---
name: plan
description: Write a comprehensive implementation plan from an approved spec.
argument-hint: "[spec-path]"
allowed-tools: [Read, Grep, Glob, Write, Skill]
---

# /plan

Invokes `Skill(k0d3:planning)` against an approved spec to produce a bite-sized implementation plan with file paths, code, tests, and commits.

Argument `[spec-path]` (optional): path to the spec doc to plan from. If omitted, looks for the most recent spec in `docs/specs/`.

Output: a plan saved to `docs/plans/YYYY-MM-DD-<feature-name>.md` and a prompt to execute via `Skill(subagent-driven-development)` (recommended) or inline.
