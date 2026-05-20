#!/usr/bin/env bash
# sharpness-check.sh — wrapper around _sharpness_check.py
# Advisory: scores skills on "softness" heuristics (imperatives, anti-pattern
# sections, body length, tables, opinion signals). Always exits 0.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/_sharpness_check.py" "$@"
