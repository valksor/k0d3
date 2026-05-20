#!/usr/bin/env python3
"""sharpness-check.sh helper. Advisory heuristics to catch bland prose.

Per skill (status: active, excluding skill-discovery + meta):
  - First 400 chars of body contain an imperative signal:
      MUST | NEVER | Iron Law | Always | Forbidden | DO NOT | Never |
      Don't | Stop | Halt
  - Body has an "Anti-patterns" or "Red flags" or "Forbidden" section header
  - Body line count <= 150 (warn at 151-200; fail at >200 — already lint-enforced)
  - Body contains at least one markdown table (`|---|`)
  - Body contains an opinion signal: `use <X>` | `prefer <X>` | `pick <X>` |
    case-insensitive

Each missing signal is a "softness" point. Output: per-skill softness score
(0-5), plus a flat summary. Advisory — exit 0 always."""

from __future__ import annotations

import pathlib
import re
import sys

try:
    import yaml  # noqa: F401  — surfaces import error early; _skill_utils uses it
except ImportError:
    print("FAIL: PyYAML not installed. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from _skill_utils import parse_frontmatter, body

REPO = pathlib.Path(__file__).resolve().parent.parent
SKILLS = REPO / "skills"

IMPERATIVE_RE = re.compile(
    r"\b(MUST|NEVER|Iron Law|Always|Forbidden|DO NOT|Never|Don't|Stop|Halt|Required|Mandatory)\b"
)
SECTION_RE = re.compile(
    r"^#{1,4}\s+(Anti[- ]?pattern|Red flag|Forbidden|Never|Don't|Stop)",
    re.MULTILINE | re.IGNORECASE,
)
TABLE_RE = re.compile(r"^\|\s*-+\s*\|", re.MULTILINE)
OPINION_RE = re.compile(r"\b(use|prefer|pick)\s+\S+", re.IGNORECASE)

EXEMPT = {"skill-discovery", "using-k0d3"}


total = 0
soft_total = 0
per_skill: list[tuple[str, int, list[str]]] = []

for d in sorted(p for p in SKILLS.iterdir() if p.is_dir()):
    slug = d.name
    if slug.startswith("_probe-") or slug in EXEMPT:
        continue
    sk = d / "SKILL.md"
    if not sk.exists():
        continue
    fm = parse_frontmatter(sk)
    if (fm.get("metadata") or {}).get("status") != "active":
        continue
    text_body = body(sk)

    misses = []
    head = text_body[:400]
    if not IMPERATIVE_RE.search(head):
        misses.append("no-imperative-in-head")
    if not SECTION_RE.search(text_body):
        misses.append("no-antipattern-section")
    lines = text_body.count("\n")
    if lines > 150:
        misses.append(f"verbose ({lines} lines, target <=150)")
    if not TABLE_RE.search(text_body):
        misses.append("no-table")
    if not OPINION_RE.search(text_body):
        misses.append("no-opinion-signal")

    total += 1
    soft_total += len(misses)
    if misses:
        per_skill.append((slug, len(misses), misses))

# Sort worst-first
per_skill.sort(key=lambda t: -t[1])

print(f"sharpness-check: {total} active skills, {soft_total} softness points total", file=sys.stderr)
if per_skill:
    print("\nWorst offenders (softness 3-5):", file=sys.stderr)
    for slug, score, misses in per_skill:
        if score >= 3:
            print(f"  {slug} ({score}): {', '.join(misses)}", file=sys.stderr)
    print("\nMild softness (1-2):", file=sys.stderr)
    for slug, score, misses in per_skill:
        if score in (1, 2):
            print(f"  {slug} ({score}): {', '.join(misses)}", file=sys.stderr)

# Advisory only — exit 0 always
sys.exit(0)
