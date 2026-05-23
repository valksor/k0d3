#!/usr/bin/env bash
# test-mcp-spec-extraction.sh
# Inputs: none (reads the repo's real .mcp.json + greps the consumer scripts)
# Exit codes: 0 = all checks pass; 1 = any fail
# Side effects: none
#
# Guards the SINGLE package-spec selector that every supply-chain consumer relies on.
# check-mcp-pin.sh, the smoke-mcp-*.sh scripts, and codegraph-autoindex.sh all extract
# the pinned `[@scope/]name@<version>` arg from .mcp.json with the SAME jq selector. If
# any consumer drifts (or the selector starts mis-selecting a trailing subcommand arg
# such as codegraph's `serve` / `--mcp`), verification and execution can diverge — the
# pin would vet one package while npx runs another. This test asserts:
#   1. the selector resolves each stdio server in .mcp.json to its real pkg@version, and
#   2. for codegraph it skips the trailing `serve`/`--mcp` args, and
#   3. every consumer script embeds the identical selector core (no divergence).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_JSON="$REPO_ROOT/.mcp.json"

# The canonical selector core. Keep in lockstep with the consumers below; this test
# fails if they drift from it.
SELECTOR='select(type == "string" and test("^(@[A-Za-z0-9._-]+/)?[A-Za-z0-9._-]+@[0-9]"))'

PASS=0
FAIL=0

if ! command -v jq > /dev/null 2>&1; then
  echo "SKIP test-mcp-spec-extraction: jq not found" >&2
  exit 0
fi

# extract <server-key> — run the selector exactly as the consumers do.
extract() {
  jq -r --arg k "$1" ".mcpServers[\$k].args[]? | $SELECTOR" "$MCP_JSON" | head -1
}

assert_spec() {
  local key="$1" want_substr="$2"
  local got
  got="$(extract "$key")"
  if [ -z "$got" ]; then
    echo "FAIL spec[$key]: selector returned nothing" >&2
    FAIL=$((FAIL + 1))
    return
  fi
  case "$got" in
    *"$want_substr"*@[0-9]*)
      PASS=$((PASS + 1))
      ;;
    *)
      echo "FAIL spec[$key]: expected a '$want_substr@<version>' spec, got '$got'" >&2
      FAIL=$((FAIL + 1))
      ;;
  esac
}

# 1 + 2 — behavioural: every stdio server resolves to its real spec; codegraph in
# particular must NOT resolve to its trailing `serve`/`--mcp` args.
assert_spec memory "@modelcontextprotocol/server-memory"
assert_spec sequential-thinking "@modelcontextprotocol/server-sequential-thinking"
cg="$(extract codegraph)"
case "$cg" in
  @colbymchenry/codegraph@[0-9]*)
    PASS=$((PASS + 1))
    ;;
  serve | --mcp | "")
    echo "FAIL spec[codegraph]: selected a non-package arg ('$cg') — trailing-arg drift" >&2
    FAIL=$((FAIL + 1))
    ;;
  *)
    echo "FAIL spec[codegraph]: expected '@colbymchenry/codegraph@<version>', got '$cg'" >&2
    FAIL=$((FAIL + 1))
    ;;
esac

# 3 — consistency: every consumer embeds the identical selector core.
for f in \
  scripts/check-mcp-pin.sh \
  scripts/smoke-mcp-memory.sh \
  scripts/smoke-mcp-sequentialthinking.sh \
  scripts/smoke-mcp-codegraph.sh \
  hooks/codegraph-autoindex.sh; do
  if grep -qF -- "$SELECTOR" "$REPO_ROOT/$f"; then
    PASS=$((PASS + 1))
  else
    echo "FAIL consumer[$f]: does not embed the canonical spec selector — divergence risk" >&2
    FAIL=$((FAIL + 1))
  fi
done

echo "test-mcp-spec-extraction.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
