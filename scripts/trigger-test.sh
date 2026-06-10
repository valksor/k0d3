#!/usr/bin/env bash
# trigger-test.sh — wrapper around _trigger_test.py
# Inputs: [--skill <slug>]... [--model <m>] [--bar 0.9] [--budget-usd 0.50] [--timeout 180]
# Exit codes: 0 = every tested skill meets the activation bar with no false-triggers; 1 otherwise
# Side effects: each corpus prompt runs a real (billed) headless `claude -p` session — opt-in
# tool, NOT wired into CI or validate/smoke. Corpora live at skills/<slug>/trigger-prompts.txt.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/_trigger_test.py" "$@"
