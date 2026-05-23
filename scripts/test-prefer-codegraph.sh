#!/usr/bin/env bash
# test-prefer-codegraph.sh
# Inputs: none (inline fixtures + a temp project tree)
# Exit codes: 0 = all fixtures behave as expected; 1 = any fail
# Side effects: none outside a temp dir; invokes hooks/prefer-codegraph.sh with mock CC input
#
# Verifies the PreToolUse(Grep) nudge protocol:
#   - bare identifier + a codegraph index present  -> advisory JSON (permissionDecision "allow"
#     + additionalContext naming codegraph_search), exit 0
#   - regex/phrase pattern                         -> no JSON (silent), exit 0
#   - bare identifier + NO index                   -> no JSON (silent), exit 0
#   - non-Grep tool                                -> no JSON (silent), exit 0
#
# Assertions inspect stdout (the hook prints JSON only when it nudges); empty = silent.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO_ROOT/hooks/prefer-codegraph.sh"

if [[ ! -x "$HOOK" ]]; then
  echo "SKIP: $HOOK not executable (chmod +x first)" >&2
  exit 0
fi

PASS=0
FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A project that HAS a codegraph index, and one that does not.
mkdir -p "$TMP/indexed/.codegraph"
: > "$TMP/indexed/.codegraph/codegraph.db"
mkdir -p "$TMP/bare"

# Run the hook with CLAUDE_PROJECT_DIR unset so only the JSON `cwd` decides the repo
# (otherwise an ambient CLAUDE_PROJECT_DIR from the caller's session would leak in).
run_hook() { printf '%s' "$1" | env -u CLAUDE_PROJECT_DIR bash "$HOOK" 2> /dev/null; }

assert() {
  local label="$1" input="$2" expect="$3" # expect: nudge | silent
  local out decision
  out="$(run_hook "$input")"
  if [[ -z "$out" ]]; then
    decision="silent"
  else
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext | test("codegraph_search")' > /dev/null 2>&1; then
      decision="nudge"
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

assert "identifier+index" "{\"tool_name\":\"Grep\",\"tool_input\":{\"pattern\":\"handleLogin\"},\"cwd\":\"$TMP/indexed\"}" "nudge"
assert "regex+index" "{\"tool_name\":\"Grep\",\"tool_input\":{\"pattern\":\"TODO.*fixme\"},\"cwd\":\"$TMP/indexed\"}" "silent"
assert "phrase+index" "{\"tool_name\":\"Grep\",\"tool_input\":{\"pattern\":\"two words\"},\"cwd\":\"$TMP/indexed\"}" "silent"
assert "twochar+index" "{\"tool_name\":\"Grep\",\"tool_input\":{\"pattern\":\"id\"},\"cwd\":\"$TMP/indexed\"}" "silent"
assert "identifier+noindex" "{\"tool_name\":\"Grep\",\"tool_input\":{\"pattern\":\"handleLogin\"},\"cwd\":\"$TMP/bare\"}" "silent"
assert "non-grep-tool" "{\"tool_name\":\"Read\",\"tool_input\":{\"pattern\":\"handleLogin\"},\"cwd\":\"$TMP/indexed\"}" "silent"

echo "test-prefer-codegraph.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
