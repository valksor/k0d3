#!/usr/bin/env python3
"""validate-skills.sh helper. Implements the lint logic in Python because macOS bash 3.2
lacks mapfile and associative arrays. Invoked by the .sh wrapper."""

from __future__ import annotations

import datetime as dt
import os
import pathlib
import re
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

FAIL = 0
WARN = 0
TODAY = dt.date.today().isoformat()


def err(msg: str) -> None:
    global FAIL
    print(f"FAIL: {msg}", file=sys.stderr)
    FAIL += 1


def warn(msg: str) -> None:
    global WARN
    print(f"warn: {msg}", file=sys.stderr)
    WARN += 1


SKILLS_DIR = REPO / "skills"
known_slugs: set[str] = set()
newest_skill_mtime = 0.0

skill_dirs = sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir()) if SKILLS_DIR.exists() else []
for d in skill_dirs:
    slug = d.name
    if slug.startswith("_probe-"):
        continue
    known_slugs.add(slug)
    sk = d / "SKILL.md"
    # Exclude skill-discovery's own mtime so it's not compared against itself
    if sk.exists() and slug != "skill-discovery":
        newest_skill_mtime = max(newest_skill_mtime, sk.stat().st_mtime)


def iso_in_value(v: str) -> str | None:
    m = re.search(r"(\d{4}-\d{2}-\d{2})", v)
    return m.group(1) if m else None


# --- Skill checks ---
for d in skill_dirs:
    slug = d.name
    if slug.startswith("_probe-"):
        continue
    sk = d / "SKILL.md"
    if not sk.exists():
        err(f"{d}: missing SKILL.md")
        continue

    fm = parse_frontmatter(sk)
    name = fm.get("name")
    desc = fm.get("description")
    md = fm.get("metadata") or {}
    typ = md.get("type")
    status = md.get("status")
    blocked_on = md.get("blocked_on")
    invokes_shell = md.get("invokes_shell")
    shell_reviewed = md.get("shell_reviewed")
    related = md.get("related") or []

    if not name:
        err(f"{sk}: missing name")
    if not desc:
        err(f"{sk}: missing description")
    if not typ:
        err(f"{sk}: missing metadata.type")
    if not status:
        err(f"{sk}: missing metadata.status")
    if name and name != slug:
        err(f"{sk}: name ({name}) != directory ({slug})")
    if status == "stub":
        err(f"{sk}: status:stub forbidden")

    lines = body_line_count(sk)
    if slug != "skill-discovery" and lines > 200:
        err(f"{sk}: body {lines} lines > 200 cap")

    if invokes_shell is False and status == "active" and not shell_reviewed:
        err(f'{sk}: invokes_shell=false + status=active requires shell_reviewed: "<who> <date>"')
    if invokes_shell is True:
        warn(f"{sk}: invokes_shell=true — confirm line-by-line review before flipping to active")

    if blocked_on:
        iso = iso_in_value(str(blocked_on))
        if iso and iso < TODAY:
            warn(f"{sk}: blocked_on date {iso} has passed — consider flipping status")

    if related:
        if not isinstance(related, list):
            err(f"{sk}: metadata.related must be a list")
        else:
            for r in related:
                if r not in known_slugs:
                    err(f"{sk}: related slug '{r}' not found in skills/")

    # Pack: bundles existence check + dedupe warning
    bundles = md.get("bundles") or []
    if bundles:
        if not isinstance(bundles, list):
            err(f"{sk}: metadata.bundles must be a list")
        else:
            seen = set()
            for b in bundles:
                if b not in known_slugs:
                    err(f"{sk}: bundles slug '{b}' not found in skills/")
                if b in seen:
                    warn(f"{sk}: bundles slug '{b}' listed multiple times")
                seen.add(b)

# --- skill-discovery freshness ---
disc = SKILLS_DIR / "skill-discovery" / "SKILL.md"
if disc.exists():
    text = disc.read_text(encoding="utf-8")
    m = re.search(r"^last-generated:\s*[\"']?([^\"'\n]+)[\"']?", text, re.MULTILINE)
    if m:
        try:
            # Treat as UTC; convert to epoch via timezone-aware datetime
            t = (
                dt.datetime.strptime(m.group(1).strip(), "%Y-%m-%dT%H:%M:%SZ")
                .replace(tzinfo=dt.timezone.utc)
                .timestamp()
            )
            # 5-minute buffer to avoid races right after generation
            if newest_skill_mtime and t + 300 < newest_skill_mtime:
                warn(
                    f"{disc}: last-generated ({m.group(1).strip()}) older than newest skill — rerun generate-skill-graph.sh"
                )
        except Exception:
            pass

# --- Agent checks ---
AGENTS_DIR = REPO / "agents"
if AGENTS_DIR.exists():
    code_block_re = re.compile(r"^```")
    skill_call_re = re.compile(r"Skill\(([a-z0-9][a-z0-9-]*)\)")
    for ag in sorted(AGENTS_DIR.rglob("*.md")):
        fm = parse_frontmatter(ag)
        if not fm:
            continue
        if not fm.get("name"):
            err(f"{ag}: missing name")
        if not fm.get("description"):
            err(f"{ag}: missing description")
        if not fm.get("tools"):
            err(f"{ag}: missing tools")
        if not fm.get("model"):
            err(f"{ag}: missing model")
        fm_skills = set(fm.get("skills") or [])

        # Check frontmatter skills: all exist in skills/
        for s in fm_skills:
            if s not in known_slugs:
                err(f"{ag}: frontmatter skills entry '{s}' not found in skills/")

        # Parse body for Skill() outside fenced code blocks
        text = ag.read_text(encoding="utf-8")
        parts = text.split("---", 2)
        body = parts[2] if len(parts) >= 3 else text
        in_fence = False
        called: set[str] = set()
        for line in body.splitlines():
            if code_block_re.match(line):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for m in skill_call_re.finditer(line):
                called.add(m.group(1))
        for s in called - fm_skills:
            warn(f"{ag}: body invokes Skill({s}) but '{s}' not in frontmatter skills:")

print(f"validate-skills.sh: {FAIL} fail, {WARN} warn", file=sys.stderr)
sys.exit(1 if FAIL > 0 else 0)
