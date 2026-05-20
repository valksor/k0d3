#!/usr/bin/env python3
"""smoke-skills.sh helper. Iterates every status:active skill and asserts smoke invariants.
Drafts are skipped by design (uninvokable, not ready for smoke). Writes
.claude/logs/smoke-results-<date>.log with per-skill pass/fail."""

from __future__ import annotations

import datetime as dt
import os
import pathlib
import sys

try:
    import yaml  # noqa: F401  — surfaces import error early; _skill_utils uses it
except ImportError:
    print("FAIL: PyYAML not installed. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from _skill_utils import parse_frontmatter, body_line_count

REPO = pathlib.Path(__file__).resolve().parent.parent
os.chdir(REPO)

LOG_DIR = REPO / ".claude" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG = LOG_DIR / f"smoke-results-{dt.date.today().strftime('%Y%m%d')}.log"
LOG.write_text("")

PASS = 0
FAIL = 0


def log(line: str) -> None:
    with LOG.open("a") as f:
        f.write(line + "\n")


SKILLS_DIR = REPO / "skills"
skill_dirs = sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir()) if SKILLS_DIR.exists() else []
known = {d.name for d in skill_dirs if not d.name.startswith("_probe-")}

for d in skill_dirs:
    slug = d.name
    if slug.startswith("_probe-"):
        continue
    sk = d / "SKILL.md"
    if not sk.exists():
        log(f"FAIL {slug}: missing SKILL.md")
        FAIL += 1
        continue

    fm = parse_frontmatter(sk)
    status = (fm.get("metadata") or {}).get("status")
    if status != "active":
        log(f"SKIP {slug}: status={status}")
        continue

    name = fm.get("name")
    md = fm.get("metadata") or {}
    typ = md.get("type")
    related = md.get("related") or []
    lines = body_line_count(sk)
    failed = False

    if name != slug:
        log(f"FAIL {slug}: name '{name}' != dir '{slug}'")
        failed = True
    if not typ:
        log(f"FAIL {slug}: metadata.type missing")
        failed = True
    if slug != "skill-discovery" and lines > 200:
        log(f"FAIL {slug}: body {lines} > 200")
        failed = True
    for r in related:
        if r not in known:
            log(f"FAIL {slug}: related '{r}' not found")
            failed = True

    if failed:
        FAIL += 1
    else:
        log(f"PASS {slug}")
        PASS += 1

print(f"smoke-skills.sh: {PASS} pass, {FAIL} fail. Log: {LOG}", file=sys.stderr)
sys.exit(1 if FAIL > 0 else 0)
