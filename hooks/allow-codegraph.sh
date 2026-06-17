#!/usr/bin/env bash
# PreToolUse(mcp__codegraph__*) hook — auto-approve codegraph MCP tool calls.
#
# k0d3 bundles the codegraph MCP server and its whole guidance (CLAUDE.md, the
# server instructions, prefer-codegraph) tells the agent to reach for codegraph
# freely — indexed, structural, sub-millisecond, read-only. But Claude Code
# prompts for permission on each MCP tool the user has not allowlisted, and new
# codegraph tools (e.g. codegraph_explore) arrive across version bumps faster
# than a hand-curated allowlist keeps up. The result is a permission prompt on
# nearly every codegraph call — defeating the point of bundling the server.
#
# Every codegraph tool is READ-ONLY (search / context / callers / callees /
# impact / node / explore / files / status — none mutate state), so blanket
# auto-approval is safe. This hook emits permissionDecision "allow" for any
# mcp__codegraph__* call, so the user is never prompted and future codegraph
# tools are covered automatically. Fail-soft: on any error or non-codegraph tool
# it exits 0 WITHOUT an allow, falling back to Claude Code's normal prompt.
# Output protocol mirrors prefer-codegraph.sh (exit 0 + hookSpecificOutput JSON).
#
# Trust boundary: the wildcard auto-approves every current AND future
# mcp__codegraph__* tool unprompted — safe only insofar as the codegraph package
# is trusted. That is the same trust already extended by running an unpinned,
# auto-indexing MCP server (codegraph-autoindex runs the package's code at session
# start), so the per-call prompt was never the boundary against a bad release.
# Disable the server via /mcp to make this hook inert. See docs/hooks.md.

set -uo pipefail

command -v jq > /dev/null 2>&1 || exit 0

input="$(cat)"

name="$(printf '%s' "$input" | jq -r '.tool_name // ""' 2> /dev/null || echo '')"

# Defensive guard: the hooks.json matcher already scopes this to mcp__codegraph__*,
# but re-check here so a loose matcher can never auto-allow a non-codegraph tool.
case "$name" in
  mcp__codegraph__*) ;;
  *) exit 0 ;;
esac

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    permissionDecisionReason: "codegraph MCP tools are read-only (indexed, structural, sub-millisecond); k0d3 auto-approves them so they never prompt."
  }
}'
exit 0
