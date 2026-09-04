#!/usr/bin/env bash
# SessionStart(startup) hook — protects the bundled memory MCP server's plaintext
# store. Two jobs, both idempotent and fail-open (any error -> exit 0):
#   1. Guarantee the host-specific state directory exists: .codex for Codex,
#      .claude for Claude Code. The memory server
#      (@modelcontextprotocol/server-memory) does NOT create its parent dir; a
#      first write to a missing parent returns ENOENT. k0d3 owns the directory.
#   2. Ensure memory.jsonl is gitignored so the store can never be
#      committed by accident — documentation alone is not enough.
# See skills/project-memory and docs/architecture.md (Bundled MCP servers).

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

if [ "${K0D3_HOST:-}" = "codex" ]; then
  MEMORY_DIR="$CLAUDE_PROJECT_DIR/.codex"
else
  MEMORY_DIR="$CLAUDE_PROJECT_DIR/.claude"
fi

# Job 1: always guarantee the store's parent dir exists.
mkdir -p "$MEMORY_DIR" 2> /dev/null || exit 0

# Job 2 only applies inside a git work tree.
git -C "$CLAUDE_PROJECT_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

# Already ignored — by our own state-dir .gitignore or a parent .gitignore? Stop.
if git -C "$CLAUDE_PROJECT_DIR" check-ignore -q "$MEMORY_DIR/memory.jsonl" 2> /dev/null; then
  exit 0
fi

GI="$MEMORY_DIR/.gitignore"
if [ -f "$GI" ] && grep -qE '^memory\.jsonl' "$GI" 2> /dev/null; then
  exit 0
fi

# Append the rule without clobbering existing content. Separate the size check
# from the append so the same file isn't read and written in one pipeline.
LEAD=""
[ -s "$GI" ] && LEAD=$'\n'
printf '%s# Added by k0d3: the local memory MCP server writes a plaintext store here — do not commit.\nmemory.jsonl\nmemory.jsonl.*\n' "$LEAD" >> "$GI" 2> /dev/null || exit 0

exit 0
