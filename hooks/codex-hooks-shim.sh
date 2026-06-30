#!/usr/bin/env bash
# codex-hooks-shim.sh — bridges Codex's hook environment to k0d3 hook scripts.
#
# k0d3's hook scripts expect Claude Code's env vars and several `exit 0` early if
# CLAUDE_PROJECT_DIR is unset. Codex DOES set CLAUDE_PLUGIN_ROOT for plugin-channel
# hooks but NOT CLAUDE_PROJECT_DIR, so this shim synthesizes the project dir, marks
# the host as Codex, then exec's the real script with stdin (the Codex hook event
# JSON) passed straight through. It is wired in by scripts/generate-codex-hooks.sh.
#
# Invocation (baked into hooks/hooks.codex.json):
#   codex-hooks-shim.sh "${CLAUDE_PLUGIN_ROOT}/hooks/<hook>.sh"
#
# - CLAUDE_PROJECT_DIR: Codex runs hooks in the session cwd, so $PWD is the
#   project root. Honor an explicit CODEX_PROJECT_DIR/CLAUDE_PROJECT_DIR if set.
# - CLAUDE_PLUGIN_ROOT: set by Codex for plugin hooks; fall back to self-locating
#   as the parent of this shim's hooks/ dir.
# - K0D3_HOST=codex: lets dual-emit hooks (e.g. verify-before-stop.sh) pick the
#   Codex output schema. A Codex `Stop` carries hook_event_name="Stop" just like
#   Claude does, so the event name alone cannot tell the hosts apart — this marker
#   can, because the shim only ever runs under Codex.
set -eu

SHIM_DIR="$(cd "$(dirname "$0")" && pwd)"

: "${CLAUDE_PROJECT_DIR:=${CODEX_PROJECT_DIR:-$PWD}}"
export CLAUDE_PROJECT_DIR
export CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$SHIM_DIR")}"
export K0D3_HOST=codex

exec "$@"
