# Hooks: enabling & operating

Most hooks in `hooks/hooks.json` ship **enabled by default** — old-claude parity (#1–9 in the table below), plus `ensure-memory-gitignore`, the three codegraph hooks (`codegraph-autoindex`, `prefer-codegraph`, `allow-codegraph`), `verify-before-stop` (the stop-time false-completion gate), and `review-plan-before-exit` (the plan-mode review gate) — all described after the table; all are fail-soft and safe in any project. Three further hooks (`validate-skill-frontmatter`, `check-name-collisions`, `block-deferred-issues`) are **opt-in** because they are k0d3-repo-development-specific and would misfire in unrelated projects. This doc covers how to enable the opt-in hooks, the correct config shape, the enable order, bypass, and rollback.

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

This table is the **opt-in / dependency-ordered** set. Beyond it, more hooks ship **enabled by default** and sit outside the table because they have no dependencies. Five have their own sections below: the three codegraph hooks, `verify-before-stop`, and `review-plan-before-exit` — and `verify-before-stop` and `review-plan-before-exit` are the **two default-on hooks that block** (the codegraph trio never does). (`ensure-memory-gitignore` is also default-on and outside the table; it is covered in the intro rather than a dedicated section.)

## Default codegraph hooks (fail-soft, outside the order table)

Three hooks back the bundled **codegraph** MCP server. All ship enabled, are independent of the dependency chain above, and **fail soft**, so they sit here rather than in the activation-order table.

- **`codegraph-autoindex`** (SessionStart, `startup`) — codegraph's `serve --mcp` serves an index but never builds one. This hook launches `codegraph init -i` / `index` in a **detached background** process when a git repo has source but no `.codegraph/`, so session start never blocks. No-ops when there's no git repo, the index already exists, or `npx`/`jq` are missing; an atomic lock **directory** `.claude/logs/.codegraph-indexing` prevents stacked runs (and a partial `.codegraph/` self-heals by falling back from `index` to `init`), with output to `.claude/logs/codegraph-index.log`.
- **`prefer-codegraph`** (PreToolUse, `Grep`) — **advisory only, never blocks.** When the agent greps for a bare identifier in a repo that has a codegraph index, it injects a note (via `additionalContext`) to prefer `codegraph_search` / `codegraph_context` / `codegraph_callers`. Silent for regex/phrase searches and in repos without a codegraph index — so it nudges only on bare-symbol greps in an indexed repo (there is no per-session dedup, so it can recur for the same symbol within a session).
- **`allow-codegraph`** (PreToolUse, `mcp__codegraph__.*`) — **auto-approves codegraph tool calls so they never prompt.** Every codegraph tool is read-only (search / context / callers / callees / impact / node / explore / files / status), so the hook emits `permissionDecision: "allow"` for any `mcp__codegraph__*` call. This means a user never has to hand-allowlist each tool, and **future** codegraph tools (new ones arrive across version bumps) are covered automatically — closing the gap where a freshly-promoted tool like `codegraph_explore` prompts on nearly every investigation. Fail-soft: a non-codegraph tool, a missing `tool_name`, or absent `jq` leaves the call to Claude Code's normal prompt. An in-script `case` guard re-checks the tool name, so even a loose matcher can never auto-allow a non-codegraph tool. **Trust boundary:** the wildcard auto-approves _every_ current and future `mcp__codegraph__*` tool unprompted — safe only insofar as you trust the bundled codegraph package. That is the **same** trust you already extend by running an unpinned, auto-indexing MCP server: a compromised release would already execute arbitrary code via `codegraph-autoindex` at session start, so the per-call prompt was never the boundary against a bad package. If you don't extend that trust, disable the server via `/mcp` (which also makes this hook inert).

None needs the supply-chain enable ceremony below — they take no destructive action.

**First run & opt-out.** On a fresh install the background `npx` fetch + initial index take a little time; until they finish, `codegraph_*` tools answer "not initialized" (fail-soft) — watch progress in `.claude/logs/codegraph-index.log`. To opt out: disable the server via `/mcp`, and/or remove the `codegraph-autoindex` / `prefer-codegraph` / `allow-codegraph` entries from `hooks/hooks.json` and restart. The index lives in each repo's `.codegraph/`. codegraph's own `.codegraph/.gitignore` ignores only the index **data** (`*.db`, `cache/`, `*.log`) — it leaves `.codegraph/config.json` and the `.gitignore` itself committable, so on its own the directory is only _partially_ ignored. The hook therefore adds `.codegraph/` to `.git/info/exclude` (repo-local, never committed), keeping the **whole** directory out of your `git status`. Remove the index with `rm -rf .codegraph/` or `npx @colbymchenry/codegraph uninit`.

## Default: `verify-before-stop` (stop-time false-completion gate)

Wired on **both `Stop` and `SubagentStop`**, enabled by default, and **one of the two default-on hooks that block** (with `review-plan-before-exit`) — so it runs **synchronously** (no `async`). It exists because the model's own "I'm done" judgment is unreliable after it hits a wall (not logged in, build failing, a command erroring) and rationalizes the failure as success.

- **What it does.** Reads the turn's `transcript_path`, scans **only this turn's `tool_result` output** (tool OUTPUT — not the model's own prose, where a reviewer subagent legitimately _discusses_ errors) for a high-precision failure signature (auth/login, build/compile, test failure, command-not-found, non-zero exit). On a hit it returns `{"decision":"block","reason":…}`, forcing one more turn to re-verify the fix or report honestly.
- **Single-fire.** Gated on `stop_hook_active`: it blocks at most once per stop episode. The model's _next_ stop is always allowed, so an honest "needs input" / "blocked" passes straight through and the gate never loops. No persistent ledger.
- **Escape hatch in the reason.** The block message explicitly accepts "needs-input" / "blocked" as honest outcomes, so the gate never traps the model into grinding on something only the user can unblock (auth, access, a decision).
- **Fail-soft.** Missing `jq`/`python3`, an absent transcript, or any parse error → `exit 0` (allows the stop, no output). Turns with no tool calls collect no `tool_result` → never blocked.
- **Signatures are the tunable surface.** The pattern list in `hooks/verify-before-stop.sh` is deliberately high-precision (no bare `error`/`failed`/`no such file`). Regression-tested in `scripts/test-hooks.sh` against `tests/stop-hook-fixtures/`.
- **Companion skill.** `skills/honest-completion/SKILL.md` is the framework the hook enforces; the hook catches the obvious walls, the skill generalizes to the ones a regex can't match.
- **Caveat / disabling.** `SubagentStop` is the higher false-positive surface (it fires for every Explore/Plan/reviewer subagent); the `tool_result`-only scoping is what keeps that in check. To disable either binding, remove its entry from the `Stop` / `SubagentStop` arrays in `hooks.json` and restart — the two are independent.

## Default: `review-plan-before-exit` (plan-mode calibrated-review gate)

Wired on **`PreToolUse` matcher `ExitPlanMode`**, enabled by default, and the second **default-on hook that blocks** — so it runs **synchronously** (no `async`). It makes `/k0d3:review-plan` fire automatically: when Claude tries to present a plan via native plan mode, the four calibrated reviewers (senior-dev, senior-qa, security, end-user) run and their findings are applied to the plan **before** it reaches you, instead of the review being a step you must remember to run.

- **What it does.** On the FIRST `ExitPlanMode` of a plan it returns `permissionDecision: "deny"` with a short user-facing reason plus an `additionalContext` instruction to the model: save the plan to a file if it isn't already, run `/k0d3:review-plan <that path>` (pass the path explicitly), apply the findings, and re-present. Reviewers are read-only and revising a plan document is prose editing, so both are allowed inside plan mode.
- **Cost.** Each gated plan triggers a four-reviewer dispatch (measurable tokens + latency), like the agent-at-Stop opt-in below. That is the deliberate default; reach for the escape hatch on throwaway plans.
- **Single-fire.** A **session-scoped** gate file (`.claude/logs/.plan-review-gate-<session-id>`) is armed on the deny; the re-presentation after the review finds the gate, consumes it (`rm -f`), and passes straight through. The gate self-re-arms for the next plan in the session — no persistent ledger, and loop-safe by construction (a content hash would re-block because the review _edits_ the plan). The per-session name means two plan-mode sessions in the same repo never consume each other's gate.
- **Escape hatch.** Launch Claude with `K0D3_SKIP_PLAN_REVIEW=1` in the environment → allow immediately (mirrors `K0D3_SKIP_VALIDATOR`). It is a session-launch toggle, **not** settable from inside a running session.
- **Fail-soft.** Missing `jq`, unset `CLAUDE_PROJECT_DIR`, a non-`ExitPlanMode` tool, or an un-writable gate dir → `exit 0` (allows the presentation, no output) — the gate never traps you in plan mode. Stale gates are pruned by age (>2h) at `session-reset` (startup); they are deliberately **not** cleared by `post-compact-resume`, so an armed-but-unpresented plan still passes through after a mid-plan compaction instead of forcing a redundant re-review.
- **Known limit.** Single-fire is a best-effort nudge, not hard enforcement. If the model ignored the instruction and immediately re-called `ExitPlanMode`, or a session was killed mid-flow and resumed via a path that fires no fresh `SessionStart` (e.g. `--resume`), the armed gate could be consumed without a real review. The failure is always fail-**open** (a plan skips its auto-review), never a deadlock — if you suspect a plan slipped through, just run `/k0d3:review-plan <path>` manually. This matches `verify-before-stop`'s philosophy; transcript-scanning for proof the reviewers ran is a possible future hardening.
- **Companion.** `/k0d3:plan` runs the same review inline (before its execution handoff) via the `planning` skill, so the command path and the plan-mode path both hand off a reviewed plan. The two never double-review: `/k0d3:plan` writes via `Write`, which plan mode blocks, so they are mutually exclusive in practice.
- **Disabling.** Remove the `ExitPlanMode` entry from the `PreToolUse` array in `hooks.json` and restart, or launch with `K0D3_SKIP_PLAN_REVIEW=1` set.

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

| Hook                         | Bypass for one command                                                                                                                                                                                                       | Bypass persistently                                                                                                 |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `guard-bash`                 | Temporarily move the hook entry back to `_disabled_examples` and restart Claude. The hook itself has no per-command bypass mechanism — SOFT vs HARD is a labeling distinction in the deny message, not a separate code path. | none — HARD BLOCKs are non-overridable by design while the hook is active                                           |
| `validate-skill-frontmatter` | `env K0D3_SKIP_VALIDATOR=1 claude` (one-shot, **preferred — logs to `validator-bypass.log`**)                                                                                                                                | `chmod -x hooks/validate-skill-frontmatter.sh` (silent, no audit trail)                                             |
| `completeness-gate`          | none (hard-block on detected secrets / placeholder markers)                                                                                                                                                                  | move entry back to `_disabled_examples`                                                                             |
| `block-deferred-issues`      | switch to `master` branch (`git checkout master`)                                                                                                                                                                            | move entry back to `_disabled_examples`                                                                             |
| `verify-before-stop`         | none — it blocks at most once per stop episode (single-fire), so the next stop always proceeds; report blocked / needs-input honestly and stop again                                                                         | remove its entry from the `Stop` and/or `SubagentStop` arrays in `hooks.json` and restart (the two are independent) |
| `review-plan-before-exit`    | `K0D3_SKIP_PLAN_REVIEW=1` (per session) — allows the plan presentation without a review; or just present, run `/k0d3:review-plan` once, and re-present (single-fire lets the second `ExitPlanMode` through)                  | remove the `ExitPlanMode` entry from the `PreToolUse` array in `hooks.json` and restart                             |

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

k0d3 wires **7** of the lifecycle events Claude Code exposes (~31 total): `SessionStart`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PreCompact`, `Stop`, and `SubagentStop` (the last two share `verify-before-stop`). Other events available if a future need arises include `PostCompact`, `SubagentStart`, `SessionEnd`, `PermissionRequest`, `UserPromptSubmit`, and `Notification`.

Every k0d3 hook is `type: "command"` (a shell script: stdin is the event JSON, the exit code plus stdout/JSON control the result). Claude Code also supports other hook types, useful to know when designing a new hook:

- **`command`** — run a shell script. What k0d3 uses.
- **`http`** — POST the event JSON to a URL; a `2xx` JSON body uses the same output schema as a command hook.
- **`mcp_tool`** — call a tool on an already-connected MCP server.
- **`prompt`** — single-turn Claude evaluation returning an allow/block-style verdict.
- **`agent`** — spawn a subagent with tool access for deeper verification (**experimental**).

Two fields control blocking:

- **`"async": true`** — the hook runs in the background and never blocks the tool/turn pipeline. Use it for append-only logging, backups, and notifications whose output is not consumed for control flow. k0d3 sets it on the three loggers (`log-changes`, `log-failures`, `log-stop-verdict`). **Do not** set it on a hook that must gate the action (`guard-bash`, `completeness-gate`, `validate-skill-frontmatter`), return a `permissionDecision` (`allow-codegraph` — an async hook's decision is discarded, so codegraph would silently fall back to prompting), inject `additionalContext` (`prefer-codegraph`), or finish before the event proceeds (`backup-before-write`, which must snapshot before the write; `pre-compact-handoff`, which must write its marker before compaction).
- **`"asyncRewake": true`** — like `async`, but exit code 2 wakes Claude with the hook's stderr as a system reminder. Implies `async`. Useful for a background check that lets the action through but nudges Claude when it finds something (e.g. a linter that flags an issue without blocking the write).

Official reference: <https://code.claude.com/docs/en/hooks>.

## Opt-in: auto-run the auditor on Stop (agent hook)

The `auditor` agent is invoked by the `/audit` command. To run it **automatically at the end of every turn**, the `agent` hook type makes that possible. Replace the `Stop` block in `hooks.json` with the merged array below — it keeps the existing `log-stop-verdict` logger and adds the agent hook as the second entry (this is the final state of the whole `Stop` array, not a snippet to append; the `Stop` event takes no `matcher`, so it fires on every stop):

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

**Cost caveat:** this spawns a subagent at every turn-end — measurable token + latency overhead, and it fires even on trivial turns. The `agent` hook type is **experimental**. For most workflows, on-demand `/audit` is the better trade; enable this only if you specifically want unattended, every-turn auditing.

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
- `verify-before-stop` is regex-based (like `guard-bash`) and pattern-matches tool output, so it has both false negatives (a failure phrased outside its signature list slips through) and rare false positives (benign output that contains a matched phrase). It is a tripwire that forces one re-check, not a proof of correctness — the companion `honest-completion` skill carries the discipline the regex can't.

See `hooks/<hook>.sh` for the authoritative per-hook contract.
