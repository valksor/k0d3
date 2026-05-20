#!/usr/bin/env bash
# generate-skill-graph.sh [--prune-drafts] — wrapper around _generate_skill_graph.py
# Inputs: optional --prune-drafts
# Exit codes: propagated from helper
# Side effects: overwrites docs/skill-graph.md and skills/skill-discovery/SKILL.md
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/_generate_skill_graph.py" "$@"
