#!/usr/bin/env bash
# check-mcp-pin.sh — supply-chain guard for the bundled memory MCP server.
#
# npm version tags are NOT immutable: a maintainer (or an attacker who
# compromises the @modelcontextprotocol org) can republish the same tag with
# different bytes. Because the server is auto-enabled for every k0d3 install and
# runs local code via `npx`, the blast radius is every machine. This asserts the
# pinned version still resolves to the exact tarball we vetted. Run in CI and on
# a weekly schedule. Requires network + npm.
#
# Exit: 0 = match, 1 = MISMATCH (investigate before trusting), 2 = could not check.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Derive package + pinned version from .mcp.json so this can never drift from the
# real config. The memory server's last arg is "<pkg>@<version>".
SPEC="$(jq -r '.mcpServers.memory.args[-1] // empty' "$REPO_ROOT/.mcp.json")"
if [ -z "$SPEC" ]; then
  echo "check-mcp-pin: no memory server spec in .mcp.json — nothing to check" >&2
  exit 2
fi
PKG="${SPEC%@*}"  # strip the trailing @version (the scope's leading @ is kept)
PIN="${SPEC##*@}" # the version after the last @

# The vetted integrity for the pinned version. When bumping PIN, update this
# deliberately: run `npm view <pkg>@<new-version> dist.integrity` and paste it.
EXPECTED_INTEGRITY="sha512-7F0hbaEB4lVqkYhNWmrC5jJjEWPCofgXd7OIk3h97HyvJL6aTAhlUNYaH8lCDxAzlK9sr2pLCkZEYI+m4HSOiA=="

ACTUAL="$(npm view "${PKG}@${PIN}" dist.integrity 2> /dev/null || true)"
if [ -z "$ACTUAL" ]; then
  echo "check-mcp-pin: could not fetch dist.integrity for ${PKG}@${PIN} (network/npm unavailable)" >&2
  exit 2
fi

if [ "$ACTUAL" != "$EXPECTED_INTEGRITY" ]; then
  echo "check-mcp-pin: INTEGRITY MISMATCH for ${PKG}@${PIN}" >&2
  echo "  expected: $EXPECTED_INTEGRITY" >&2
  echo "  actual:   $ACTUAL" >&2
  echo "The pinned tag was republished with different bytes. Do NOT bump the pin until investigated." >&2
  exit 1
fi

echo "check-mcp-pin: OK — ${PKG}@${PIN} integrity matches"
exit 0
