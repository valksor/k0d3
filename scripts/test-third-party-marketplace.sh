#!/usr/bin/env bash
# test-third-party-marketplace.sh — locks optional upstream plugin boundaries.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGIN_MANIFEST="$REPO_ROOT/.claude-plugin/plugin.json"
PASS=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  echo "PASS $1"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "FAIL $1" >&2
}

if ! command -v jq > /dev/null 2>&1; then
  echo "FAIL jq is required" >&2
  exit 1
fi

if jq -e '
  [.plugins[] | select(.name == "watermarks-remover")] | length == 1
' "$MARKETPLACE" > /dev/null; then
  pass "one Watermarks Remover marketplace entry"
else
  fail "expected one Watermarks Remover marketplace entry"
fi

if jq -e '
  .plugins[]
  | select(.name == "watermarks-remover")
  | .source == {
      "source": "github",
      "repo": "guillaumemeyer/watermarks-remover"
    }
' "$MARKETPLACE" > /dev/null; then
  pass "Watermarks Remover resolves directly from upstream GitHub"
else
  fail "Watermarks Remover must resolve directly from upstream GitHub"
fi

if jq -e 'has("dependencies") | not' "$PLUGIN_MANIFEST" > /dev/null; then
  pass "k0d3 declares no transitive plugin dependency"
else
  fail "k0d3 must not auto-install Watermarks Remover"
fi

if [[ ! -e "$REPO_ROOT/skills/remove-ai-marks" && ! -e "$REPO_ROOT/skills/clean-user-facing-text" ]]; then
  pass "Watermarks Remover skills are not vendored"
else
  fail "Watermarks Remover skills must remain upstream-owned"
fi

if grep -qF '/plugin install watermarks-remover@valksor-k0d3' "$REPO_ROOT/README.md"; then
  pass "README documents the explicit install command"
else
  fail "README must document the explicit Watermarks Remover install command"
fi

if grep -qF '/plugin update watermarks-remover@valksor-k0d3' "$REPO_ROOT/README.md" &&
  grep -qF 'claude --plugin-dir /path/to/watermarks-remover' "$REPO_ROOT/README.md"; then
  pass "README documents cache-aware refresh paths"
else
  fail "README must document normal updates and the cache-bypass development path"
fi

echo "test-third-party-marketplace.sh: $PASS pass, $FAIL fail" >&2
((FAIL == 0))
