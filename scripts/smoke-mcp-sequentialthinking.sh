#!/usr/bin/env bash
# smoke-mcp-sequentialthinking.sh — proves the bundled sequential-thinking MCP
# server actually works.
#
# Unlike the memory server, this one is STATELESS — it writes no store, so there
# is no file artifact to assert on. Instead this drives a minimal MCP session
# (initialize -> tools/call sequentialthinking) and asserts the server answers
# the call with a JSON-RPC *result* (not an error) on stdout. That verifies the
# package launches over stdio and its one tool responds.
#
# Requires Node/npx and jq, and (on first run) network to fetch the package.
# SKIPs cleanly (exit 0) when those are unavailable so it never blocks offline
# devs; in CI both are present so it runs for real.
set -uo pipefail

if ! command -v npx > /dev/null 2>&1; then
  echo "SKIP smoke-mcp-sequentialthinking: npx not found (Node absent)" >&2
  exit 0
fi
if ! command -v jq > /dev/null 2>&1; then
  echo "SKIP smoke-mcp-sequentialthinking: jq not found" >&2
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Shared package-spec selector: the @scope/name arg (with or without a trailing @version),
# not args[-1] — so it stays correct whether the server is pinned and if it ever gains
# trailing subcommand args. All bundled servers are scoped, so the @scope/ prefix is
# unambiguous; a future unscoped package would need this revisited.
# Keep this selector identical across its four consumers — smoke-mcp-{memory,sequentialthinking,codegraph}.sh
# and hooks/codegraph-autoindex.sh; no automated parity test guards them any more.
SPEC="$(jq -r '.mcpServers."sequential-thinking".args[]? | select(type == "string" and test("^@[A-Za-z0-9._-]+/[A-Za-z0-9._-]+"))' "$REPO_ROOT/.mcp.json" | head -1)"
if [ -z "$SPEC" ]; then
  echo "SKIP smoke-mcp-sequentialthinking: could not read sequential-thinking server spec from .mcp.json" >&2
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
OUT="$TMP/out.jsonl"
ERR="$TMP/err.log"

init='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"k0d3-smoke","version":"0"}}}'
inited='{"jsonrpc":"2.0","method":"notifications/initialized"}'
call='{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"sequentialthinking","arguments":{"thought":"smoke","nextThoughtNeeded":false,"thoughtNumber":1,"totalThoughts":1}}}'

printf '%s\n%s\n%s\n' "$init" "$inited" "$call" |
  timeout 120 npx -y "$SPEC" > "$OUT" 2> "$ERR"
rc=$?

# Did the id:2 call come back as a *successful* result? Three things must hold:
# a JSON-RPC `result` is present, there is no JSON-RPC `error`, and the result is
# not a tool-level failure (MCP wraps tool errors as `result.isError: true`, not
# as a JSON-RPC error — so checking only for `error` would pass on a broken tool).
# Server logs go to stderr; stdout carries only JSON-RPC, one object per line.
ok="$(jq -rc 'select(.id == 2) | (has("result") and (has("error") | not) and ((.result.isError // false) != true))' "$OUT" 2> /dev/null | grep -m1 -x true || true)"

if [ -z "$ok" ]; then
  if [ "$rc" -ne 0 ] && grep -qiE 'network|ENOTFOUND|EAI_AGAIN|registry|getaddrinfo|fetch failed|ETIMEDOUT' "$ERR" 2> /dev/null; then
    echo "SKIP smoke-mcp-sequentialthinking: package fetch failed (offline first run), rc=$rc" >&2
    exit 0
  fi
  echo "FAIL smoke-mcp-sequentialthinking: no successful result for the sequentialthinking call, rc=$rc" >&2
  sed 's/^/  stderr: /' "$ERR" >&2 || true
  exit 1
fi

echo "smoke-mcp-sequentialthinking: OK — server launched and the sequentialthinking tool returned a result"
exit 0
