#!/usr/bin/env bash
# install-codex-hooks.sh — install k0d3's hooks into Codex CLI.
#
# Codex removed plugin-bundled hooks (feature `plugin_hooks` = removed), so the
# k0d3 Codex plugin delivers skills + MCP but NOT hooks. This script installs the
# hooks at the user level (~/.codex/hooks.json) or project level (.codex/hooks.json),
# deriving the Codex wiring from the single source of truth, hooks/hooks.json:
#   - drops ExitPlanMode (no Codex plan-mode hook) and PostToolUseFailure (no Codex event)
#   - routes every hook command through codex-hooks-shim.sh (synthesizes CLAUDE_* env)
#   - merges into any existing hooks.json WITHOUT clobbering the user's own hooks
#
# Usage:
#   scripts/install-codex-hooks.sh [--project] [--dry-run] [--uninstall] [--print]
#     (default)     install globally into ~/.codex/
#     --project     install into ./.codex/ for the current repo only
#     --dry-run     show what would change; write nothing
#     --print       print the derived Codex hooks JSON to stdout and exit
#     --uninstall   remove k0d3 hooks (and runtime) from the target
#
# Requires: bash 3.2+, jq.
set -eu

SRC="$(cd "$(dirname "$0")/.." && pwd)"   # k0d3 repo root
SCOPE="global"
DRY=0
UNINSTALL=0
PRINT=0

for arg in "$@"; do
  case "$arg" in
    --project) SCOPE="project" ;;
    --dry-run) DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --print) PRINT=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }

if [ "$SCOPE" = "project" ]; then
  BASE="$PWD/.codex"
else
  BASE="$HOME/.codex"
fi
HOOKS_HOME="$BASE/k0d3"          # stable runtime copy (scripts + .mcp.json + shim)
TARGET="$BASE/hooks.json"        # the file Codex reads
SHIM="$HOOKS_HOME/hooks/codex-hooks-shim.sh"
HD="$HOOKS_HOME/hooks"

# Derive the Codex hooks object from hooks/hooks.json (single source of truth).
# Every command is rewritten to: "<shim>" "<HD>/<name>.sh"
derive_hooks() {
  jq \
    --arg shim "$SHIM" \
    --arg hd "$HD" '
    .hooks
    | del(.PostToolUseFailure)
    | .PreToolUse |= map(select(.matcher != "ExitPlanMode"))
    | walk(
        if type == "object" and has("command")
        then ((.command | capture("hooks/(?<n>[A-Za-z0-9._-]+\\.sh)").n) as $n
              | .command = "\"\($shim)\" \"\($hd)/\($n)\"")
        else . end)
    | {hooks: .}
  ' "$SRC/hooks/hooks.json"
}

if [ "$PRINT" = "1" ]; then
  derive_hooks
  exit 0
fi

# Merge k0d3 hooks into an existing target without clobbering user hooks.
# k0d3 entries are identified by their command referencing $HD; on re-install we
# strip any prior k0d3 entries first (idempotent), then append the fresh ones.
merge_into_target() {
  local new_hooks="$1"
  if [ -f "$TARGET" ]; then
    jq \
      --argjson k0 "$new_hooks" \
      --arg hd "$HD" '
      (.hooks // {}) as $ex
      | ($k0.hooks) as $new
      | ($ex * (reduce ($new | keys_unsorted[]) as $evt ({};
            .[$evt] = (
              (($ex[$evt] // [])
                | map(select([ .hooks[]?.command // "" | contains($hd) ] | any | not)))
              + $new[$evt])))) as $merged
      | .hooks = $merged
    ' "$TARGET"
  else
    echo "$new_hooks"
  fi
}

strip_from_target() {
  jq --arg hd "$HD" '
    if .hooks then
      .hooks |= with_entries(
        .value |= map(select([ .hooks[]?.command // "" | contains($hd) ] | any | not)))
      | .hooks |= with_entries(select(.value | length > 0))
    else . end
  ' "$TARGET"
}

if [ "$UNINSTALL" = "1" ]; then
  if [ -f "$TARGET" ]; then
    OUT="$(strip_from_target)"
    if [ "$DRY" = "1" ]; then
      echo "[dry-run] would rewrite $TARGET to:"; echo "$OUT"
    else
      printf '%s\n' "$OUT" > "$TARGET"
      echo "removed k0d3 hooks from $TARGET"
    fi
  fi
  if [ -d "$HOOKS_HOME" ]; then
    if [ "$DRY" = "1" ]; then echo "[dry-run] would rm -rf $HOOKS_HOME"; else rm -rf "$HOOKS_HOME"; echo "removed $HOOKS_HOME"; fi
  fi
  exit 0
fi

NEW_HOOKS="$(derive_hooks)"
MERGED="$(merge_into_target "$NEW_HOOKS")"

if [ "$DRY" = "1" ]; then
  echo "[dry-run] scope=$SCOPE"
  echo "[dry-run] would copy $SRC/hooks -> $HD and $SRC/.mcp.json -> $HOOKS_HOME/.mcp.json"
  echo "[dry-run] would write $TARGET:"
  echo "$MERGED"
  exit 0
fi

# Install runtime: copy hooks/ + .mcp.json to a stable home so removing the repo
# does not break the installed hooks.
mkdir -p "$HD"
cp "$SRC"/hooks/*.sh "$HD"/
[ -f "$SRC/.mcp.json" ] && cp "$SRC/.mcp.json" "$HOOKS_HOME/.mcp.json"
chmod +x "$HD"/*.sh 2>/dev/null || true

printf '%s\n' "$MERGED" > "$TARGET"

echo "installed k0d3 hooks ($SCOPE) -> $TARGET"
echo "runtime: $HOOKS_HOME"
echo "Run 'codex' and use /hooks to review and trust them (do NOT use --bypass-hook-trust)."
