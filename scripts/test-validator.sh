#!/usr/bin/env bash
# test-validator.sh
# Inputs: none (uses tests/validator-fixtures/ + a temp dir)
# Exit codes: 0 = all fixtures behave as expected; 1 = any fixture fails
# Side effects: creates/cleans a temp dir; runs hooks/validate-skill-frontmatter.sh per fixture
#
# Per-fixture assertion: validate-skill-frontmatter.sh exits 0 (always — fail-open by spec)
# AND writes the expected log line to .claude/logs/validator-errors.log when malformed.
#
# Fix (B5): Construct proper Claude Code JSON envelope on stdin; place fixtures
# under CLAUDE_PROJECT_DIR so the scope guard in the hook accepts them.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

HOOK="hooks/validate-skill-frontmatter.sh"
FIXTURES_DIR="tests/validator-fixtures"

if [[ ! -x "$HOOK" ]]; then
  echo "SKIP: $HOOK not executable (chmod +x first)" >&2
  exit 0
fi
if [[ ! -d "$FIXTURES_DIR" ]]; then
  echo "FAIL: $FIXTURES_DIR missing" >&2
  exit 1
fi

PASS=0
FAIL=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# CLAUDE_PROJECT_DIR must end in /k0d3 for the hook's scope guard to fire.
# Place fixtures under it so the file_path also passes the /skills/ check.
export CLAUDE_PROJECT_DIR="$TMP/k0d3"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/logs"
LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/logs/validator-errors.log"

for fixture in "$FIXTURES_DIR"/*.md; do
  name="$(basename "$fixture" .md)"
  target_dir="$CLAUDE_PROJECT_DIR/skills/$name"
  mkdir -p "$target_dir"
  target="$target_dir/SKILL.md"
  cp "$fixture" "$target"

  content="$(cat "$target")"
  input_json="$(jq -n --arg fp "$target" --arg c "$content" \
    '{tool_name:"Write", tool_input:{file_path:$fp, content:$c}}')"

  : > "$LOG_FILE"
  : > "$TMP/stderr"
  rc=0
  printf '%s' "$input_json" | bash "$REPO_ROOT/$HOOK" > /dev/null 2> "$TMP/stderr" || rc=$?

  # Spec: exit code MUST be 0 (fail-open)
  if ((rc != 0)); then
    echo "FAIL $name: hook exited $rc (should always exit 0 per spec)" >&2
    FAIL=$((FAIL + 1))
    continue
  fi

  case "$name" in
    valid-*)
      # Valid fixture: NO error line should be logged or echoed
      if [[ -s "$LOG_FILE" ]] || grep -qiE 'missing|forbidden|cap|>[[:space:]]*[0-9]' "$TMP/stderr" 2> /dev/null; then
        echo "FAIL $name: valid fixture produced error output" >&2
        echo "  stderr: $(cat "$TMP/stderr")" >&2
        echo "  log:    $(cat "$LOG_FILE" 2> /dev/null || true)" >&2
        FAIL=$((FAIL + 1))
      else
        PASS=$((PASS + 1))
      fi
      ;;
    *)
      # Malformed fixture: stderr should have an error message AND log file should gain a line
      if grep -q -F "$name" "$LOG_FILE" 2> /dev/null; then
        PASS=$((PASS + 1))
      else
        echo "FAIL $name: malformed fixture produced no log line in $LOG_FILE" >&2
        echo "  stderr: $(cat "$TMP/stderr")" >&2
        FAIL=$((FAIL + 1))
      fi
      ;;
  esac
done

# Cross-check: the write-time hard cap must match scripts/_validate_skills.py
# DESC_FAIL so the two validators never silently diverge (conventions.md treats a
# divergence between doc/validators as a bug). Catches a bump to one but not the other.
LINT_CAP="$(grep -oE 'DESC_FAIL = [0-9]+' "$REPO_ROOT/scripts/_validate_skills.py" | grep -oE '[0-9]+')"
if [[ -n "$LINT_CAP" ]] && grep -qF "> $LINT_CAP cap" "$REPO_ROOT/$HOOK"; then
  PASS=$((PASS + 1))
else
  echo "FAIL threshold-sync: hook hard cap does not match _validate_skills.py DESC_FAIL=$LINT_CAP" >&2
  FAIL=$((FAIL + 1))
fi

echo "test-validator.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
