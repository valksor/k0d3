#!/usr/bin/env bash
# codex-hooks-shim.sh — bridges Codex's hook environment to k0d3 hook scripts.
#
# k0d3's hook scripts expect Claude Code's env vars and several `exit 0` early if
# CLAUDE_PROJECT_DIR is unset. Codex does NOT set CLAUDE_PROJECT_DIR or
# CLAUDE_PLUGIN_ROOT for user/project-level hooks (and plugin-bundled hooks were
# removed in Codex), so this shim synthesizes both, then exec's the real script
# with stdin (the Codex hook event JSON) passed straight through.
#
# Invocation (baked into the generated hooks.json by install-codex-hooks.sh):
#   codex-hooks-shim.sh /abs/path/to/<hook>.sh
#
# - CLAUDE_PROJECT_DIR: Codex runs hooks in the session cwd, so $PWD is the
#   project root. Honor an explicit CODEX_PROJECT_DIR/CLAUDE_PROJECT_DIR if set.
# - CLAUDE_PLUGIN_ROOT: self-located as the parent of this shim's hooks/ dir,
#   i.e. the k0d3 runtime root that holds hooks/ and .mcp.json.
set -eu

SHIM_DIR="$(cd "$(dirname "$0")" && pwd)"

: "${CLAUDE_PROJECT_DIR:=${CODEX_PROJECT_DIR:-$PWD}}"
export CLAUDE_PROJECT_DIR
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$SHIM_DIR")}"

exec "$@"
