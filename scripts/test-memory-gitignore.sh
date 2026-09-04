#!/usr/bin/env bash
# test-memory-gitignore.sh — verifies hooks/ensure-memory-gitignore.sh:
#   1. creates .codex/ and ignores memory.jsonl for Codex in a fresh git repo
#   2. is idempotent (no duplicate rule on re-run)
#   3. does not clobber an existing .codex/.gitignore's content
#   4. skips writing when a parent .gitignore already ignores .codex/
#   5. fail-open: no CLAUDE_PROJECT_DIR -> exit 0
#   6. retains .claude/ behavior for Claude Code
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
run_codex() { K0D3_HOST=codex CLAUDE_PROJECT_DIR="$1" bash "$HOOK" < /dev/null > /dev/null 2>&1; }
run_claude() { CLAUDE_PROJECT_DIR="$1" bash "$HOOK" < /dev/null > /dev/null 2>&1; }

# 1. fresh git repo
T1="$(mktemp -d)"
git -C "$T1" init -q
run_codex "$T1"
if [ -d "$T1/.codex" ]; then ok; else no "1a: .codex/ not created"; fi
if git -C "$T1" check-ignore -q .codex/memory.jsonl; then ok; else no "1b: memory.jsonl not ignored"; fi
if [ ! -e "$T1/.claude" ]; then ok; else no "1c: Codex run created .claude/"; fi

# 2. idempotent
run_codex "$T1"
COUNT="$(grep -c '^memory\.jsonl$' "$T1/.codex/.gitignore" 2> /dev/null || true)"
if [ "$COUNT" = "1" ]; then ok; else no "2: rule count is '$COUNT' (expected 1) on re-run"; fi

# 3. doesn't clobber existing content
T3="$(mktemp -d)"
git -C "$T3" init -q
mkdir -p "$T3/.codex"
printf 'logs/\n' > "$T3/.codex/.gitignore"
run_codex "$T3"
if grep -q '^logs/$' "$T3/.codex/.gitignore"; then ok; else no "3a: clobbered existing content"; fi
if grep -q '^memory\.jsonl$' "$T3/.codex/.gitignore"; then ok; else no "3b: rule not appended"; fi

# 4. parent already ignores .codex/ -> no redundant .codex/.gitignore
T4="$(mktemp -d)"
git -C "$T4" init -q
printf '.codex/\n' > "$T4/.gitignore"
run_codex "$T4"
if [ ! -f "$T4/.codex/.gitignore" ]; then ok; else no "4: wrote redundant .codex/.gitignore"; fi

# 5. fail-open with no CLAUDE_PROJECT_DIR
if (
  unset CLAUDE_PROJECT_DIR
  bash "$HOOK" < /dev/null > /dev/null 2>&1
); then ok; else no "5: nonzero exit with no CLAUDE_PROJECT_DIR"; fi

# 6. Claude Code retains its .claude/ store protection
T6="$(mktemp -d)"
git -C "$T6" init -q
run_claude "$T6"
if git -C "$T6" check-ignore -q .claude/memory.jsonl; then ok; else no "6a: Claude memory.jsonl not ignored"; fi
if [ ! -e "$T6/.codex" ]; then ok; else no "6b: Claude run created .codex/"; fi

echo "test-memory-gitignore.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
