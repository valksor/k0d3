---
name: tdd
description: Begin (or resume) a test-driven development cycle for the current task.
argument-hint: "[task-description]"
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash, Skill]
---

# /tdd

Invokes `Skill(tdd)` and enters the Red-Green-Refactor loop for the described task. Argument is the feature/bug being worked on.

Iron law: no production code without a failing test first. The skill enforces the cycle.
