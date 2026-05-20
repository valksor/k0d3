#!/usr/bin/env bash
# Block `gh issue create` when the current shell is on a work/* branch.
# Rationale: filing an issue during implementation is deferral-as-dodge —
# it disposes of work without doing it, inflating the backlog instead of
# advancing release. From master (planning, hub triage, user-directed),
# filing is the right action.
#
# Uses Claude Code's structured-JSON deny protocol (exit 0 + JSON stdout) so
# the message renders consistently with other deny hooks in this plugin.

set -uo pipefail

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0

input="$(cat)"

command="$(printf '%s' "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2> /dev/null || echo '')"

# Only act on `gh issue create` (allow list/view/edit/close/comment).
if ! printf '%s' "$command" | grep -Eq '\bgh[[:space:]]+issue[[:space:]]+create\b'; then
  exit 0
fi

cwd="$(printf '%s' "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('cwd',''))" 2> /dev/null || echo '')"
[ -z "$cwd" ] && cwd="$(pwd)"

branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2> /dev/null || echo '')"

case "$branch" in
  work/*)
    jq -n --arg branch "$branch" \
      '{
            hookSpecificOutput: {
              hookEventName: "PreToolUse",
              permissionDecision: "deny",
              permissionDecisionReason: ("BLOCKED: gh issue create disabled on " + $branch + " (defer-as-dodge prevention)."),
              additionalContext: "You are implementing on a work/* branch. Out-of-scope findings should be: (a) fixed in this PR if small, (b) dropped if not load-bearing, or (c) listed in the PR body under \"## Out of scope (no issue filed)\" for the user to triage and file from master. If this is hub triage, switch to master first: git checkout master"
            }
          }'
    exit 0
    ;;
esac

exit 0
