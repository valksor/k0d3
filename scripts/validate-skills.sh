#!/usr/bin/env bash
# validate-skills.sh — wrapper around _validate_skills.py (Python because macOS bash is 3.2)
# Inputs: none
# Exit codes: 0 = all pass; 1 = at least one fail
# Side effects: prints to stderr
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/_validate_skills.py" "$@"
