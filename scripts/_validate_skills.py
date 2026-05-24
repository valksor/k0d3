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

# Description length caps. Only frontmatter `description` (and `name`) count toward
# Claude Code's session skill-listing budget (skillListingBudgetFraction); the body
# does not. Keep descriptions to a one-line trigger so the whole catalogue's listing
# fits without the harness dropping descriptions ("name-only") and nagging the user.
DESC_WARN = 180
DESC_FAIL = 220
# Advisory soft cap on the total name+description footprint of all skills. The true
# budget also depends on the user's context-window size and the built-in skills that
# share the listing, so this is a self-discipline signal, not an exact mirror.
LISTING_BUDGET_WARN_CHARS = 22000


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
listing_chars = 0  # running total of name+description across skills (budget footprint)

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
    elif len(desc) > DESC_FAIL:
        err(
            f"{sk}: description {len(desc)} chars > {DESC_FAIL} cap — trim to a one-line "
            f"trigger; move detail to the body (docs/conventions.md § Skill frontmatter)"
        )
    elif len(desc) > DESC_WARN:
        warn(f"{sk}: description {len(desc)} chars > {DESC_WARN} — tighten toward a one-line trigger")
    listing_chars += len(name or "") + len(desc or "")
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

# --- listing budget footprint (advisory) ---
if listing_chars > LISTING_BUDGET_WARN_CHARS:
    warn(
        f"skill listing footprint {listing_chars} chars > {LISTING_BUDGET_WARN_CHARS} soft cap — "
        f"the session skill listing may overflow skillListingBudgetFraction for end users; tighten the "
        f"longest descriptions (advisory: true budget also depends on context size + built-in skills)"
    )

# --- skill-discovery freshness ---
disc = SKILLS_DIR / "skill-discovery" / "SKILL.md"
if disc.exists():
    # Guard against Prettier (or any formatter) re-padding the generated table.
    # Clean output is ~67 KB; column-aligning the markdown table blows it past 2 MB.
    # The fix is the .prettierignore entry; this catches the regression if it's lost.
    size = disc.stat().st_size
    if size > 262_144:
        err(
            f"{disc}: {size} bytes > 256 KB cap — likely Prettier re-padded the table; "
            f"ensure it is listed in .prettierignore, then rerun generate-skill-graph.sh"
        )
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
