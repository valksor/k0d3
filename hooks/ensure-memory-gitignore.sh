#!/usr/bin/env bash
# SessionStart(startup) hook — protects the bundled memory MCP server's plaintext
# store. Two jobs, both idempotent and fail-open (any error -> exit 0):
#   1. Guarantee the host-specific state directory exists: .codex for Codex,
#      .claude for Claude Code. The memory server does not create its parent dir.
#   2. Ensure memory.jsonl and memory.jsonl.* sidecars are gitignored so
#      plaintext memory can never be committed by accident. Self-ignore the
#      generated .gitignore so enabling memory does not dirty the repository.
# See skills/project-memory and docs/architecture.md (Bundled MCP servers).

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

if [ "${K0D3_HOST:-}" = "codex" ]; then
  MEMORY_DIR="$CLAUDE_PROJECT_DIR/.codex"
else
  MEMORY_DIR="$CLAUDE_PROJECT_DIR/.claude"
fi

# Never follow a repository-controlled directory or ignore-file symlink.
[ -L "$MEMORY_DIR" ] && exit 0
mkdir -p "$MEMORY_DIR" 2> /dev/null || exit 0

# Ignore rules only apply inside a git work tree.
git -C "$CLAUDE_PROJECT_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

GITIGNORE_FILE="$MEMORY_DIR/.gitignore"
[ -L "$MEMORY_DIR" ] && exit 0
[ -L "$GITIGNORE_FILE" ] && exit 0

# A parent rule may already cover the directory. Check the main file and a
# representative sidecar because ignoring only memory.jsonl is insufficient.
if [ ! -e "$GITIGNORE_FILE" ] &&
  git -C "$CLAUDE_PROJECT_DIR" check-ignore -q "$MEMORY_DIR/memory.jsonl" 2> /dev/null &&
  git -C "$CLAUDE_PROJECT_DIR" check-ignore -q "$MEMORY_DIR/memory.jsonl.tmp" 2> /dev/null; then
  exit 0
fi

missing_store=0
missing_sidecars=0
missing_self=0
missing_comment=0
grep -Fxq 'memory.jsonl' "$GITIGNORE_FILE" 2> /dev/null || missing_store=1
grep -Fxq 'memory.jsonl.*' "$GITIGNORE_FILE" 2> /dev/null || missing_sidecars=1
grep -Fxq '.gitignore' "$GITIGNORE_FILE" 2> /dev/null || missing_self=1
grep -Fxq '# Added by k0d3: the local memory MCP server writes a plaintext store here — do not commit.' "$GITIGNORE_FILE" 2> /dev/null || missing_comment=1
[ "$missing_store" -eq 0 ] && [ "$missing_sidecars" -eq 0 ] && [ "$missing_self" -eq 0 ] && exit 0

# Append only missing rules without clobbering user content or duplicating a
# rule that was already present.
lead=""
[ -s "$GITIGNORE_FILE" ] && lead=$'\n'
{
  printf '%s' "$lead"
  if [ "$missing_comment" -eq 1 ]; then
    printf '%s\n' '# Added by k0d3: the local memory MCP server writes a plaintext store here — do not commit.'
  fi
  [ "$missing_self" -eq 1 ] && printf '%s\n' '.gitignore'
  [ "$missing_store" -eq 1 ] && printf '%s\n' 'memory.jsonl'
  [ "$missing_sidecars" -eq 1 ] && printf '%s\n' 'memory.jsonl.*'
} >> "$GITIGNORE_FILE" 2> /dev/null || exit 0

exit 0
