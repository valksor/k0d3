---
name: security-audit
description: Run a security-focused audit on a path or PR — OWASP, secrets, injection, auth — then validate and auto-fix the findings.
argument-hint: "[path-or-pr]"
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash(git:*), Bash(gh:*), Agent, Skill]
---

# /security-audit

Dispatches `Agent(security-auditor)` against the specified target. The agent invokes `Skill(security)` for OWASP-category deep-dives.

Argument:

- A path → audits the files under it
- A PR number (e.g. `#123`) → audits the PR diff
- Empty → audits the current branch's diff against `origin/main`

Output: findings categorized by severity (Critical / High / Medium / Low / Info), with specific file:line references and remediation suggestions.

**Plan mode is fine — do not stop to ask.** The audit itself is read-only. In plan mode the disposition step writes the validated findings and their intended fixes to the active plan file instead of editing source, per `references/review-finding-disposition.md`. Run the audit.

Then disposition the findings: **Read `references/review-finding-disposition.md` and follow it** — validate each against the actual code, fix **every** valid finding directly (all severities), skip false positives with a one-line reason, never push, and **do not ask for permission**. Per the reference's guard clause, when the target is a PR not checked out locally, present the remediations instead of editing.
