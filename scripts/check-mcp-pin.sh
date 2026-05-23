#!/usr/bin/env bash
# check-mcp-pin.sh — supply-chain guard for the bundled stdio MCP servers.
#
# npm dist-tags are mutable, and even an exact version can be unpublished and
# republished within npm's 72h window (or served differently by a compromised
# registry/org). Because these servers are auto-enabled for every k0d3 install
# and run local code via `npx`, the blast radius is every machine. This asserts
# each pinned spec still resolves to the exact tarball we vetted. Run in CI and
# on a weekly schedule. Requires network + npm.
#
# Drift-proof: the server LIST is derived from .mcp.json (every stdio server),
# never hardcoded — so a newly bundled stdio server cannot slip in unchecked. If
# one has no vetted integrity recorded below, this fails closed (exit 2).
#
# To bump a pin: change the version in .mcp.json, then update the matching
# integrity below. Get the value with:
#   npm view <pkg>@<version> dist.integrity
#
# Exit: 0 = all verified, 1 = MISMATCH (investigate before trusting),
#       2 = could not verify one or more (network down, or an unvetted server).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_JSON="$REPO_ROOT/.mcp.json"

# Vetted integrity per server key — the trust anchor; update deliberately (see
# header). bash 3.2 has no associative arrays (macOS system bash), so a case
# statement is the portable lookup.
expected_integrity() {
  case "$1" in
    memory)
      echo "sha512-7F0hbaEB4lVqkYhNWmrC5jJjEWPCofgXd7OIk3h97HyvJL6aTAhlUNYaH8lCDxAzlK9sr2pLCkZEYI+m4HSOiA=="
      ;;
    sequential-thinking)
      echo "sha512-eFR5I9Z9czXQhDn05wahetZU83YNPO+p1HLSEZZEM5q9U1CLF7zv9+TrmSBfRoPaksEAoM8pTWQ33lRCScSFeQ=="
      ;;
    *)
      echo ""
      ;;
  esac
}

# Every stdio server in .mcp.json. Keys are kebab-case with no spaces, so a
# word-split `for` loop is safe. context7 (type "http") is excluded.
SERVERS="$(jq -r '.mcpServers | to_entries[] | select(.value.type == "stdio") | .key' "$MCP_JSON")"
if [ -z "$SERVERS" ]; then
  echo "check-mcp-pin: no stdio servers in .mcp.json — nothing to check" >&2
  exit 2
fi

# A real mismatch fails fast (exit 1). A server we couldn't verify (network down,
# or no vetted hash) doesn't abort the loop — we still try every other server,
# then exit 2 at the end. That way one flaky `npm view` never hides a second
# server's state, and an unvetted server is always surfaced.
unverified=0
for key in $SERVERS; do
  SPEC="$(jq -r --arg k "$key" '.mcpServers[$k].args[-1] // empty' "$MCP_JSON")"
  if [ -z "$SPEC" ]; then
    echo "check-mcp-pin: '$key' is stdio but has no <pkg>@<version> arg — refusing to trust" >&2
    unverified=1
    continue
  fi

  EXPECTED="$(expected_integrity "$key")"
  if [ -z "$EXPECTED" ]; then
    echo "check-mcp-pin: '$key' ($SPEC) is a bundled stdio server with no vetted integrity recorded — refusing to trust. Add it to expected_integrity()." >&2
    unverified=1
    continue
  fi

  ACTUAL="$(npm view "$SPEC" dist.integrity 2> /dev/null || true)"
  if [ -z "$ACTUAL" ]; then
    echo "check-mcp-pin: could not fetch dist.integrity for $SPEC (network/npm unavailable)" >&2
    unverified=1
    continue
  fi

  if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "check-mcp-pin: INTEGRITY MISMATCH for $SPEC" >&2
    echo "  expected: $EXPECTED" >&2
    echo "  actual:   $ACTUAL" >&2
    echo "The pinned spec was republished with different bytes. Do NOT bump the pin until investigated." >&2
    exit 1
  fi

  echo "check-mcp-pin: OK — $SPEC integrity matches"
done

if [ "$unverified" -ne 0 ]; then
  echo "check-mcp-pin: one or more servers could not be verified (see above)" >&2
  exit 2
fi

exit 0
