#!/usr/bin/env bash
# SessionStart(user) hook — resets stale state on fresh session start.
# Cleans up gate files, validates agent definitions, checks permissions.

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
AGENTS_DIR="$CLAUDE_PROJECT_DIR/agents"
HOOKS_DIR="$CLAUDE_PROJECT_DIR/hooks"

mkdir -p "$LOG_DIR"

# ═══════════════════════════════════════════════════════
# 1. Reset stale gate files (prevents cross-session deadlocks)
# ═══════════════════════════════════════════════════════
rm -f "$LOG_DIR/.quality-gate-active" \
  "$LOG_DIR/.tool-call-count" \
  "$LOG_DIR/.compaction-occurred" 2> /dev/null

# Clean up stale session-blocks and plan-review gate files (older than 2h).
# Plan-review gates are session-scoped (.plan-review-gate-<id>), so prune by age,
# not by exact name — a startup must never delete a concurrent session's fresh gate.
find "$LOG_DIR" -name ".session-blocks-*" -mmin +120 -delete 2> /dev/null
find "$LOG_DIR" -name ".plan-review-gate*" -mmin +120 -delete 2> /dev/null

# ═══════════════════════════════════════════════════════
# 2. Validate hook scripts are executable (B7: was .claude/hooks; hooks live at $CLAUDE_PROJECT_DIR/hooks)
# ═══════════════════════════════════════════════════════
if [ -d "$HOOKS_DIR" ]; then
  HOOK_ISSUES=0
  for hook in "$HOOKS_DIR"/*.sh; do
    [ ! -f "$hook" ] && continue
    if [ ! -x "$hook" ]; then
      chmod +x "$hook" 2> /dev/null
      HOOK_ISSUES=$((HOOK_ISSUES + 1))
    fi
  done
  if [ "$HOOK_ISSUES" -gt 0 ]; then
    echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | INFO | Fixed permissions on $HOOK_ISSUES hook scripts" >> "$LOG_DIR/incident-log.md"
  fi
fi

# ═══════════════════════════════════════════════════════
# 3. Validate agent definitions exist and have frontmatter
# ═══════════════════════════════════════════════════════
if [ -d "$AGENTS_DIR" ]; then
  AGENT_ISSUES=""
  # Agents live under agents/{workflow,reviewers,experts}/*.md — recurse
  while IFS= read -r agent; do
    [ ! -f "$agent" ] && continue
    AGENT_NAME=$(basename "$agent" .md)
    if ! head -1 "$agent" | grep -q '^---'; then
      AGENT_ISSUES="$AGENT_ISSUES $AGENT_NAME(no-frontmatter)"
    fi
  done < <(find "$AGENTS_DIR" -type f -name '*.md' 2> /dev/null)

  if [ -n "$AGENT_ISSUES" ]; then
    echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | WARN | Agent issues:$AGENT_ISSUES" >> "$LOG_DIR/incident-log.md"
  fi
fi

# ═══════════════════════════════════════════════════════
# 4. Ensure required runtime directories exist
# ═══════════════════════════════════════════════════════
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/agent-memory" \
  "$CLAUDE_PROJECT_DIR/.claude/backups" 2> /dev/null

# ═══════════════════════════════════════════════════════
# 5. Prune old log files (keep last 30 days)
# ═══════════════════════════════════════════════════════
if [ -f "$LOG_DIR/audit-trail.md" ]; then
  LINE_COUNT=$(wc -l < "$LOG_DIR/audit-trail.md" | tr -d ' ')
  if [ "$LINE_COUNT" -gt 5000 ]; then
    # C3: explicit step-by-step with failure handling; never leaves the
    # original truncated if tail or mv fails (disk full, perms).
    TMP="$LOG_DIR/audit-trail.md.tmp"
    if ! tail -2000 "$LOG_DIR/audit-trail.md" > "$TMP" 2> /dev/null; then
      rm -f "$TMP" 2> /dev/null
      echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | WARN | Failed to prune audit-trail (tail error); kept original" >> "$LOG_DIR/incident-log.md"
    elif ! mv "$TMP" "$LOG_DIR/audit-trail.md" 2> /dev/null; then
      rm -f "$TMP" 2> /dev/null
      echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | WARN | Failed to swap audit-trail (mv error); kept original" >> "$LOG_DIR/incident-log.md"
    else
      echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | INFO | Pruned audit trail from $LINE_COUNT to 2000 lines" >> "$LOG_DIR/incident-log.md"
    fi
  fi
fi

exit 0
