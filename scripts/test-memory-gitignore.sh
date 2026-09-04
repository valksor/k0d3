#!/usr/bin/env bash
# test-memory-gitignore.sh — verifies hooks/ensure-memory-gitignore.sh:
#   1. creates both host store dirs and ignores memory.jsonl + sidecars
#      in a fresh git repo
#   2. is idempotent (no duplicate rule on re-run)
#   3. does not clobber an existing .claude/.gitignore's content
#   4. skips writing when a parent .gitignore already ignores .claude/
#   5. fail-open: no CLAUDE_PROJECT_DIR -> exit 0
#   6. refuses store-directory and .gitignore symlinks
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
if git -C "$T1" check-ignore -q .claude/memory.jsonl; then ok; else no "1b: Claude memory.jsonl not ignored"; fi
if git -C "$T1" check-ignore -q .claude/memory.jsonl.tmp; then ok; else no "1c: Claude memory sidecars not ignored"; fi
if [ -d "$T1/.codex" ]; then ok; else no "1d: .codex/ not created"; fi
if git -C "$T1" check-ignore -q .codex/memory.jsonl; then ok; else no "1e: Codex memory.jsonl not ignored"; fi
if git -C "$T1" check-ignore -q .codex/memory.jsonl.tmp; then ok; else no "1f: Codex memory sidecars not ignored"; fi

# 2. idempotent
run "$T1"
COUNT="$(grep -c '^memory\.jsonl$' "$T1/.claude/.gitignore" 2> /dev/null || true)"
if [ "$COUNT" = "1" ]; then ok; else no "2: rule count is '$COUNT' (expected 1) on re-run"; fi
CODEX_COUNT="$(grep -c '^memory\.jsonl$' "$T1/.codex/.gitignore" 2> /dev/null || true)"
if [ "$CODEX_COUNT" = "1" ]; then ok; else no "2b: Codex rule count is '$CODEX_COUNT' (expected 1) on re-run"; fi

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

# 6a. repository-controlled store directory symlink must not be followed
T6="$(mktemp -d)"
OUTSIDE6="$(mktemp -d)"
git -C "$T6" init -q
printf 'outside-dir-sentinel\n' > "$OUTSIDE6/.gitignore"
ln -s "$OUTSIDE6" "$T6/.codex"
run "$T6"
if [ "$(cat "$OUTSIDE6/.gitignore")" = "outside-dir-sentinel" ]; then ok; else no "6a: followed symlinked .codex directory"; fi
if git -C "$T6" check-ignore -q .claude/memory.jsonl; then ok; else no "6b: unsafe .codex prevented safe .claude protection"; fi

# 6c. repository-controlled .gitignore symlink must not be followed
T7="$(mktemp -d)"
OUTSIDE7="$(mktemp)"
git -C "$T7" init -q
mkdir -p "$T7/.claude"
printf 'outside-file-sentinel\n' > "$OUTSIDE7"
ln -s "$OUTSIDE7" "$T7/.claude/.gitignore"
run "$T7"
if [ "$(cat "$OUTSIDE7")" = "outside-file-sentinel" ]; then ok; else no "6c: followed symlinked .claude/.gitignore"; fi
if git -C "$T7" check-ignore -q .codex/memory.jsonl; then ok; else no "6d: unsafe Claude ignore file prevented safe Codex protection"; fi

echo "test-memory-gitignore.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
