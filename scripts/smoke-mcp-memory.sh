#!/usr/bin/env bash
# smoke-mcp-memory.sh — proves the bundled memory MCP server actually works.
#
# Launches it over stdio with a temp MEMORY_FILE_PATH, drives a minimal MCP
# session (initialize -> create_entities), and asserts it persists the entity at
# the configured path. This verifies env-var path resolution and store self-init
# — the behaviours the rest of the suite only asserts in prose.
#
# Requires Node/npx and (on first run) network to fetch the package. SKIPs
# cleanly (exit 0) when those are unavailable so it never blocks offline devs; in
# CI both are present so it runs for real.
set -uo pipefail

if ! command -v npx > /dev/null 2>&1; then
  echo "SKIP smoke-mcp-memory: npx not found (Node absent)" >&2
  exit 0
fi
if ! command -v jq > /dev/null 2>&1; then
  echo "SKIP smoke-mcp-memory: jq not found" >&2
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Shared package-spec selector: the @scope/name arg (with or without a trailing @version),
# not args[-1] — so it stays correct whether the server is pinned and if it ever gains
# trailing subcommand args. All bundled servers are scoped, so the @scope/ prefix is
# unambiguous; a future unscoped package would need this revisited.
# Keep this selector identical across its four consumers — smoke-mcp-{memory,sequentialthinking,codegraph}.sh
# and hooks/codegraph-autoindex.sh; no automated parity test guards them any more.
SPEC="$(jq -r '.mcpServers.memory.args[]? | select(type == "string" and test("^@[A-Za-z0-9._-]+/[A-Za-z0-9._-]+"))' "$REPO_ROOT/.mcp.json" | head -1)"
if [ -z "$SPEC" ]; then
  echo "SKIP smoke-mcp-memory: could not read memory server spec from .mcp.json" >&2
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Mirror production: k0d3's SessionStart hook ensures .claude/ exists before any
# write (the server does NOT create its parent dir).
mkdir -p "$TMP/.claude"
STORE="$TMP/.claude/memory.jsonl"

init='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"k0d3-smoke","version":"0"}}}'
inited='{"jsonrpc":"2.0","method":"notifications/initialized"}'
call='{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"create_entities","arguments":{"entities":[{"name":"k0d3-smoke","entityType":"test","observations":["smoke ok"]}]}}}'

printf '%s\n%s\n%s\n' "$init" "$inited" "$call" |
  MEMORY_FILE_PATH="$STORE" timeout 120 npx -y "$SPEC" > /dev/null 2> "$TMP/err.log"
rc=$?

if [ ! -f "$STORE" ]; then
  if [ "$rc" -ne 0 ] && grep -qiE 'network|ENOTFOUND|EAI_AGAIN|registry|getaddrinfo|fetch failed|ETIMEDOUT' "$TMP/err.log" 2> /dev/null; then
    echo "SKIP smoke-mcp-memory: package fetch failed (offline first run), rc=$rc" >&2
    exit 0
  fi
  echo "FAIL smoke-mcp-memory: store not created at \$MEMORY_FILE_PATH ($STORE), rc=$rc" >&2
  sed 's/^/  stderr: /' "$TMP/err.log" >&2 || true
  exit 1
fi

if ! grep -q 'k0d3-smoke' "$STORE" 2> /dev/null; then
  echo "FAIL smoke-mcp-memory: store created but test entity not persisted" >&2
  exit 1
fi

echo "smoke-mcp-memory: OK — server resolved MEMORY_FILE_PATH and persisted the entity"
exit 0
