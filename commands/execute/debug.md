---
name: debug
description: Start systematic debugging on a bug, test failure, or unexpected behavior.
argument-hint: "[symptom]"
allowed-tools: [Read, Edit, Grep, Glob, Bash, Skill, Agent]
---

# /debug

Invokes `Skill(k0d3:debugging)` and walks the four phases (root-cause investigation → pattern analysis → hypothesis → fix). No fix attempts until Phase 1 is complete.

If the issue is a cryptic error message, the `error-whisperer` agent may help interpret it before debugging proper begins.

Argument: short description of the symptom. The skill drives the rest.
