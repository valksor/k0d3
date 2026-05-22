#!/usr/bin/env bash
# test-memory-gitignore.sh — verifies hooks/ensure-memory-gitignore.sh:
#   1. creates .claude/ and ignores memory.jsonl in a fresh git repo
#   2. is idempotent (no duplicate rule on re-run)
#   3. does not clobber an existing .claude/.gitignore's content
#   4. skips writing when a parent .gitignore already ignores .claude/
#   5. fail-open: no CLAUDE_PROJECT_DIR -> exit 0
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO_ROOT/hooks/ensure-memory-gitignore.sh"
PASS=0
FAIL=0

if [ ! -x "$HOOK" ]; then
  echo "SKIP: $HOOK not executable (chmod +x first)" >&2
  exit 0
fi

ok() { PASS=$((PASS + 1)); }
no() {
  echo "FAIL $1" >&2
  FAIL=$((FAIL + 1))
}
run() { CLAUDE_PROJECT_DIR="$1" bash "$HOOK" < /dev/null > /dev/null 2>&1; }

# 1. fresh git repo
T1="$(mktemp -d)"
git -C "$T1" init -q
run "$T1"
if [ -d "$T1/.claude" ]; then ok; else no "1a: .claude/ not created"; fi
if git -C "$T1" check-ignore -q .claude/memory.jsonl; then ok; else no "1b: memory.jsonl not ignored"; fi

# 2. idempotent
run "$T1"
COUNT="$(grep -c '^memory\.jsonl$' "$T1/.claude/.gitignore" 2> /dev/null || true)"
if [ "$COUNT" = "1" ]; then ok; else no "2: rule count is '$COUNT' (expected 1) on re-run"; fi

# 3. doesn't clobber existing content
T3="$(mktemp -d)"
git -C "$T3" init -q
mkdir -p "$T3/.claude"
printf 'logs/\n' > "$T3/.claude/.gitignore"
run "$T3"
if grep -q '^logs/$' "$T3/.claude/.gitignore"; then ok; else no "3a: clobbered existing content"; fi
if grep -q '^memory\.jsonl$' "$T3/.claude/.gitignore"; then ok; else no "3b: rule not appended"; fi

# 4. parent already ignores .claude/ -> no redundant .claude/.gitignore
T4="$(mktemp -d)"
git -C "$T4" init -q
printf '.claude/\n' > "$T4/.gitignore"
run "$T4"
if [ ! -f "$T4/.claude/.gitignore" ]; then ok; else no "4: wrote redundant .claude/.gitignore"; fi

# 5. fail-open with no CLAUDE_PROJECT_DIR
if (
  unset CLAUDE_PROJECT_DIR
  bash "$HOOK" < /dev/null > /dev/null 2>&1
); then ok; else no "5: nonzero exit with no CLAUDE_PROJECT_DIR"; fi

echo "test-memory-gitignore.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
