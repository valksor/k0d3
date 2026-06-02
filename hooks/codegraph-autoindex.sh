#!/usr/bin/env bash
# SessionStart(startup) hook — provision codegraph's per-repo index in the background.
#
# The codegraph MCP server (bundled in .mcp.json) SERVES an index but never BUILDS
# one: a repo with no .codegraph/ answers every codegraph_* tool with "not
# initialized". This hook fills that gap — the same way ensure-memory-gitignore
# provisions memory's parent dir — by kicking off an index in a DETACHED background
# process so session start never blocks.
#
# Strictly fail-soft: does nothing unless this is a git repo that has no index yet
# and `npx`/`jq` are present. The codegraph package spec is read from the plugin's
# own .mcp.json (single source of truth), so it can never drift from what's bundled.

set -uo pipefail

[ -z "${CLAUDE_PROJECT_DIR:-}" ] && exit 0
DIR="$CLAUDE_PROJECT_DIR"

# Only auto-index real code repos — never a bare directory, a notes folder, or $HOME.
[ -d "$DIR/.git" ] || exit 0

# Already indexed → the serve watcher keeps it fresh; nothing to do.
[ -f "$DIR/.codegraph/codegraph.db" ] && exit 0

# We run codegraph exactly as .mcp.json does (via npx); jq reads the package spec.
command -v npx > /dev/null 2>&1 || exit 0
command -v jq > /dev/null 2>&1 || exit 0

MCP_JSON="${CLAUDE_PLUGIN_ROOT:-}/.mcp.json"
[ -f "$MCP_JSON" ] || exit 0
# The @scope/name arg (with or without a trailing @version), skipping codegraph's
# `serve --mcp` args. All bundled servers are scoped, so the @scope/ prefix is unambiguous.
# Keep this selector identical across its four consumers — smoke-mcp-{memory,sequentialthinking,codegraph}.sh
# and hooks/codegraph-autoindex.sh; no automated parity test guards them any more.
SPEC="$(jq -r '.mcpServers.codegraph.args[]? | select(type == "string" and test("^@[A-Za-z0-9._-]+/[A-Za-z0-9._-]+"))' "$MCP_JSON" 2> /dev/null | head -1)"
[ -n "$SPEC" ] || exit 0

LOG_DIR="$DIR/.claude/logs"
mkdir -p "$LOG_DIR" 2> /dev/null || exit 0
LOCK="$LOG_DIR/.codegraph-indexing"
LOG="$LOG_DIR/codegraph-index.log"

# Don't stack index runs across rapid restarts. The lock is a DIRECTORY: mkdir is atomic
# on POSIX, so two near-simultaneous session starts can't both pass a check and both spawn
# an index build (a check-then-touch on a file would race). A stale lock (>30 min, e.g. a
# killed build) is reclaimed first so a crash can't wedge indexing forever.
if [ -d "$LOCK" ] && find "$LOCK" -mmin +30 2> /dev/null | grep -q .; then
  rm -rf "$LOCK" 2> /dev/null
fi
mkdir "$LOCK" 2> /dev/null || exit 0

# Keep the WHOLE .codegraph/ out of the user's repo. codegraph's own .codegraph/.gitignore
# (written by init) ignores only the index DATA (*.db, cache/, *.log) — it leaves
# .codegraph/config.json and the .gitignore itself committable, so on its own the dir is
# only PARTIALLY ignored and those two files leak into `git status` / `git add .`. Excluding
# the dir locally via .git/info/exclude (repo-local, never committed, leaves the user's
# tracked .gitignore untouched) hides all of it — and also covers a failed/partial init that
# never wrote .codegraph/.gitignore at all.
EXCLUDE="$DIR/.git/info/exclude"
if [ -f "$EXCLUDE" ] && ! grep -qxF '.codegraph/' "$EXCLUDE" 2> /dev/null; then
  printf '%s\n' '.codegraph/' >> "$EXCLUDE" 2> /dev/null || true
fi

# Detached background build so SessionStart returns immediately. stdin=/dev/null so
# codegraph's clack prompts (e.g. the watch-fallback offer) can never hang; all
# output is captured to a log for triage.
(
  ts() { date +"%Y-%m-%d %H:%M:%S"; }
  echo "[$(ts)] codegraph autoindex: start ($SPEC) in $DIR" >> "$LOG"
  if [ -d "$DIR/.codegraph" ]; then
    # Dir exists but no db: either a cleared index (re-index) or a half-finished init that
    # died before writing the db. (Re)index quietly first; if that still leaves no db the
    # dir was never fully initialized, so fall back to a fresh init — otherwise a partial
    # .codegraph/ would wedge every future session on this branch forever.
    npx -y "$SPEC" index "$DIR" -q < /dev/null >> "$LOG" 2>&1
    rc=$?
    if [ ! -f "$DIR/.codegraph/codegraph.db" ]; then
      echo "[$(ts)] codegraph autoindex: index left no db — retrying with init" >> "$LOG"
      npx -y "$SPEC" init "$DIR" -i < /dev/null >> "$LOG" 2>&1
      rc=$?
    fi
  else
    # Fresh repo — initialize and run the initial index in one shot.
    npx -y "$SPEC" init "$DIR" -i < /dev/null >> "$LOG" 2>&1
    rc=$?
  fi
  echo "[$(ts)] codegraph autoindex: done rc=$rc" >> "$LOG"
  echo "- \`$(ts)\` | SESSION | INFO | codegraph autoindex done rc=$rc ($DIR)" >> "$LOG_DIR/incident-log.md" 2> /dev/null
  rm -rf "$LOCK" 2> /dev/null
) < /dev/null > /dev/null 2>&1 &
disown 2> /dev/null || true

echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | INFO | codegraph autoindex launched ($DIR)" >> "$LOG_DIR/incident-log.md" 2> /dev/null

exit 0
