#!/usr/bin/env bash
# test-hooks.sh
# Inputs: none (uses inline fixtures below)
# Exit codes: 0 = all fixtures behave as expected; 1 = any fail
# Side effects: invokes hooks/guard-bash.sh with mock CC inputs
#
# Verifies the guard-bash.sh deny/allow protocol:
#   - HARD/SOFT blocks emit JSON with `permissionDecision: "deny"` on stdout, exit 0
#   - WARN-tier and allow-tier emit no JSON, exit 0; WARN also appends to incident-log.md
#
# Assertions inspect the stdout JSON for permissionDecision (NOT the exit code,
# because Claude Code's hook contract uses exit 0 for both allow and deny).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

GUARD_BASH="hooks/guard-bash.sh"

if [[ ! -x "$GUARD_BASH" ]]; then
  echo "SKIP: $GUARD_BASH not executable (chmod +x first)" >&2
  exit 0
fi

PASS=0
FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export CLAUDE_PROJECT_DIR="$TMP/project"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs"

run_case() {
  local label="$1" cmd="$2" expect="$3"
  local out decision
  out="$(printf '%s' "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":$(printf '%s' "$cmd" | jq -Rs .)}}" |
    bash "$REPO_ROOT/$GUARD_BASH" 2> /dev/null)"
  # Hook prints JSON only on deny. Empty stdout = allow. Parse only if non-empty.
  if [[ -z "$out" ]]; then
    decision="allow"
  else
    decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "allow"' 2> /dev/null)"
    [[ -z "$decision" ]] && decision="allow"
  fi

  case "$expect" in
    block)
      if [[ "$decision" == "deny" ]]; then
        PASS=$((PASS + 1))
      else
        echo "FAIL $label: expected deny, got '$decision'; out=$out" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
    allow)
      if [[ "$decision" == "allow" ]]; then
        PASS=$((PASS + 1))
      else
        echo "FAIL $label: expected allow, got '$decision'; out=$out" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
    warn)
      # warn = no deny JSON (decision=allow), AND incident log gained an entry
      if [[ "$decision" != "allow" ]]; then
        echo "FAIL $label: expected allow+log, got '$decision'; out=$out" >&2
        FAIL=$((FAIL + 1))
        return
      fi
      if grep -q -F -- "$cmd" "$CLAUDE_PROJECT_DIR/.claude/logs/incident-log.md" 2> /dev/null; then
        PASS=$((PASS + 1))
      else
        echo "FAIL $label: expected warning in incident-log.md; not found" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
  esac
}

# Reset incident log between runs so warn-grep is unambiguous
: > "$CLAUDE_PROJECT_DIR/.claude/logs/incident-log.md"

# ── Hard-block fixtures (catastrophic-rm B1 coverage) ──
run_case "rm-rf-root-trailing-flags" "rm -rf / --no-preserve-root" "block"
run_case "rm-r-root-no-force" "rm -r /" "block"
run_case "rm-rf-etc" "rm -rf /etc/something" "block"
run_case "rm-flag-after-path" "rm / -rf" "block"
run_case "rm-long-form-recursive" "rm --recursive /etc" "block"

# ── Shell-indirection bypass (B2) ──
run_case "eval-bypass" "eval 'rm -rf /'" "block"
run_case "bash-c-bypass" "bash -c 'rm -rf /'" "block"

# ── Force push (also covers --force-with-lease via prefix) ──
run_case "force-push" "git push --force" "block"
run_case "force-with-lease" "git push --force-with-lease" "block"

# ── Secret-file read (B3) ──
run_case "cat-env" "cat .env" "block"
run_case "grep-env-no-c" "grep STRIPE .env" "block"
run_case "awk-env" "awk '1' .env" "block"
run_case "grep-c-env-allowed" "grep -c STRIPE .env" "allow"
run_case "printenv-var" "printenv STRIPE_SECRET_KEY" "block"

# ── env-table enumeration is NOT blocked (regression: the bare-word `env`/`export`
# matcher false-positived on benign --env flags, `npm run env`, even rg patterns) ──
run_case "env-grep-allowed" "env | grep STRIPE" "allow"
run_case "docker-env-flag-allowed" "docker run --env FOO=bar img | grep ready" "allow"
run_case "npm-run-env-grep-allowed" "npm run env | grep PORT" "allow"
run_case "rg-env-pattern-allowed" "rg -n 'env|export' docs/hooks.md | head" "allow"

# ── Catastrophic-rm is clause-aware: a system path in a SIBLING clause (not the
#    rm target) must not hard-block; a system path in the rm clause still does ──
run_case "rm-sibling-syspath-allowed" "cd /Users/me/proj && rm -f localfile" "allow"
run_case "ls-syspath-then-rm-allowed" "ls /etc && rm note.txt" "allow"
run_case "rm-syspath-in-rm-clause-blocked" "cd /tmp && rm -rf /etc/x" "block"

# ── .env templates carry no secrets: read/copy/stage allowed; real .env blocked ──
run_case "cp-env-template-allowed" "cp .env.example .env" "allow"
run_case "cat-env-template-allowed" "cat .env.example" "allow"
run_case "mv-env-local-allowed" "mv .env.local .env" "allow"
run_case "gitadd-env-template-allowed" "git add .env.example" "allow"
run_case "gitadd-env-real-blocked" "git add .env" "block"

# ── Force-only rm (no -r) is warn-tier (allowed); recursive still soft-blocks ──
run_case "rm-force-named-allowed" "rm -f /tmp/throwaway.txt" "allow"
run_case "rm-recursive-dir-blocked" "rm -rf node_modules" "block"

# ── printenv safelists benign vars; secret-named vars still blocked ──
run_case "printenv-path-allowed" "printenv PATH" "allow"
run_case "printenv-home-allowed" "printenv HOME" "allow"

# ── echo of benign env vars allowed; real secret vars still blocked ──
run_case "echo-aws-region-allowed" "echo \$AWS_REGION" "allow"
run_case "echo-db-name-allowed" "echo \$DATABASE_NAME" "allow"
run_case "echo-token-count-allowed" "echo \$TOKEN_COUNT" "allow"
run_case "echo-stripe-secret-blocked" "echo \$STRIPE_SECRET_KEY" "block"
run_case "echo-gh-token-blocked" "echo \$GH_TOKEN" "block"

# ── Compound-AND allowlist bypass (C7) ──
# First case is caught by the HARD-block (/home/user is a system path),
# second case exercises the clause-aware SOFT-block: allowlisted + non-allowlisted
# clauses both present; non-allowlisted clause forces deny.
run_case "compound-rm-bypass-hardpath" "rm -rf .claude/backups/old && rm -rf /home/user" "block"
run_case "compound-rm-bypass-clauselogic" "rm -rf .claude/backups/old && rm -rf ./project-data" "block"

# ── Quoted-path token-scan bypass (Pass 2 Security B1) ──
run_case "rm-quoted-system-path" "rm -rf \"/etc\"" "block"
run_case "cat-quoted-env" "cat \".env\"" "block"

# ── macOS home path (Pass 2 Sr Dev B1) ──
run_case "rm-users-home" "rm -rf /Users/someone" "block"

# ── Allow-tier ──
run_case "ls-cwd" "ls -la" "allow"
run_case "rm-allowlisted-backups" "rm -rf .claude/backups/2024-01-01" "allow"
run_case "rm-single-file" "rm ./single-file.txt" "allow"

# ── Warn-tier (logs to incident-log.md, no JSON deny) ──
: > "$CLAUDE_PROJECT_DIR/.claude/logs/incident-log.md"
run_case "warn-redirect-outside" "echo hi > /tmp/somefile.txt" "warn"

# ── verify-before-stop gate ──────────────────────────────────────────────────
# Stop-hook block protocol: prints {"decision":"block",...} on a detected failure
# in this turn's tool output, nothing otherwise. Single-fire via stop_hook_active.
# Fail-soft on missing inputs. Requires python3; skipped if absent.
VERIFY_STOP="hooks/verify-before-stop.sh"
FIXTURES="$REPO_ROOT/tests/stop-hook-fixtures"

run_stop_case() {
  local label="$1" active="$2" transcript="$3" expect="$4"
  local out decision
  out="$(printf '{"stop_hook_active":%s,"transcript_path":%s}' \
    "$active" "$(printf '%s' "$transcript" | jq -Rs .)" |
    bash "$REPO_ROOT/$VERIFY_STOP" 2> /dev/null)"
  if [[ -z "$out" ]]; then
    decision="allow"
  else
    decision="$(printf '%s' "$out" | jq -r '.decision // "allow"' 2> /dev/null)"
    [[ -z "$decision" ]] && decision="allow"
  fi
  if [[ "$decision" == "$expect" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL $label: expected $expect, got '$decision'; out=$out" >&2
    FAIL=$((FAIL + 1))
  fi
}

if command -v python3 > /dev/null 2>&1; then
  # Each signature category blocks on a real failure...
  run_stop_case "stop-build-blocks" "false" "$FIXTURES/failing.jsonl" "block"
  run_stop_case "stop-auth-blocks" "false" "$FIXTURES/auth.jsonl" "block"
  run_stop_case "stop-cmd-not-found-blocks" "false" "$FIXTURES/cmd-not-found.jsonl" "block"
  run_stop_case "stop-test-failure-blocks" "false" "$FIXTURES/test-fail.jsonl" "block"
  run_stop_case "stop-permission-blocks" "false" "$FIXTURES/permission.jsonl" "block"
  # ...and allows on clean output, on source merely READ (tightened patterns must
  # not fire on except-clauses / panic() / prose), on single-fire, and fail-soft.
  run_stop_case "stop-clean-allows" "false" "$FIXTURES/clean.jsonl" "allow"
  run_stop_case "stop-reading-source-allows" "false" "$FIXTURES/reading-source.jsonl" "allow"
  run_stop_case "stop-single-fire-allows" "true" "$FIXTURES/failing.jsonl" "allow"
  run_stop_case "stop-missing-transcript" "false" "$FIXTURES/does-not-exist.jsonl" "allow"
else
  echo "SKIP verify-before-stop: python3 not available" >&2
fi

# ── review-plan-before-exit gate ─────────────────────────────────────────────
# PreToolUse(ExitPlanMode) block protocol: prints JSON with
# `permissionDecision: "deny"` on the FIRST ExitPlanMode (arming a single-fire
# gate file), nothing on the re-presentation (gate consumed), nothing for other
# tools, and nothing under K0D3_SKIP_PLAN_REVIEW=1. Fail-soft on missing inputs.
REVIEW_PLAN="hooks/review-plan-before-exit.sh"
PLAN_GATE="$CLAUDE_PROJECT_DIR/.claude/logs/.plan-review-gate"

run_plan_case() {
  local label="$1" tool="$2" expect="$3" skip="${4:-}"
  local out decision
  out="$(printf '{"tool_name":"%s","tool_input":{"plan":"x"}}' "$tool" |
    env ${skip:+K0D3_SKIP_PLAN_REVIEW=1} bash "$REPO_ROOT/$REVIEW_PLAN" 2> /dev/null)"
  if [[ -z "$out" ]]; then
    decision="allow"
  else
    decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "allow"' 2> /dev/null)"
    [[ -z "$decision" ]] && decision="allow"
  fi
  if [[ "$decision" == "$expect" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL $label: expected $expect, got '$decision'; out=$out" >&2
    FAIL=$((FAIL + 1))
  fi
}

rm -f "$PLAN_GATE"
run_plan_case "plan-first-exit-denies" "ExitPlanMode" "deny" # arms the gate
if [[ -f "$PLAN_GATE" ]]; then PASS=$((PASS + 1)); else
  echo "FAIL plan-gate-armed: gate not created after deny" >&2
  FAIL=$((FAIL + 1))
fi
run_plan_case "plan-second-exit-allows" "ExitPlanMode" "allow" # consumes the gate
if [[ ! -f "$PLAN_GATE" ]]; then PASS=$((PASS + 1)); else
  echo "FAIL plan-gate-consumed: gate not removed after allow" >&2
  FAIL=$((FAIL + 1))
fi
run_plan_case "plan-non-exitplanmode-allows" "Bash" "allow"
rm -f "$PLAN_GATE"
run_plan_case "plan-skip-env-allows" "ExitPlanMode" "allow" "skip"
rm -f "$PLAN_GATE"

# Re-arm: after a deny→allow cycle consumes the gate, a fresh ExitPlanMode must
# deny again (the loop-safety property — back-to-back plans can't bypass review).
run_plan_case "plan-rearm-1-denies" "ExitPlanMode" "deny"
run_plan_case "plan-rearm-2-consumes" "ExitPlanMode" "allow"
run_plan_case "plan-rearm-3-denies-again" "ExitPlanMode" "deny"
rm -f "$PLAN_GATE"

# The deny output must carry the /k0d3:review-plan routing instruction (a regression
# that emptied/misdirected the reason would otherwise pass the decision-only checks).
deny_out="$(printf '{"tool_name":"ExitPlanMode","tool_input":{"plan":"x"}}' |
  bash "$REPO_ROOT/$REVIEW_PLAN" 2> /dev/null)"
if printf '%s' "$deny_out" | jq -e -r '.hookSpecificOutput.permissionDecisionReason' 2> /dev/null |
  grep -q "/k0d3:review-plan"; then
  PASS=$((PASS + 1))
else
  echo "FAIL plan-deny-reason-routes: reason lacks /k0d3:review-plan; out=$deny_out" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$PLAN_GATE"

# Session-scoped gate: a session_id yields a per-session gate file, never the shared
# fallback — so two concurrent plan-mode sessions can't consume each other's gate.
SID_GATE="$CLAUDE_PROJECT_DIR/.claude/logs/.plan-review-gate-sess-abc"
rm -f "$SID_GATE" "$PLAN_GATE"
printf '{"tool_name":"ExitPlanMode","tool_input":{"plan":"x"},"session_id":"sess-abc"}' |
  bash "$REPO_ROOT/$REVIEW_PLAN" > /dev/null 2>&1
if [[ -f "$SID_GATE" && ! -f "$PLAN_GATE" ]]; then
  PASS=$((PASS + 1))
else
  echo "FAIL plan-session-scoped-gate: expected $SID_GATE armed, shared gate absent" >&2
  FAIL=$((FAIL + 1))
fi
rm -f "$SID_GATE"

echo "test-hooks.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
