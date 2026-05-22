#!/usr/bin/env bash
# Stop hook — logs a session-ended event for trend analysis across sessions.
# Writes one JSONL line per session end; `decision` is always "ended"
# (no verdict or quality-gate logic).

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
VERDICT_LOG="$LOG_DIR/verdicts.jsonl"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

mkdir -p "$LOG_DIR"

# Read and discard any stdin to avoid broken-pipe noise
cat > /dev/null 2>&1 || true

jq -n --arg ts "$TIMESTAMP" \
  '{timestamp: $ts, decision: "ended"}' \
  >> "$VERDICT_LOG"

exit 0
