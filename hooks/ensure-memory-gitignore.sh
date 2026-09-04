#!/usr/bin/env bash
# SessionStart(startup) hook — protects the bundled memory MCP server's plaintext
# store. Two jobs, both idempotent and fail-open (any error -> exit 0):
#   1. Guarantee the Claude (.claude/) and Codex (.codex/) store directories
#      exist. The memory server does NOT create its parent dir.
#   2. Ensure each host's memory.jsonl and memory.jsonl.* sidecars are
#      gitignored so plaintext memory can never be committed by accident.
# See skills/project-memory and docs/architecture.md (Bundled MCP servers).

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

CLAUDE_DIR="$CLAUDE_PROJECT_DIR/.claude"
CODEX_DIR="$CLAUDE_PROJECT_DIR/.codex"

# Job 1: guarantee each safe store parent dir exists. Never follow a
# repository-controlled directory symlink; skip only that host's unsafe path.
claude_ready=0
codex_ready=0
if [ ! -L "$CLAUDE_DIR" ] && mkdir -p "$CLAUDE_DIR" 2> /dev/null; then
  claude_ready=1
fi
if [ ! -L "$CODEX_DIR" ] && mkdir -p "$CODEX_DIR" 2> /dev/null; then
  codex_ready=1
fi

# Job 2 only applies inside a git work tree.
git -C "$CLAUDE_PROJECT_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 0

ensure_memory_ignored() {
  store_dir="$1"
  gitignore_file="$store_dir/.gitignore"

  # Recheck the directory after creation and reject a symlinked ignore file.
  # Both paths are repository-controlled and must never redirect this append.
  [ -L "$store_dir" ] && return 0
  [ -L "$gitignore_file" ] && return 0

  # A parent rule may already cover the directory. Check both the main file and
  # a representative sidecar because ignoring only memory.jsonl is insufficient.
  if git -C "$CLAUDE_PROJECT_DIR" check-ignore -q "$store_dir/memory.jsonl" 2> /dev/null &&
    git -C "$CLAUDE_PROJECT_DIR" check-ignore -q "$store_dir/memory.jsonl.tmp" 2> /dev/null; then
    return 0
  fi

  missing_store=0
  missing_sidecars=0
  missing_comment=0
  grep -Fxq 'memory.jsonl' "$gitignore_file" 2> /dev/null || missing_store=1
  grep -Fxq 'memory.jsonl.*' "$gitignore_file" 2> /dev/null || missing_sidecars=1
  grep -Fxq '# Added by k0d3: the local memory MCP server writes a plaintext store here — do not commit.' "$gitignore_file" 2> /dev/null || missing_comment=1
  [ "$missing_store" -eq 0 ] && [ "$missing_sidecars" -eq 0 ] && return 0

  # Append only missing rules without clobbering user content or duplicating a
  # rule that was already present.
  lead=""
  [ -s "$gitignore_file" ] && lead=$'\n'
  {
    printf '%s' "$lead"
    if [ "$missing_comment" -eq 1 ]; then
      printf '%s\n' '# Added by k0d3: the local memory MCP server writes a plaintext store here — do not commit.'
    fi
    [ "$missing_store" -eq 1 ] && printf '%s\n' 'memory.jsonl'
    [ "$missing_sidecars" -eq 1 ] && printf '%s\n' 'memory.jsonl.*'
  } >> "$gitignore_file" 2> /dev/null || return 0

  return 0
}

[ "$claude_ready" -eq 1 ] && ensure_memory_ignored "$CLAUDE_DIR"
[ "$codex_ready" -eq 1 ] && ensure_memory_ignored "$CODEX_DIR"

exit 0
