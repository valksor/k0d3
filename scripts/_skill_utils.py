"""Shared helpers for skill-related scripts. Centralizes frontmatter parsing
so behaviors (BOM, CRLF, trailing-space-after-`---`, etc.) stay consistent
across _validate_skills.py, _smoke_skills.py, _generate_skill_graph.py,
and _sharpness_check.py.

PyYAML is a hard dependency for the consumers (they sys.exit if missing);
this module just imports it lazily so that import-time errors surface at
the consumer rather than here.
"""

from __future__ import annotations

import pathlib

try:
    import yaml
except ImportError:  # pragma: no cover — consumers handle their own messaging
    yaml = None  # type: ignore[assignment]


def parse_frontmatter(path: pathlib.Path) -> dict:
    """Return the YAML frontmatter of a Markdown file as a dict.

    Returns an empty dict on any parse failure (missing file, no frontmatter,
    invalid YAML, frontmatter is not a mapping). Callers should treat an
    empty dict as "no frontmatter" rather than "missing fields".
    """
    if yaml is None:
        return {}
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return {}
    if not text.startswith("---"):
        return {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}
    try:
        data = yaml.safe_load(parts[1]) or {}
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}


def body(path: pathlib.Path) -> str:
    """Return the body of a Markdown file (everything after the closing `---`).

    For files without frontmatter, returns the entire content.
    """
    text = path.read_text(encoding="utf-8")
    parts = text.split("---", 2)
    return parts[2] if len(parts) >= 3 else text


def body_line_count(path: pathlib.Path) -> int:
    """Line count of the body (post-frontmatter)."""
    return body(path).count("\n")
