#!/usr/bin/env bash
# test-memory-gitignore.sh — verifies hooks/ensure-memory-gitignore.sh:
#   1. creates .codex/ and ignores memory.jsonl + sidecars for Codex
#   2. self-ignores its generated file and is idempotent
#   3. does not clobber existing content
#   4. skips writing when a parent ignore already covers .codex/
#   5. fails open without CLAUDE_PROJECT_DIR
#   6. retains .claude/ behavior for Claude Code
#   7. refuses store-directory and .gitignore symlinks
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

# 1. fresh Codex git repo
T1="$(mktemp -d)"
git -C "$T1" init -q
run_codex "$T1"
if [ -d "$T1/.codex" ]; then ok; else no "1a: .codex/ not created"; fi
if git -C "$T1" check-ignore -q .codex/memory.jsonl; then ok; else no "1b: Codex memory.jsonl not ignored"; fi
if git -C "$T1" check-ignore -q .codex/memory.jsonl.tmp; then ok; else no "1c: Codex memory sidecars not ignored"; fi
if [ ! -e "$T1/.claude" ]; then ok; else no "1d: Codex run created .claude/"; fi
if [ -z "$(git -C "$T1" status --porcelain)" ]; then ok; else no "1e: generated Codex ignore file dirtied the repo"; fi

# 2. idempotent
run_codex "$T1"
COUNT="$(grep -c '^memory\.jsonl$' "$T1/.codex/.gitignore" 2> /dev/null || true)"
if [ "$COUNT" = "1" ]; then ok; else no "2a: rule count is '$COUNT' (expected 1) on re-run"; fi
SIDECAR_COUNT="$(grep -c '^memory\.jsonl\.\*$' "$T1/.codex/.gitignore" 2> /dev/null || true)"
if [ "$SIDECAR_COUNT" = "1" ]; then ok; else no "2b: sidecar rule count is '$SIDECAR_COUNT' (expected 1)"; fi
SELF_COUNT="$(grep -c '^\.gitignore$' "$T1/.codex/.gitignore" 2> /dev/null || true)"
if [ "$SELF_COUNT" = "1" ]; then ok; else no "2c: self-ignore rule count is '$SELF_COUNT' (expected 1)"; fi

# 3. does not clobber existing content
T3="$(mktemp -d)"
git -C "$T3" init -q
mkdir -p "$T3/.codex"
printf 'logs/\n' > "$T3/.codex/.gitignore"
run_codex "$T3"
if grep -q '^logs/$' "$T3/.codex/.gitignore"; then ok; else no "3a: clobbered existing content"; fi
if grep -q '^memory\.jsonl$' "$T3/.codex/.gitignore"; then ok; else no "3b: rule not appended"; fi
if grep -q '^memory\.jsonl\.\*$' "$T3/.codex/.gitignore"; then ok; else no "3c: sidecar rule not appended"; fi

# 3d. upgrade an existing generated file that predates the self-ignore rule
T3D="$(mktemp -d)"
git -C "$T3D" init -q
mkdir -p "$T3D/.codex"
printf 'memory.jsonl\nmemory.jsonl.*\n' > "$T3D/.codex/.gitignore"
run_codex "$T3D"
if grep -Fxq '.gitignore' "$T3D/.codex/.gitignore"; then ok; else no "3d: existing generated file not upgraded with self-ignore"; fi
if [ -z "$(git -C "$T3D" status --porcelain)" ]; then ok; else no "3e: upgraded ignore file still dirtied the repo"; fi

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
if git -C "$T6" check-ignore -q .claude/memory.jsonl.tmp; then ok; else no "6b: Claude memory sidecars not ignored"; fi
if [ ! -e "$T6/.codex" ]; then ok; else no "6c: Claude run created .codex/"; fi

# 7a. repository-controlled store directory symlink must not be followed
T7="$(mktemp -d)"
OUTSIDE7="$(mktemp -d)"
git -C "$T7" init -q
printf 'outside-dir-sentinel\n' > "$OUTSIDE7/.gitignore"
ln -s "$OUTSIDE7" "$T7/.codex"
run_codex "$T7"
if [ "$(cat "$OUTSIDE7/.gitignore")" = "outside-dir-sentinel" ]; then ok; else no "7a: followed symlinked .codex directory"; fi
if [ ! -e "$T7/.claude" ]; then ok; else no "7b: unsafe Codex path created Claude state"; fi

# 7c. repository-controlled .gitignore symlink must not be followed
T8="$(mktemp -d)"
OUTSIDE8="$(mktemp)"
git -C "$T8" init -q
mkdir -p "$T8/.claude"
printf 'outside-file-sentinel\n' > "$OUTSIDE8"
ln -s "$OUTSIDE8" "$T8/.claude/.gitignore"
run_claude "$T8"
if [ "$(cat "$OUTSIDE8")" = "outside-file-sentinel" ]; then ok; else no "7c: followed symlinked .claude/.gitignore"; fi
if [ ! -e "$T8/.codex" ]; then ok; else no "7d: unsafe Claude path created Codex state"; fi

echo "test-memory-gitignore.sh: $PASS pass, $FAIL fail" >&2
exit $((FAIL > 0 ? 1 : 0))
