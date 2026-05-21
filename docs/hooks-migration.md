# Phase 6 hooks migration

Procedure for enabling k0d3 hooks during the Phase 6 cutover. All hooks ship **disabled by default** in `hooks/hooks.json`; this doc explains how to turn them on safely, the per-hook ordering, and rollback at each step.

## TL;DR

1. Verify Batch 1 (`hooks/` + `scripts/`) is reviewed and `bash scripts/test-hooks.sh && bash scripts/test-validator.sh` returns 0.
2. Enable one hook at a time by moving its entry from `_disabled_examples` to the matching `hooks.<event>` array in `hooks/hooks.json`.
3. After each move, restart your Claude Code session and observe `.claude/logs/incident-log.md` and `.claude/logs/audit-trail.md` for at least one work session.
4. If anything misbehaves, move the entry back to `_disabled_examples` and revert.
5. Once all hooks are healthy and the legacy plugin set has been uninstalled, k0d3 is the sole plugin.

## Per-hook activation order

Some hooks depend on artifacts produced by other hooks (`session-reset` reads what `post-compact-resume` cleaned up, `pre-compact-handoff` writes a marker that `post-compact-resume` consumes). Enable in this order.

| #   | Hook                         | Event                        | Why this position                                                                                                                                                                                                    |
| --- | ---------------------------- | ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `backup-before-write`        | PreToolUse Write\|Edit       | Pure side-effect (file copy). No deps. Safest to enable first — gives you rollback for the next hooks.                                                                                                               |
| 2   | `log-changes`                | PostToolUse Write\|Edit      | Append-only audit. No deps. Pairs well with backups for the cutover.                                                                                                                                                 |
| 3   | `log-failures`               | PostToolUseFailure           | Append-only failure log. No deps. Independent of any other hook.                                                                                                                                                     |
| 4   | `pre-compact-handoff`        | PreCompact                   | Writes `.compaction-occurred` marker. Must be enabled **before** `post-compact-resume`.                                                                                                                              |
| 5   | `post-compact-resume`        | SessionStart matcher=compact | Reads + deletes the marker from #4. Enable after #4 is confirmed healthy.                                                                                                                                            |
| 6   | `session-reset`              | SessionStart matcher=startup | Cleans stale gate files at session start. Independent — can be enabled any time, but pairs naturally with #4–#5 (same gate-file lifecycle).                                                                          |
| 7   | `log-stop-verdict`           | Stop                         | JSONL session-ended log. Currently writes `decision: ended` unconditionally — purely additive.                                                                                                                       |
| 8   | `guard-bash`                 | PreToolUse Bash              | **Behavior-changing.** Will start blocking commands. Confirm `scripts/test-hooks.sh` is green BEFORE enabling. Be prepared to bypass via the deny message's `additionalContext` if a legitimate command is rejected. |
| 9   | `completeness-gate`          | PreToolUse Write\|Edit       | **Behavior-changing.** Blocks writes containing TBD/TODO/FIXME markers and detected secrets. Test on a throwaway file first.                                                                                         |
| 10  | `validate-skill-frontmatter` | PreToolUse Write\|Edit       | **Behavior-changing.** Validates frontmatter when writing to `skills/`. Fail-open (always exit 0), so a misfire is annoying but not blocking.                                                                        |
| 11  | `block-deferred-issues`      | PreToolUse Bash              | Blocks `gh issue create` on `work/*` branches. Only fires on that one command path.                                                                                                                                  |

## Step-by-step procedure (per hook)

1. **Read the hook's source.** All hooks are short (≤200 lines). Confirm you understand the deny conditions before flipping it on.
2. **Open `hooks/hooks.json`.** Locate the matching entry in `_disabled_examples`.
3. **Move the entry to `hooks.<event>`.** Copy the object (including `event`, `matcher` if present, `command`) into the corresponding array. Leave `_disabled_examples` as a reference catalog.
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

## Rollback (entire migration)

To unwind any subset of activations:

```bash
# Restore disabled-by-default state
git checkout hooks/hooks.json
```

If old plugins were uninstalled and you need them back: `/plugin install <name>` (Claude Code's plugin manager remembers prior installs).

## Hard sequencing (read-after-write pairs)

- `pre-compact-handoff` (write marker) → `post-compact-resume` (read + delete marker). Pair must move together; never enable resume without handoff.
- `session-reset` benefits from `post-compact-resume` being live (it cleans up the same gate files). Independent but sequenced.
- `log-changes` and `log-failures` are independent — enable separately or together.
- `backup-before-write` has no dependency — always safe to enable first.

## Health checks after full activation

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

## Known limitations of the current hook set

- `guard-bash` is regex-based and treats the command as a string. Shell-indirection (`eval`, `bash -c`) is soft-blocked but `python3 -c '<payload>'` and `perl -e '<payload>'` are not yet detected. Treat the hook as a tripwire, not a sandbox.
- `completeness-gate` secret-scan does not cover every credential format (covers Stripe, OpenAI, Anthropic, classic + fine-grained GitHub PATs, GitLab tokens, Slack tokens, AWS, JWTs, GCP private-key JSON). Custom-format tokens for in-house systems are not detected.
- `validate-skill-frontmatter` is fail-open: missing PyYAML or any internal error exits 0 (allows the write). Acceptable for a dev tool; surface the limitation to anyone relying on it for security gating.

See `hooks/<hook>.sh` for the authoritative per-hook contract.
