#!/usr/bin/env bash
# SessionStart hook — warns when k0d3 skill/agent/command names also exist in
# other installed plugins. Bare names (e.g. /review) resolve by plugin load
# order, so silent shadowing is a real failure mode when multiple plugins are installed.
#
# This hook is ADVISORY ONLY. It always exits 0 and never blocks the session.
# Output is written to .claude/logs/collision-report.log; warnings are also
# echoed to stderr for visibility on session start.
#
# To enable: move this entry from hooks.json's _disabled_examples into the
# active SessionStart array. When no other plugin defines colliding names,
# the report stays empty.

set -uo pipefail

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"
REPORT="$LOG_DIR/collision-report.log"

# Candidate plugin install roots — extend if your Claude Code uses a custom one.
PLUGIN_ROOTS=(
  "$HOME/.claude/plugins"
  "$HOME/.claude-code/plugins"
  "$HOME/.config/claude/plugins"
)

# Drain stdin (Claude Code SessionStart envelope) — we don't need it but must
# not leave it dangling for downstream hooks.
[ ! -t 0 ] && cat > /dev/null 2>&1 || true

# ── Step 1: collect k0d3's own names ──────────────────────────────────────
declare -a K0D3_NAMES=()

# Skills (one level under skills/)
if [ -d "$CLAUDE_PROJECT_DIR/skills" ]; then
  while IFS= read -r d; do
    K0D3_NAMES+=("skill:$(basename "$d")")
  done < <(find "$CLAUDE_PROJECT_DIR/skills" -maxdepth 1 -mindepth 1 -type d 2> /dev/null)
fi

# Agents (recursive — workflow/, reviewers/, experts/)
if [ -d "$CLAUDE_PROJECT_DIR/agents" ]; then
  while IFS= read -r f; do
    K0D3_NAMES+=("agent:$(basename "$f" .md)")
  done < <(find "$CLAUDE_PROJECT_DIR/agents" -type f -name "*.md" 2> /dev/null)
fi

# Commands (recursive — workflow/, plan/, execute/, review/, analyze/)
if [ -d "$CLAUDE_PROJECT_DIR/commands" ]; then
  while IFS= read -r f; do
    K0D3_NAMES+=("command:$(basename "$f" .md)")
  done < <(find "$CLAUDE_PROJECT_DIR/commands" -type f -name "*.md" 2> /dev/null)
fi

# ── Step 2: scan installed plugins, build collision list ──────────────────
COLLISIONS=""
COLLISION_COUNT=0

for ROOT in "${PLUGIN_ROOTS[@]}"; do
  [ ! -d "$ROOT" ] && continue

  while IFS= read -r PLUGIN_DIR; do
    PLUGIN_NAME="$(basename "$PLUGIN_DIR")"
    # Skip k0d3 itself if it's installed under one of these roots.
    [ "$PLUGIN_NAME" = "k0d3" ] && continue

    for entry in "${K0D3_NAMES[@]}"; do
      KIND="${entry%%:*}"
      NAME="${entry#*:}"

      case "$KIND" in
        skill)
          if [ -d "$PLUGIN_DIR/skills/$NAME" ]; then
            COLLISIONS+="  skill '$NAME' — also in plugin '$PLUGIN_NAME' (prefer 'k0d3:$NAME')"$'\n'
            COLLISION_COUNT=$((COLLISION_COUNT + 1))
          fi
          ;;
        agent)
          # Agents may sit at any depth under agents/
          if find "$PLUGIN_DIR/agents" -type f -name "${NAME}.md" 2> /dev/null | grep -q .; then
            COLLISIONS+="  agent '$NAME' — also in plugin '$PLUGIN_NAME' (prefer 'k0d3:$NAME')"$'\n'
            COLLISION_COUNT=$((COLLISION_COUNT + 1))
          fi
          ;;
        command)
          if find "$PLUGIN_DIR/commands" -type f -name "${NAME}.md" 2> /dev/null | grep -q .; then
            COLLISIONS+="  command '/$NAME' — also in plugin '$PLUGIN_NAME' (prefer '/k0d3:$NAME')"$'\n'
            COLLISION_COUNT=$((COLLISION_COUNT + 1))
          fi
          ;;
      esac
    done
  done < <(find "$ROOT" -maxdepth 2 -mindepth 1 -type d 2> /dev/null)
done

# ── Step 3: write report + emit stderr warning ────────────────────────────
TS="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "── $TS — collision scan ──"
  if [ "$COLLISION_COUNT" -eq 0 ]; then
    echo "  no collisions detected (${#K0D3_NAMES[@]} k0d3 names checked)"
  else
    echo "  $COLLISION_COUNT collision(s) detected:"
    printf '%s' "$COLLISIONS"
  fi
} >> "$REPORT"

if [ "$COLLISION_COUNT" -gt 0 ]; then
  {
    echo "k0d3 name-collision advisory — $COLLISION_COUNT name(s) shadow other plugins:"
    printf '%s' "$COLLISIONS"
    echo "Use the explicit 'k0d3:' prefix to disambiguate. Full report: $REPORT"
  } >&2
fi

exit 0
