---
name: security-audit
description: Run a security-focused audit on a path or PR — OWASP, secrets, injection, auth.
argument-hint: "[path-or-pr]"
allowed-tools: [Read, Grep, Glob, Bash(git:*), Bash(gh:*), Agent, Skill]
---

# /security-audit

Dispatches `Agent(security-auditor)` against the specified target. The agent invokes `Skill(security)` and `Skill(security)` for category-specific deep-dives.

Argument:

- A path → audits the files under it
- A PR number (e.g. `#123`) → audits the PR diff
- Empty → audits the current branch's diff against `origin/main`

Output: findings categorized by severity (Critical / High / Medium / Low / Info), with specific file:line references and remediation suggestions.
