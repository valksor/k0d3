#!/usr/bin/env bash
# start-memory.sh — launcher for the @modelcontextprotocol/server-memory MCP server.
#
# Why this exists: the Claude .mcp.json hard-codes MEMORY_FILE_PATH to
# ${CLAUDE_PROJECT_DIR}/.claude/memory.jsonl, relying on Claude Code's
# config-level env interpolation. Codex plugins do not guarantee that variable,
# and nested ${VAR:-$PWD} interpolation inside JSON is non-portable. So the
# Codex .mcp.codex.json points the memory server's `command` at this wrapper,
# which resolves the project directory at RUNTIME and exec's the real server.
#
# Resolution order for the project dir: CODEX_PROJECT_DIR, then CLAUDE_PROJECT_DIR,
# then PWD. We refuse to scope memory to $HOME (would commingle every session's
# memory into one home-level file); in that case we fall back to a Codex-global
# store under ~/.codex so it is at least explicit and never inside a git work tree
# by accident.
set -eu

PROJ="${CODEX_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}"

# Never write memory into the bare home directory (dotfiles repos commonly track it).
if [ "$PROJ" = "$HOME" ] || [ -z "$PROJ" ]; then
  TARGET_DIR="$HOME/.codex/k0d3"
else
  TARGET_DIR="$PROJ/.codex"
fi

mkdir -p "$TARGET_DIR"
export MEMORY_FILE_PATH="$TARGET_DIR/memory.jsonl"

exec npx -y @modelcontextprotocol/server-memory
