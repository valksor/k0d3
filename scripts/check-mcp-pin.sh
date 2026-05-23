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
# codegraph is a thin launcher whose real code ships as per-platform optional-deps;
# those are pinned separately in cg_platform_integrity() below the main loop — bump
# them in lockstep with the launcher version.
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
    codegraph)
      # Thin launcher package only. The code that actually executes lives in a
      # per-platform optional-dependency, verified separately by cg_platform_integrity.
      echo "sha512-UJe7wMKnK0IPyN+mRUUUnnfF55rXiwQL8hzpwb0djLrdvy6L3rdK4WXX/sOek+Eih3ANt6YGhv1Ay3vxbRpqRg=="
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
  # The pinned spec is the arg shaped like [@scope/]name@<version>. Anchored so a stray
  # arg merely CONTAINING "@<digit>" can't be mistaken for the package (verify-vs-execute
  # can't drift). NOT args[-1]: some servers (codegraph) carry trailing subcommand args
  # (serve --mcp) after the spec. This exact selector is shared by every consumer
  # (smoke-mcp-*.sh, codegraph-autoindex.sh); scripts/test-mcp-spec-extraction.sh guards
  # them against divergence.
  SPEC="$(jq -r --arg k "$key" '.mcpServers[$k].args[]? | select(type == "string" and test("^(@[A-Za-z0-9._-]+/)?[A-Za-z0-9._-]+@[0-9]"))' "$MCP_JSON" | head -1)"
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

# codegraph ships a thin launcher whose real code is a per-platform optional-dep — the
# main loop above pinned only that launcher. This block verifies the bytes that actually
# execute: EVERY platform codegraph publishes (darwin/linux/win32 × arm64/x64). A platform
# left without a recorded hash fails closed (unverified=1 → exit 2) rather than passing
# silently, so the pin stays the codegraph trust control on all platforms — not just the
# two CI/dev runners. The version is read from .mcp.json's codegraph pin so it can't drift;
# the whole block is skipped cleanly when codegraph isn't bundled.
CG_SPEC="$(jq -r '.mcpServers.codegraph.args[]? | select(type == "string" and test("^(@[A-Za-z0-9._-]+/)?[A-Za-z0-9._-]+@[0-9]"))' "$MCP_JSON" 2> /dev/null | head -1)"
if [ -n "$CG_SPEC" ]; then
  CG_VER="${CG_SPEC##*@}"
  cg_platform_integrity() {
    case "$1" in
      @colbymchenry/codegraph-darwin-arm64)
        echo "sha512-ggF9MicmVzpqaYvwnguUX1VzQ896j83rPKFfHhwL+QvRmTXWZbhoHtcJ7mYDNPRRIdkXCeTReyYLlfH0k358CQ=="
        ;;
      @colbymchenry/codegraph-darwin-x64)
        echo "sha512-rzdbD/8Cokxsxrkqec6QVFlVNcsF104asWW3ggY6xi+1YvEVXKc0V6qDwV6pNaRgqmkUD1zUTJKo4kzVkD4iGw=="
        ;;
      @colbymchenry/codegraph-linux-arm64)
        echo "sha512-FXGkiXKlRoDglMbUVLnsJkPYCg3mnkVt7l7Pib0Csx3th/qW0FqTXwDcQdt1DfnbdNizCmYD3tfHUvGzjjjVsA=="
        ;;
      @colbymchenry/codegraph-linux-x64)
        echo "sha512-PDJW9YStRIJYnTsI7ZqmYSbEulPq7HYFi6fAEIG499Gk3YQt/P/YQrZlJatyoBvWIlVgxAde50KbpUKWX1c34w=="
        ;;
      @colbymchenry/codegraph-win32-arm64)
        echo "sha512-89y+AowpS6NCZ3mUl58W3w6q/e3F5DNPkxbA4rdnB4zIYmC1C4GnATCwe5UIG36ca3JHBBZTjkKhu59HaFfDyg=="
        ;;
      @colbymchenry/codegraph-win32-x64)
        echo "sha512-lmXmKKf9GXp7e+xEj6UtePL9xHlN9lAz9z4LDGguGj9kWm/+Z32ObYPSpiBz2/05fyG5URyLnf+7ss6umMQH6Q=="
        ;;
      *)
        echo ""
        ;;
    esac
  }
  for plat in \
    @colbymchenry/codegraph-darwin-arm64 \
    @colbymchenry/codegraph-darwin-x64 \
    @colbymchenry/codegraph-linux-arm64 \
    @colbymchenry/codegraph-linux-x64 \
    @colbymchenry/codegraph-win32-arm64 \
    @colbymchenry/codegraph-win32-x64; do
    PSPEC="$plat@$CG_VER"
    PEXP="$(cg_platform_integrity "$plat")"
    if [ -z "$PEXP" ]; then
      echo "check-mcp-pin: $PSPEC has no vetted integrity recorded — refusing to trust. Add it to cg_platform_integrity()." >&2
      unverified=1
      continue
    fi
    PACT="$(npm view "$PSPEC" dist.integrity 2> /dev/null || true)"
    if [ -z "$PACT" ]; then
      echo "check-mcp-pin: could not fetch dist.integrity for $PSPEC (network/npm unavailable)" >&2
      unverified=1
      continue
    fi
    if [ "$PACT" != "$PEXP" ]; then
      echo "check-mcp-pin: INTEGRITY MISMATCH for $PSPEC" >&2
      echo "  expected: $PEXP" >&2
      echo "  actual:   $PACT" >&2
      echo "A codegraph platform tarball was republished with different bytes. Do NOT bump the pin until investigated." >&2
      exit 1
    fi
    echo "check-mcp-pin: OK — $PSPEC integrity matches"
  done
fi

if [ "$unverified" -ne 0 ]; then
  echo "check-mcp-pin: one or more servers could not be verified (see above)" >&2
  exit 2
fi

exit 0
