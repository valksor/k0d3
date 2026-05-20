#!/usr/bin/env bash
# smoke-skills.sh — wrapper around _smoke_skills.py
# Inputs: none
# Exit codes: 0 = all active skills pass; 1 = any fail
# Side effects: writes .claude/logs/smoke-results-<date>.log
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/_smoke_skills.py" "$@"
