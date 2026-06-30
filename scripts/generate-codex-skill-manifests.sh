#!/usr/bin/env bash
# generate-codex-skill-manifests.sh [--check] — wrapper around
# _generate_codex_skill_manifests.py.
# Inputs: optional --check (verify committed openai.yaml files are in sync)
# Exit codes: propagated from helper
# Side effects: writes skills/<slug>/agents/openai.yaml for every non-draft skill
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/_generate_codex_skill_manifests.py" "$@"
