---
name: description-overflow
description: This fixture exercises the write-time description-length hard cap and is intentionally padded so its parsed length lands one character past the two hundred twenty cap, a boundary fencepost rather than a far-over value pad
metadata:
  type: meta
  status: draft
  invokes_shell: false
---

# description-overflow

Validator test fixture. MUST stay status:draft with invokes_shell:false and no
shell_reviewed — that combination is intentional so the ONLY defect is the
over-cap (>220) frontmatter description above; flipping to active would add a
shell_reviewed error and mask what this fixture is meant to catch.
