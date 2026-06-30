#!/usr/bin/env bash
# generate-codex-hooks.sh [--check] — derive the Codex plugin-channel hooks file
# (hooks/hooks.codex.json) from the single source of truth, hooks/hooks.json.
#
# Codex 0.142.x loads plugin hooks from the file named by `.codex-plugin/plugin.json`
# `hooks`; command paths resolve relative to the plugin root and support
# ${CLAUDE_PLUGIN_ROOT} interpolation. This generator rewrites each k0d3 hook to run
# through codex-hooks-shim.sh (which synthesizes CLAUDE_PROJECT_DIR and exports
# K0D3_HOST=codex) and strips the events/keys Codex does not support.
#
# Transform (vs hooks/hooks.json):
#   - drop PostToolUseFailure        (no such Codex event)
#   - drop the ExitPlanMode matcher  (no Codex plan-mode hook)
#   - drop async-only telemetry      (log-changes.sh, log-stop-verdict.sh) — Codex has
#                                     no async hooks; running them sync adds latency
#   - del(.async) on every hook      (Codex has no async support yet)
#   - route every command through    "${CLAUDE_PLUGIN_ROOT}/hooks/codex-hooks-shim.sh"
#     the shim, QUOTED so a space in the plugin cache path can't word-split the args
#   - keep Stop/SubagentStop          (verify-before-stop.sh dual-emits the Codex schema)
#
# Usage:
#   scripts/generate-codex-hooks.sh           # (re)write hooks/hooks.codex.json
#   scripts/generate-codex-hooks.sh --check   # verify the committed file is in sync (CI)
#
# Requires: jq.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/hooks/hooks.json"
OUT="$ROOT/hooks/hooks.codex.json"
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

command -v jq > /dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 1
}

# The async-only telemetry hooks to exclude from Codex (run sync would add latency,
# and Codex ignores `async` so they would block anyway). log-failures.sh lives under
# PostToolUseFailure, which is dropped wholesale below.
EXCLUDE='["log-changes.sh","log-stop-verdict.sh"]'

derive() {
  jq --argjson excl "$EXCLUDE" '
    # extract "<name>.sh" from a command string, or null if absent
    def script_name: (try (capture("hooks/(?<n>[A-Za-z0-9._-]+\\.sh)").n) catch null);

    .hooks
    | del(.PostToolUseFailure)
    # drop the ExitPlanMode PreToolUse matcher (no Codex plan-mode hook)
    | (if has("PreToolUse") then .PreToolUse |= map(select((.matcher // "") != "ExitPlanMode")) else . end)
    # within every hook group, drop the async-only telemetry commands
    | with_entries(
        .value |= (
          map(.hooks |= map(select(((.command | script_name) as $n | ($excl | index($n)) | not))))
          | map(select((.hooks | length) > 0))
        )
      )
    # drop any event whose group list went empty
    | with_entries(select((.value | length) > 0))
    # rewrite every surviving command to the shim form; strip async; assert name non-null
    | walk(
        if type == "object" and has("command")
        then ((.command | script_name) as $n
              | if $n == null then error("hook command has no script name: \(.command)") else . end
              | .command = "\"${CLAUDE_PLUGIN_ROOT}/hooks/codex-hooks-shim.sh\" \"${CLAUDE_PLUGIN_ROOT}/hooks/\($n)\""
              | del(.async))
        else . end)
    | {hooks: .}
  ' "$SRC"
}

if [ "$CHECK" = "1" ]; then
  TMP="$(mktemp)"
  trap 'rm -f "$TMP"' EXIT
  derive > "$TMP"
  if [ ! -f "$OUT" ]; then
    echo "FAIL: $OUT missing — run scripts/generate-codex-hooks.sh" >&2
    exit 1
  fi
  if diff -u "$OUT" "$TMP" > /dev/null 2>&1; then
    echo "hooks.codex.json in sync"
  else
    echo "FAIL: hooks/hooks.codex.json is stale — run scripts/generate-codex-hooks.sh" >&2
    diff -u "$OUT" "$TMP" >&2 || true
    exit 1
  fi
else
  derive > "$OUT"
  echo "wrote $OUT"
fi
