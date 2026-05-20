---
name: refactor
description: Refactor code without changing behavior. Tests must stay green throughout.
argument-hint: "[target]"
allowed-tools: [Read, Edit, Grep, Glob, Bash, Skill]
---

# /refactor

Invokes `Skill(k0d3:refactoring)`. Enforces the two-hat rule (no feature work mid-refactor), small steps, frequent commits, tests green at every step.

Argument: the file, module, or pattern being refactored.
