#!/usr/bin/env bash
# Stop hook — logs a session-ended event for trend analysis across sessions.
#
# History: this hook used to consume a verdict (block/ended) from a haiku
# review prompt and maintain a quality-gate counter. The prompt hook was
# removed; DECISION is now always "ended". The block-tracking logic was dead
# code and has been deleted. If verdict tracking is reintroduced, the design
# needs to specify how DECISION is sourced (stdin envelope, env var, etc.).

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
