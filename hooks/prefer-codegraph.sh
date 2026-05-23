#!/usr/bin/env bash
# PreToolUse(Grep) hook — nudge toward codegraph when grepping for a symbol.
#
# When the agent greps for a bare identifier in a repo that HAS a codegraph index,
# codegraph_search / codegraph_context / codegraph_callers answer the same question
# structurally and in sub-ms, with no file scan. This surfaces that at the exact
# decision point — the gap that passive CLAUDE.md / server-instructions don't close
# because grep is always in-hand and codegraph competes from behind.
#
# Strictly advisory: emits permissionDecision "allow" + additionalContext, NEVER
# blocks. Self-gating: silent unless the pattern is a bare identifier AND a real
# index exists — so regex/phrase searches (the legitimate use of Grep) and repos
# without codegraph are left untouched. Output protocol mirrors
# block-deferred-issues.sh (exit 0 + hookSpecificOutput JSON on stdout).

set -uo pipefail

command -v jq > /dev/null 2>&1 || exit 0
command -v python3 > /dev/null 2>&1 || exit 0

input="$(cat)"

name="$(printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_name',''))" 2> /dev/null || echo '')"
[ "$name" = "Grep" ] || exit 0

pat="$(printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('pattern',''))" 2> /dev/null || echo '')"

# Only nudge on a bare identifier (a symbol lookup). A pattern with regex
# metacharacters, spaces, or fewer than 3 chars is left alone — that's grep's job.
printf '%s' "$pat" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]{2,}$' || exit 0

cwd="$(printf '%s' "$input" | python3 -c "import json,sys; print(json.load(sys.stdin).get('cwd',''))" 2> /dev/null || echo '')"
[ -z "$cwd" ] && cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

# The index lives at the project root; cwd may be a subdir, so walk up to find it.
db=""
d="$cwd"
while [ -n "$d" ] && [ "$d" != "/" ]; do
  if [ -f "$d/.codegraph/codegraph.db" ]; then
    db="$d/.codegraph/codegraph.db"
    break
  fi
  d="$(dirname "$d")"
done
if [ -z "$db" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/.codegraph/codegraph.db" ]; then
  db="$CLAUDE_PROJECT_DIR/.codegraph/codegraph.db"
fi
[ -n "$db" ] || exit 0

jq -n --arg p "$pat" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    additionalContext: ("codegraph is indexed for this repo. For the symbol \"" + $p + "\" prefer codegraph_search or codegraph_context (and codegraph_callers for usages) — indexed, structural, sub-millisecond — over a grep file-scan. Keep Grep for free-text/regex, not symbol lookups.")
  }
}'
exit 0
