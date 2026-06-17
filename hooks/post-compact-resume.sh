#!/usr/bin/env bash
# SessionStart(compact) hook — restores context after auto-compaction.
# Reads the marker left by pre-compact-handoff.sh, resets counters,
# and injects resumption instructions for Claude.

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
MARKER="$LOG_DIR/.compaction-occurred"

# Only run if compaction actually occurred
if [ ! -f "$MARKER" ]; then
  exit 0
fi

# Reset session counters. NB: the plan-review gate is deliberately NOT cleared here
# — it is session-scoped and survives compaction so an armed-but-unpresented plan
# still passes through on re-presentation instead of forcing a redundant re-review.
rm -f "$LOG_DIR/.tool-call-count" "$LOG_DIR/.quality-gate-active" 2> /dev/null

# Read compaction timestamp
COMPACT_TIME=$(cat "$MARKER" 2> /dev/null || echo "unknown")

# Clean up marker
rm -f "$MARKER"

# Output resumption context for Claude
echo "POST-COMPACTION RESUME: Context was auto-compacted at $COMPACT_TIME. Session state was preserved in memory.md and daily note. Read .claude/memory.md and the latest Daily Note (look for the latest Session Handoff) to reload context, then continue working on whatever task was in progress. Do not ask the user what to do — just resume seamlessly."

exit 0
