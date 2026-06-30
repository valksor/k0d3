#!/usr/bin/env python3
"""generate-codex-skill-manifests.sh helper.

Writes skills/<slug>/agents/openai.yaml for every non-draft skill so Codex surfaces
k0d3 skills. Codex reads agents/openai.yaml (the `interface` block) — NOT the SKILL.md
frontmatter — to title and describe a skill in its `/skills` UI and `$slug` menu. The
format mirrors the bundled `documents` plugin's openai.yaml (the authoritative example).

YAML is emitted via PyYAML (never f-string interpolation) so colons, parentheses, `$`,
and em-dashes in descriptions cannot produce malformed manifests that Codex's parser
rejects.

`allow_implicit_invocation` is intentionally NOT emitted: it is absent from the bundled
`documents` openai.yaml, so its acceptance/placement is unconfirmed. Skills remain
addressable explicitly via `$slug`; add the flag here once confirmed on a live Codex.

Usage:
  _generate_codex_skill_manifests.py            # (re)write all openai.yaml files
  _generate_codex_skill_manifests.py --check    # verify committed files are in sync
"""

from __future__ import annotations

import pathlib
import re
import sys

try:
    import yaml
except ImportError:
    print("FAIL: PyYAML not installed (`pip install pyyaml`)", file=sys.stderr)
    sys.exit(1)

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from _skill_utils import parse_frontmatter

REPO = pathlib.Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO / "skills"
CHECK = "--check" in sys.argv

# Keep short_description terse, like the bundled `documents` skill (~6-10 words).
SHORT_MAX = 100
_LEAD = re.compile(r"^\s*Use\s+(?:when|for|to|first\s+when|after|before)\b[:\s]*", re.I)


def title_case(slug: str) -> str:
    """Human display name from a kebab slug: 'go-testing' -> 'Go Testing'."""
    return slug.replace("-", " ").title()


def short_description(desc: str, fallback: str) -> str:
    """First clause of the skill description, lead-in stripped and length-capped."""
    text = " ".join((desc or "").split()).strip()
    text = _LEAD.sub("", text).strip()
    # Cut at the first clause boundary (em dash or sentence end) when present.
    for sep in (" — ", " - ", ". "):
        idx = text.find(sep)
        if 0 < idx < SHORT_MAX + 40:
            text = text[:idx]
            break
    text = text.strip().rstrip(".")
    if len(text) > SHORT_MAX:
        text = text[: SHORT_MAX - 1].rstrip() + "…"
    return text or fallback


def manifest_for(slug: str, fm: dict) -> str:
    short = short_description(fm.get("description") or "", slug)
    data = {
        "interface": {
            "display_name": title_case(slug),
            "short_description": short,
            "default_prompt": f"Use ${slug} — {short}",
        }
    }
    return yaml.dump(data, sort_keys=False, allow_unicode=True, default_flow_style=False)


def iter_skills():
    if not SKILLS_DIR.exists():
        return
    for d in sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir()):
        if d.name.startswith("_probe-"):
            continue
        sk = d / "SKILL.md"
        if not sk.exists():
            continue
        fm = parse_frontmatter(sk)
        status = (fm.get("metadata") or {}).get("status")
        if status == "draft":
            continue
        yield d, fm


def main() -> int:
    drift: list[str] = []
    written = 0
    for d, fm in iter_skills():
        content = manifest_for(d.name, fm)
        out = d / "agents" / "openai.yaml"
        if CHECK:
            if not out.exists() or out.read_text(encoding="utf-8") != content:
                drift.append(str(out.relative_to(REPO)))
        else:
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(content, encoding="utf-8")
            written += 1
    if CHECK:
        if drift:
            print(
                "FAIL: openai.yaml out of sync — run scripts/generate-codex-skill-manifests.sh:",
                file=sys.stderr,
            )
            for p in drift:
                print(f"  - {p}", file=sys.stderr)
            return 1
        print("openai.yaml manifests in sync")
        return 0
    print(f"wrote {written} agents/openai.yaml manifests")
    return 0


if __name__ == "__main__":
    sys.exit(main())
