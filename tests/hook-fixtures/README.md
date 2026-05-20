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
| `env-grep-secret`    | `env \| grep STRIPE`         | block                                  |

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
