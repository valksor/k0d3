# Hook fixtures

Test cases for `scripts/test-hooks.sh`. Cases are encoded inline in the test script (no separate fixture files for `guard-bash.sh` — the command string IS the fixture). Each case feeds a mock Claude Code PreToolUse JSON envelope to the hook and asserts the resulting `permissionDecision` (`allow`, `warn`, or implicit `deny` for `block`).

## Verdict semantics

| Verdict | Hook behavior                                                                   | Test assertion                                                   |
| ------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `block` | JSON stdout with `permissionDecision: "deny"`, exit 0                           | decision == "deny"                                               |
| `allow` | No JSON output (or `permissionDecision: "allow"`), exit 0                       | decision == "allow"                                              |
| `warn`  | No JSON output, exit 0, BUT an entry appended to `.claude/logs/incident-log.md` | decision == "allow" AND grep of command found in incident-log.md |

The hook contract: `guard-bash.sh` ALWAYS exits 0. Block signals travel via JSON on stdout, not exit code.

## Current cases (must mirror what `test-hooks.sh` actually runs)

### Hard-block: catastrophic rm token-scan (B1, Pass 2 Sr Dev B1 + Security B1)

| Case                        | Command                       | Expect |
| --------------------------- | ----------------------------- | ------ |
| `rm-rf-root-trailing-flags` | `rm -rf / --no-preserve-root` | block  |
| `rm-r-root-no-force`        | `rm -r /`                     | block  |
| `rm-rf-etc`                 | `rm -rf /etc/something`       | block  |
| `rm-flag-after-path`        | `rm / -rf`                    | block  |
| `rm-long-form-recursive`    | `rm --recursive /etc`         | block  |
| `rm-quoted-system-path`     | `rm -rf "/etc"`               | block  |
| `rm-users-home`             | `rm -rf /Users/someone`       | block  |

### Hard-block: shell-indirection bypass (B2)

| Case            | Command              | Expect |
| --------------- | -------------------- | ------ |
| `eval-bypass`   | `eval 'rm -rf /'`    | block  |
| `bash-c-bypass` | `bash -c 'rm -rf /'` | block  |

### Hard-block: force push

| Case               | Command                       | Expect                         |
| ------------------ | ----------------------------- | ------------------------------ |
| `force-push`       | `git push --force`            | block                          |
| `force-with-lease` | `git push --force-with-lease` | block (matches --force prefix) |

### Hard-block: secret-file read (B3)

| Case                 | Command                      | Expect                                 |
| -------------------- | ---------------------------- | -------------------------------------- |
| `cat-env`            | `cat .env`                   | block                                  |
| `grep-env-no-c`      | `grep STRIPE .env`           | block                                  |
| `awk-env`            | `awk '1' .env`               | block                                  |
| `cat-quoted-env`     | `cat ".env"`                 | block                                  |
| `grep-c-env-allowed` | `grep -c STRIPE .env`        | allow (existence check, no value leak) |
| `printenv-var`       | `printenv STRIPE_SECRET_KEY` | block                                  |

### Allow: env-table enumeration (matcher intentionally absent)

A bare-word `env`/`export` piped to a filter is allowed. Matching the word `env` caught far more benign commands (build flags, package scripts, search patterns) than real exfil; reading a _named_ variable (`printenv VAR`) and all `.env` file access stay blocked above.

| Case                       | Command                                      | Expect |
| -------------------------- | -------------------------------------------- | ------ |
| `env-grep-allowed`         | `env \| grep STRIPE`                         | allow  |
| `docker-env-flag-allowed`  | `docker run --env FOO=bar img \| grep ready` | allow  |
| `npm-run-env-grep-allowed` | `npm run env \| grep PORT`                   | allow  |
| `rg-env-pattern-allowed`   | `rg -n 'env\|export' docs/hooks.md \| head`  | allow  |

### Clause-aware catastrophic rm (system path in a sibling clause)

A system/home path is treated as an rm target only when it shares a clause with `rm`. A path in a sibling clause (`cd`, `ls`, …) no longer hard-blocks.

| Case                              | Command                                | Expect |
| --------------------------------- | -------------------------------------- | ------ |
| `rm-sibling-syspath-allowed`      | `cd /Users/me/proj && rm -f localfile` | allow  |
| `ls-syspath-then-rm-allowed`      | `ls /etc && rm note.txt`               | allow  |
| `rm-syspath-in-rm-clause-blocked` | `cd /tmp && rm -rf /etc/x`             | block  |

### .env templates vs real secrets

`.env.example` / `.sample` / `.template` / `.dist` are secret-free templates: reading, copying, and staging them is allowed. Local file-movers (`cp`/`mv`/`ln`) are no longer treated as readers. A real `.env` stays blocked.

| Case                          | Command                | Expect |
| ----------------------------- | ---------------------- | ------ |
| `cp-env-template-allowed`     | `cp .env.example .env` | allow  |
| `cat-env-template-allowed`    | `cat .env.example`     | allow  |
| `mv-env-local-allowed`        | `mv .env.local .env`   | allow  |
| `gitadd-env-template-allowed` | `git add .env.example` | allow  |
| `gitadd-env-real-blocked`     | `git add .env`         | block  |

### Force-only vs recursive rm

Force-only `rm -f <named files>` (no `-r`) is warn-tier (allowed, logged). A recursive `rm -r`/`-R` still soft-blocks unless it targets an allowlisted path.

| Case                       | Command                    | Expect |
| -------------------------- | -------------------------- | ------ |
| `rm-force-named-allowed`   | `rm -f /tmp/throwaway.txt` | allow  |
| `rm-recursive-dir-blocked` | `rm -rf node_modules`      | block  |

### printenv & echo: benign vars vs secrets

`printenv` of a safelisted var (`PATH`, `HOME`, …) and `echo` of a non-secret var are allowed; secret-named vars stay blocked.

| Case                         | Command                   | Expect |
| ---------------------------- | ------------------------- | ------ |
| `printenv-path-allowed`      | `printenv PATH`           | allow  |
| `printenv-home-allowed`      | `printenv HOME`           | allow  |
| `echo-aws-region-allowed`    | `echo $AWS_REGION`        | allow  |
| `echo-db-name-allowed`       | `echo $DATABASE_NAME`     | allow  |
| `echo-token-count-allowed`   | `echo $TOKEN_COUNT`       | allow  |
| `echo-stripe-secret-blocked` | `echo $STRIPE_SECRET_KEY` | block  |
| `echo-gh-token-blocked`      | `echo $GH_TOKEN`          | block  |

### Soft-block: compound-AND allowlist (C7)

| Case                             | Command                                               | Expect | Coverage                                   |
| -------------------------------- | ----------------------------------------------------- | ------ | ------------------------------------------ |
| `compound-rm-bypass-hardpath`    | `rm -rf .claude/backups/old && rm -rf /home/user`     | block  | hard-block fires on /home/user             |
| `compound-rm-bypass-clauselogic` | `rm -rf .claude/backups/old && rm -rf ./project-data` | block  | exercises CLAUSE_FAILED loop in soft-block |

### Allow

| Case                     | Command                             | Expect                          |
| ------------------------ | ----------------------------------- | ------------------------------- |
| `ls-cwd`                 | `ls -la`                            | allow                           |
| `rm-allowlisted-backups` | `rm -rf .claude/backups/2024-01-01` | allow                           |
| `rm-single-file`         | `rm ./single-file.txt`              | allow (warn-level, not blocked) |

### Warn (allowed, but appended to incident-log.md)

| Case                    | Command                       | Expect |
| ----------------------- | ----------------------------- | ------ |
| `warn-redirect-outside` | `echo hi > /tmp/somefile.txt` | warn   |

## Adding new cases

1. Add the case to `scripts/test-hooks.sh` under the matching tier section.
2. Add a row to the corresponding table above.
3. Run `bash scripts/test-hooks.sh` and confirm `0 fail`.

Coverage gaps (intentionally not blocked by the regex tripwire — documented in `hooks/guard-bash.sh`):

- `python3 -c '...'` / `perl -e '...'` / `node -e '...'` shell indirection
- `find ... | xargs rm -rf` (`xargs rm -rf` has no trailing space; soft-block regex misses)
- Words in commands like `git log --grep "force"` (low-impact false positive)
