#!/usr/bin/env bash
# test-allow-codegraph.sh
# Inputs: none (inline fixtures)
# Exit codes: 0 = all fixtures behave as expected; 1 = any fail
# Side effects: none; invokes hooks/allow-codegraph.sh with mock CC input
#
# Verifies the PreToolUse(mcp__codegraph__*) auto-approve protocol:
#   - any mcp__codegraph__* tool      -> JSON with permissionDecision "allow", exit 0
#   - a non-codegraph mcp__* tool     -> no JSON (silent — defer to normal prompt), exit 0
#   - a native tool (Read/Bash)       -> no JSON (silent), exit 0
#   - missing tool_name               -> no JSON (silent), exit 0
#
# Assertions inspect stdout (the hook prints JSON only when it auto-allows); empty = silent.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO_ROOT/hooks/allow-codegraph.sh"

if [[ ! -x "$HOOK" ]]; then
  echo "SKIP: $HOOK not executable (chmod +x first)" >&2
  exit 0
fi

PASS=0
FAIL=0

run_hook() { printf '%s' "$1" | bash "$HOOK" 2> /dev/null; }

assert() {
  local label="$1" input="$2" expect="$3" # expect: allow | silent
  local out decision
  out="$(run_hook "$input")"
  if [[ -z "$out" ]]; then
    decision="silent"
  else
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "allow"' > /dev/null 2>&1; then
      decision="allow"
    else
      decision="malformed"
    fi
  fi
  if [[ "$decision" == "$expect" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL $label: expected $expect, got '$decision'; out=$out" >&2
    FAIL=$((FAIL + 1))
  fi
}

assert "codegraph-explore" '{"tool_name":"mcp__codegraph__codegraph_explore","tool_input":{}}' "allow"
assert "codegraph-files" '{"tool_name":"mcp__codegraph__codegraph_files","tool_input":{}}' "allow"
# INTENTIONAL: a not-yet-existing codegraph tool is auto-allowed too. This is the
# wildcard's whole point (new tools must not reintroduce the prompt), and its
# trust boundary — see the "Trust boundary" note in hooks/allow-codegraph.sh.
assert "codegraph-future" '{"tool_name":"mcp__codegraph__codegraph_brand_new_tool","tool_input":{}}' "allow"
assert "other-mcp-server" '{"tool_name":"mcp__memory__create_entities","tool_input":{}}' "silent"
assert "native-read" '{"tool_name":"Read","tool_input":{}}' "silent"
assert "missing-name" '{"tool_input":{}}' "silent"
# Boundary cases: the guard must NOT match a different server whose name merely
# starts with "codegraph", nor a bare prefix with no tool suffix, and must stay
# silent on null/malformed/empty input rather than erroring or over-allowing.
assert "neighbor-server" '{"tool_name":"mcp__codegraphX__foo","tool_input":{}}' "silent"
assert "bare-prefix" '{"tool_name":"mcp__codegraph","tool_input":{}}' "silent"
assert "null-name" '{"tool_name":null,"tool_input":{}}' "silent"
assert "malformed-json" '{"tool_name":' "silent"
assert "empty-stdin" '' "silent"

echo "test-allow-codegraph.sh: $PASS pass, $FAIL fail" >&2

# Wiring assertion: the script is useless unless hooks.json actually routes
# mcp__codegraph__* calls to it. Catch an accidental matcher deletion (which the
# per-call asserts above cannot see) so it fails CI instead of silently
# re-enabling permission prompts for every user.
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"
if ! jq -e '
  [.. | objects | select(.matcher == "mcp__codegraph__.*")
    | .hooks[]?.command // ""] | any(test("allow-codegraph\\.sh"))
' "$HOOKS_JSON" > /dev/null 2>&1; then
  echo "FAIL wiring: hooks.json has no mcp__codegraph__.* matcher routing to allow-codegraph.sh" >&2
  FAIL=$((FAIL + 1))
fi

exit $((FAIL > 0 ? 1 : 0))
