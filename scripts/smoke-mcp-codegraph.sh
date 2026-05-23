#!/usr/bin/env bash
# smoke-mcp-codegraph.sh — proves the bundled codegraph MCP server launches and answers.
#
# Drives a minimal MCP session over stdio (initialize -> initialized -> tools/list) and
# asserts the server advertises its tools (codegraph_search). This checks the bundled
# server actually starts and speaks MCP — independent of any per-repo index: tools/list
# is the static catalog; the index only matters at tools/call time, which the
# codegraph-autoindex SessionStart hook provisions.
#
# Two-phase to stay robust and fast:
#   1. Warm the npx cache (a plain --version fetch). codegraph's bundle is larger than
#      the @modelcontextprotocol servers, so the first fetch is slow; isolating it here
#      means the timed phase starts instantly and an offline first run SKIPs cleanly.
#   2. Send the messages, then hold stdin open briefly. codegraph's stdio transport
#      calls process.exit(0) on stdin EOF — closing stdin too early can truncate the
#      async tools/list reply. The short post-send hold lets the reply flush first.
#
# Requires Node/npx + jq. SKIPs cleanly (exit 0) when those are absent or the fetch
# fails offline, so it never blocks offline devs; CI has both and runs it for real.
set -uo pipefail

if ! command -v npx > /dev/null 2>&1; then
  echo "SKIP smoke-mcp-codegraph: npx not found (Node absent)" >&2
  exit 0
fi
if ! command -v jq > /dev/null 2>&1; then
  echo "SKIP smoke-mcp-codegraph: jq not found" >&2
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Shared package-spec selector (see scripts/test-mcp-spec-extraction.sh): the arg shaped
# like [@scope/]name@<version>, skipping codegraph's trailing `serve --mcp` args.
SPEC="$(jq -r '.mcpServers.codegraph.args[]? | select(type == "string" and test("^(@[A-Za-z0-9._-]+/)?[A-Za-z0-9._-]+@[0-9]"))' "$REPO_ROOT/.mcp.json" | head -1)"
if [ -z "$SPEC" ]; then
  echo "SKIP smoke-mcp-codegraph: could not read codegraph server spec from .mcp.json" >&2
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Phase 1 — warm the npx cache (and surface an offline first run as a SKIP).
if ! timeout 300 npx -y "$SPEC" --version < /dev/null > /dev/null 2> "$TMP/warm.log"; then
  # Only a clear NETWORK signature is treated as an offline SKIP. The broad 'npm error'
  # token is deliberately excluded: almost any npm failure prints it, so matching it would
  # silently SKIP genuine (non-network) failures — e.g. an unsupported flag — and hide a
  # real regression. Same network-token set as the memory/sequential-thinking smokes.
  if grep -qiE 'network|ENOTFOUND|EAI_AGAIN|registry|getaddrinfo|fetch failed|ETIMEDOUT' "$TMP/warm.log" 2> /dev/null; then
    echo "SKIP smoke-mcp-codegraph: package fetch failed (offline first run)" >&2
    exit 0
  fi
  echo "FAIL smoke-mcp-codegraph: 'npx $SPEC --version' failed (not a network issue)" >&2
  sed 's/^/  warm: /' "$TMP/warm.log" 2> /dev/null | head -10 >&2 || true
  exit 1
fi

# Phase 2 — drive a minimal MCP session against the now-cached server.
init='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"k0d3-smoke","version":"0"}}}'
inited='{"jsonrpc":"2.0","method":"notifications/initialized"}'
list='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

{
  printf '%s\n%s\n%s\n' "$init" "$inited" "$list"
  sleep 8
} |
  timeout 60 npx -y "$SPEC" serve --mcp --no-watch > "$TMP/out.log" 2> "$TMP/err.log"

# Pass criterion is a STRUCTURAL check of the tools/list reply (id:2), not a bare substring
# grep — a stray "codegraph_search" in banner/usage/log text on stdout must not pass. Assert
# the id:2 response carries a result whose tools[] advertises codegraph_search. Exit code is
# NOT the criterion: the server may be killed by the stdin-hold/timeout after it has already
# answered (same contract as the memory/sequential-thinking smokes).
ok="$(jq -rc 'select(.id == 2) | (.result.tools // [] | any(.name == "codegraph_search"))' "$TMP/out.log" 2> /dev/null | grep -m1 -x true || true)"
if [ -n "$ok" ]; then
  echo "smoke-mcp-codegraph: OK — server launched and advertised codegraph tools"
  exit 0
fi

echo "FAIL smoke-mcp-codegraph: server did not return a tools/list result advertising codegraph_search" >&2
sed 's/^/  stdout: /' "$TMP/out.log" 2> /dev/null | head -5 >&2 || true
sed 's/^/  stderr: /' "$TMP/err.log" 2> /dev/null | head -10 >&2 || true
exit 1
