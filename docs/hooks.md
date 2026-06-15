# Hooks: enabling & operating

Most hooks in `hooks/hooks.json` ship **enabled by default** — old-claude parity (#1–9 in the table below), plus `ensure-memory-gitignore` and the two codegraph hooks (`codegraph-autoindex`, `prefer-codegraph`, described after the table); all are fail-soft and safe in any project. Three further hooks (`validate-skill-frontmatter`, `check-name-collisions`, `block-deferred-issues`) are **opt-in** because they are k0d3-repo-development-specific and would misfire in unrelated projects. This doc covers how to enable the opt-in hooks, the correct config shape, the enable order, bypass, and rollback.

> **Config shape & paths (read before editing `hooks.json`).** A live hook entry is the **nested** form
> `hooks.<event>: [ { "matcher": "…", "hooks": [ { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/<name>.sh" } ] } ]`.
> Always reference scripts via **`${CLAUDE_PLUGIN_ROOT}`** (the plugin's install dir) — **not** `$CLAUDE_PROJECT_DIR` (the user's current project), or the hook won't be found once k0d3 is installed in some other project. The flat `{event, matcher, command}` objects in `_disabled_examples` are a **catalog**, not valid live config.

## TL;DR

1. Confirm `bash scripts/test-hooks.sh && bash scripts/test-validator.sh` returns 0.
2. Hooks #1–9 are already wired in `hooks.<event>`. To enable an opt-in hook (#10–12), add a **nested** entry to the matching `hooks.<event>` array (see the config-shape note above) — do not paste the flat catalog object.
3. After each change, restart your Claude Code session and observe `.claude/logs/incident-log.md` and `.claude/logs/audit-trail.md` for at least one work session.
4. If anything misbehaves, move the entry back to `_disabled_examples` and revert.

## Per-hook activation order

Some hooks depend on artifacts produced by other hooks (`session-reset` reads what `post-compact-resume` cleaned up, `pre-compact-handoff` writes a marker that `post-compact-resume` consumes). Enable in this order.

| #   | Hook                         | Event                        | Why this position                                                                                                                                                                                                                                  |
| --- | ---------------------------- | ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `backup-before-write`        | PreToolUse Write\|Edit       | Pure side-effect (file copy). Runs **synchronously** (blocking, by design) — a PreToolUse backup must finish before the write so the snapshot captures pre-write content. No deps. Safest to enable first — gives you rollback for the next hooks. |
| 2   | `log-changes`                | PostToolUse Write\|Edit      | Append-only audit. Runs **`async`** (non-blocking). No deps. Pairs well with backups.                                                                                                                                                              |
| 3   | `log-failures`               | PostToolUseFailure           | Append-only failure log. Runs **`async`** (non-blocking). No deps. Independent of any other hook.                                                                                                                                                  |
| 4   | `pre-compact-handoff`        | PreCompact                   | Writes `.compaction-occurred` marker. Must be enabled **before** `post-compact-resume`.                                                                                                                                                            |
| 5   | `post-compact-resume`        | SessionStart matcher=compact | Reads + deletes the marker from #4. Enable after #4 is confirmed healthy.                                                                                                                                                                          |
| 6   | `session-reset`              | SessionStart matcher=startup | Cleans stale gate files at session start. Independent — can be enabled any time, but pairs naturally with #4–#5 (same gate-file lifecycle).                                                                                                        |
| 7   | `log-stop-verdict`           | Stop                         | JSONL session-ended log. Runs **`async`** (non-blocking). Writes `decision: ended` unconditionally — purely additive.                                                                                                                              |
| 8   | `guard-bash`                 | PreToolUse Bash              | **Behavior-changing.** Will start blocking commands. Confirm `scripts/test-hooks.sh` is green BEFORE enabling. Be prepared to bypass via the deny message's `additionalContext` if a legitimate command is rejected.                               |
| 9   | `completeness-gate`          | PreToolUse Write\|Edit       | **Behavior-changing.** Blocks writes containing TBD/TODO/FIXME markers and detected secrets. Test on a throwaway file first.                                                                                                                       |
| 10  | `validate-skill-frontmatter` | PreToolUse Write\|Edit       | **Behavior-changing.** Validates frontmatter when writing to `skills/`. Fail-open (always exit 0), so a misfire is annoying but not blocking.                                                                                                      |
| 11  | `block-deferred-issues`      | PreToolUse Bash              | Blocks `gh issue create` on `work/*` branches. Only fires on that one command path.                                                                                                                                                                |
| 12  | `check-name-collisions`      | SessionStart matcher=startup | Independent (no deps). Warns when a skill/command/agent name collides with another installed plugin. Safe to enable any time; opt-in only because the collision set is k0d3-repo-development-specific.                                             |

## Default codegraph hooks (fail-soft, outside the order table)

Two hooks back the bundled **codegraph** MCP server. Both ship enabled, are independent of the dependency chain above, and **fail soft**, so they sit here rather than in the activation-order table.

- **`codegraph-autoindex`** (SessionStart, `startup`) — codegraph's `serve --mcp` serves an index but never builds one. This hook launches `codegraph init -i` / `index` in a **detached background** process when a git repo has source but no `.codegraph/`, so session start never blocks. No-ops when there's no git repo, the index already exists, or `npx`/`jq` are missing; an atomic lock **directory** `.claude/logs/.codegraph-indexing` prevents stacked runs (and a partial `.codegraph/` self-heals by falling back from `index` to `init`), with output to `.claude/logs/codegraph-index.log`.
- **`prefer-codegraph`** (PreToolUse, `Grep`) — **advisory only, never blocks.** When the agent greps for a bare identifier in a repo that has a codegraph index, it injects a note (via `additionalContext`) to prefer `codegraph_search` / `codegraph_context` / `codegraph_callers`. Silent for regex/phrase searches and in repos without a codegraph index — so it nudges only on bare-symbol greps in an indexed repo (there is no per-session dedup, so it can recur for the same symbol within a session).

Neither needs the supply-chain enable ceremony below — they take no destructive action.

**First run & opt-out.** On a fresh install the background `npx` fetch + initial index take a little time; until they finish, `codegraph_*` tools answer "not initialized" (fail-soft) — watch progress in `.claude/logs/codegraph-index.log`. To opt out: disable the server via `/mcp`, and/or remove the `codegraph-autoindex` / `prefer-codegraph` entries from `hooks/hooks.json` and restart. The index lives in each repo's `.codegraph/`. codegraph's own `.codegraph/.gitignore` ignores only the index **data** (`*.db`, `cache/`, `*.log`) — it leaves `.codegraph/config.json` and the `.gitignore` itself committable, so on its own the directory is only _partially_ ignored. The hook therefore adds `.codegraph/` to `.git/info/exclude` (repo-local, never committed), keeping the **whole** directory out of your `git status`. Remove the index with `rm -rf .codegraph/` or `npx @colbymchenry/codegraph uninit`.

## Step-by-step procedure (per hook)

1. **Read the hook's source.** All hooks are short (≤200 lines). Confirm you understand the deny conditions before flipping it on.
2. **Open `hooks/hooks.json`.** Locate the matching entry in `_disabled_examples`.
3. **Add a nested entry to `hooks.<event>`.** Don't paste the flat catalog object — write the nested form: `{ "matcher": "<matcher, or omit for all>", "hooks": [ { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/<name>.sh" } ] }`. Leave `_disabled_examples` as the reference catalog.
4. **Validate JSON syntax.** Run `jq empty hooks/hooks.json` — must exit 0.
5. **Restart Claude Code.** The new session picks up the hook config at startup.
6. **Observe for one work session.** Check `.claude/logs/incident-log.md` and `.claude/logs/audit-trail.md` (or `.claude/logs/failure-log.md` for #3).
7. **If the hook misbehaves**: move the entry back to `_disabled_examples`, restart the session.

## Validation before enabling behavior-changing hooks (#8–#11)

```bash
bash -n hooks/*.sh            # syntax
bash scripts/test-hooks.sh    # guard-bash regression tests
bash scripts/test-validator.sh # validator regression tests
bash scripts/validate-skills.sh # lint
```

All four must exit 0 before flipping hooks #8–#11.

## Bypass mechanisms (per-hook)

| Hook                         | Bypass for one command                                                                                                                                                                                                       | Bypass persistently                                                       |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `guard-bash`                 | Temporarily move the hook entry back to `_disabled_examples` and restart Claude. The hook itself has no per-command bypass mechanism — SOFT vs HARD is a labeling distinction in the deny message, not a separate code path. | none — HARD BLOCKs are non-overridable by design while the hook is active |
| `validate-skill-frontmatter` | `env K0D3_SKIP_VALIDATOR=1 claude` (one-shot, **preferred — logs to `validator-bypass.log`**)                                                                                                                                | `chmod -x hooks/validate-skill-frontmatter.sh` (silent, no audit trail)   |
| `completeness-gate`          | none (hard-block on detected secrets / placeholder markers)                                                                                                                                                                  | move entry back to `_disabled_examples`                                   |
| `block-deferred-issues`      | switch to `master` branch (`git checkout master`)                                                                                                                                                                            | move entry back to `_disabled_examples`                                   |

The `chmod -x` bypass for the validator is supported but produces no audit log — prefer the env-var path for one-off needs.

## Rollback

To unwind any subset of activations:

```bash
# Restore disabled-by-default state
git checkout hooks/hooks.json
```

## Hard sequencing (read-after-write pairs)

- `pre-compact-handoff` (write marker) → `post-compact-resume` (read + delete marker). Pair must move together; never enable resume without handoff.
- `session-reset` benefits from `post-compact-resume` being live (it cleans up the same gate files). Independent but sequenced.
- `log-changes` and `log-failures` are independent — enable separately or together.
- `backup-before-write` has no dependency — always safe to enable first.

## Health checks after enabling hooks

```bash
# 1. No syntax errors in hook config
jq empty hooks/hooks.json

# 2. All hooks executable
ls -la hooks/*.sh | awk '$1 !~ /x/ {print}'   # should print nothing

# 3. Test suite green
bash scripts/test-hooks.sh && bash scripts/test-validator.sh

# 4. Incident log not full of WARNs from your own use
tail -50 .claude/logs/incident-log.md
```

If any health check fails, rollback the most recently-enabled hook and investigate.

## Hook capabilities reference (Claude Code)

k0d3 wires **6** of the lifecycle events Claude Code exposes (~31 total): `SessionStart`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PreCompact`, `Stop`. Other events available if a future need arises include `PostCompact`, `SubagentStart` / `SubagentStop`, `SessionEnd`, `PermissionRequest`, `UserPromptSubmit`, and `Notification`.

Every k0d3 hook is `type: "command"` (a shell script: stdin is the event JSON, the exit code plus stdout/JSON control the result). Claude Code also supports other hook types, useful to know when designing a new hook:

- **`command`** — run a shell script. What k0d3 uses.
- **`http`** — POST the event JSON to a URL; a `2xx` JSON body uses the same output schema as a command hook.
- **`mcp_tool`** — call a tool on an already-connected MCP server.
- **`prompt`** — single-turn Claude evaluation returning an allow/block-style verdict.
- **`agent`** — spawn a subagent with tool access for deeper verification (**experimental**).

Two fields control blocking:

- **`"async": true`** — the hook runs in the background and never blocks the tool/turn pipeline. Use it for append-only logging, backups, and notifications whose output is not consumed for control flow. k0d3 sets it on the three loggers (`log-changes`, `log-failures`, `log-stop-verdict`). **Do not** set it on a hook that must gate the action (`guard-bash`, `completeness-gate`, `validate-skill-frontmatter`), inject `additionalContext` (`prefer-codegraph`), or finish before the event proceeds (`backup-before-write`, which must snapshot before the write; `pre-compact-handoff`, which must write its marker before compaction).
- **`"asyncRewake": true`** — like `async`, but exit code 2 wakes Claude with the hook's stderr as a system reminder. Implies `async`. Useful for a background check that lets the action through but nudges Claude when it finds something (e.g. a linter that flags an issue without blocking the write).

Official reference: <https://code.claude.com/docs/en/hooks>.

## Opt-in: auto-run the auditor on Stop (agent hook)

The `auditor` agent is invoked by the `/audit` command and as part of `/wrap-up`. To run it **automatically at the end of every turn**, the `agent` hook type makes that possible. Replace the `Stop` block in `hooks.json` with the merged array below — it keeps the existing `log-stop-verdict` logger and adds the agent hook as the second entry (this is the final state of the whole `Stop` array, not a snippet to append; the `Stop` event takes no `matcher`, so it fires on every stop):

```json
"Stop": [
  {
    "hooks": [
      { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/log-stop-verdict.sh", "async": true },
      { "type": "agent", "prompt": "Run a Tier-1 audit of the work in this turn. Read CLAUDE.md and .claude/knowledge-base.md, check for contradictions, scope violations, and incomplete tasks, then emit a PASS/WARN/FAIL verdict. Do not edit operational source code." }
    ]
  }
]
```

The prompt references `CLAUDE.md` and `.claude/knowledge-base.md` as project-relative paths; adapt them to your repo (or the audit reads nothing where those files are absent).

**Cost caveat:** this spawns a subagent at every turn-end — measurable token + latency overhead, and it fires even on trivial turns. The `agent` hook type is **experimental**. For most workflows, on-demand `/audit` (or `/wrap-up` at end of day) is the better trade; enable this only if you specifically want unattended, every-turn auditing.

## Opt-in: green-gate — typecheck/lint after edits (command hook)

<!-- Green-gate recipe adapted from tale-mode (https://github.com/alicicek/tale-mode), MIT. -->

k0d3's hooks log, back up, and guard — none of them assert "the project still typechecks" after an edit. `Skill(using-k0d3)` states the principle (_internal consistency is not correctness — run it and observe_); a `PostToolUse` gate makes that the harness's job instead of something the model must remember to run.

This is a **recipe, not a bundled hook.** The command is project-specific (a Go repo runs `go build ./...`, a TS repo `tsc --noEmit`, a Python repo `ruff check`), so k0d3 ships no script for it — wire it into your own `.claude/settings.json`. Because it runs a project command rather than a plugin script, it is the one case that does **not** use `${CLAUDE_PLUGIN_ROOT}`.

**Blocking variant** — `PostToolUse` runs _after_ the edit is written, so this doesn't prevent the change; a non-zero exit surfaces the hook's stderr to Claude as a blocking error it must resolve before continuing. Exit code `2` is the value Claude Code treats as blocking (a bare `npm run` failure exits `1`, a non-blocking error), so force it with `|| exit 2`:

```json
"PostToolUse": [
  {
    "matcher": "Edit|Write",
    "hooks": [
      { "type": "command", "command": "npm run -s typecheck || exit 2" }
    ]
  }
]
```

Swap the command for your stack: `tsc --noEmit`, `ruff check`, `go build ./...`. Keep it self-contained — don't reference the edited file's path here; the bare `"command"` string has no `$file` in scope (see file-scoping below for that).

A whole-project gate also fires _between_ the files of a multi-file edit, when the tree is legitimately half-written and red — Claude then chases a failure the next edit would have fixed. For multi-file work, prefer the file-scoping below or the non-blocking nudge.

**Non-blocking nudge** — `asyncRewake` (see the _Hook capabilities reference_ section above) runs the check in the background, lets the edit through, and only wakes Claude (exit 2 → stderr as a system reminder) when it fails:

```json
"PostToolUse": [
  {
    "matcher": "Edit|Write",
    "hooks": [
      { "type": "command", "command": "npm run -s typecheck", "asyncRewake": true }
    ]
  }
]
```

**Scope to the changed file.** A multi-line gate doesn't fit the single-string `"command"` field — save it as a project script and point the command at it (e.g. `"command": "bash .claude/green-gate.sh"`; a project script takes no `${CLAUDE_PLUGIN_ROOT}`). The hook delivers the tool payload as JSON on **stdin**, so parse the path with `jq` and only run when a relevant file changed:

```bash
#!/usr/bin/env bash
file=$(jq -r '.tool_input.file_path // empty')
case "$file" in
  *.ts | *.tsx) npx --no-install tsc --noEmit || exit 2 ;;
esac
```

`--no-install` stops `npx` from fetching `tsc` over the network on every edit — install it locally (`devDependencies`) so it resolves from `node_modules`. Confirm the payload field name against your Claude Code version (<https://code.claude.com/docs/en/hooks>); if it is absent, `$file` is empty, the `case` matches nothing, and the gate silently passes.

**Keep it fast** — this fires on _every_ matching edit. Prefer a file-scoped or incremental check (as above) to a full build; reserve the full test suite for the verification phase, not the per-edit hook.

## Known limitations of the current hook set

- `guard-bash` is regex-based and treats the command as a string. Shell-indirection (`eval`, `bash -c`) is soft-blocked but `python3 -c '<payload>'` and `perl -e '<payload>'` are not yet detected. Treat the hook as a tripwire, not a sandbox.
- `guard-bash` does not block env-table enumeration — `env | grep NAME`, `export | grep`, or bare `printenv | grep` all run. Reading a _named_ variable (`printenv VAR`, `echo $KNOWN_PREFIX`) and every `.env` file access stay blocked, but an ambient-environment dump piped to a filter is allowed: a bare-word `env` matcher flags far more benign commands (`docker run --env`, `npm run env`, `rg 'env|export'`) than real exfil, so it is intentionally absent. Keep real secrets in `.env`/a secret store rather than exported into the shell environment.
- `completeness-gate` secret-scan does not cover every credential format (covers Stripe, OpenAI, Anthropic, classic + fine-grained GitHub PATs, GitLab tokens, Slack tokens, AWS, JWTs, GCP private-key JSON). Custom-format tokens for in-house systems are not detected.
- `validate-skill-frontmatter` is fail-open: missing PyYAML or any internal error exits 0 (allows the write). Acceptable for a dev tool; surface the limitation to anyone relying on it for security gating.

See `hooks/<hook>.sh` for the authoritative per-hook contract.
