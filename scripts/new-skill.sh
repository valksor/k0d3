#!/usr/bin/env bash
# new-skill.sh <slug>
# Inputs: $1 = kebab-case slug for the new skill
# Exit codes: 0 on success; 1 on bad input or pre-existing dir; 2 if validate-skills.sh fails on the scaffold
# Side effects: creates skills/<slug>/SKILL.md with template frontmatter
#
# Self-validates by running scripts/validate-skills.sh on the result. If validation fails, the new skill remains
# on disk but the script exits non-zero so the author sees the issue immediately.
#
# Scaffold uses neutral placeholder text (no TBD/TODO/FIXME) so it does not
# trip completeness-gate.sh when the author starts editing it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SLUG="${1:-}"
if [[ -z "$SLUG" ]]; then
  echo "usage: new-skill.sh <slug>" >&2
  exit 1
fi
# Tighter regex: kebab-case, no leading digit, no trailing or doubled hyphens
if ! [[ "$SLUG" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
  echo "slug must be kebab-case (lowercase letters, digits, single hyphens between alphanumeric segments; start with letter; no trailing hyphen): $SLUG" >&2
  exit 1
fi

DIR="skills/$SLUG"
if [[ -e "$DIR" ]]; then
  echo "$DIR already exists" >&2
  exit 1
fi
mkdir -p "$DIR"

# Neutral placeholder text — gate-safe (no TBD/TODO/FIXME) so the author can
# iteratively edit without the completeness-gate denying the first Edit.
# status: draft means validate-skills.sh won't fail on incomplete metadata.
cat > "$DIR/SKILL.md" << EOF
---
name: $SLUG
description: One-line trigger description goes here.
metadata:
  type: core
  status: draft
  invokes_shell: false
  related: []
---

# $SLUG

Replace this body with content. Body cap is ~200 lines; long-form to references/.
EOF

echo "Created $DIR/SKILL.md" >&2

# Self-validate; echo the specific failures so the author sees them without scrolling
if [[ -x scripts/validate-skills.sh ]]; then
  VALIDATE_OUT="$(bash scripts/validate-skills.sh 2>&1)" || {
    echo "" >&2
    echo "validate-skills.sh failed on new scaffold:" >&2
    printf '%s\n' "$VALIDATE_OUT" | sed 's/^/  /' >&2
    echo "" >&2
    echo "Fix the issues above before activating ($DIR/SKILL.md remains on disk)." >&2
    exit 2
  }
fi
