---
name: review-code
description: Dispatch the 4 calibrated reviewer agents in parallel against local uncommitted code changes, then validate and auto-fix the findings.
argument-hint: "[all | file paths]"
allowed-tools: [Read, Edit, Write, Glob, Bash(git:*), Agent, Skill]
---

# /review-code

Multi-perspective review of local in-flight code — no plan context. Dispatches all four reviewers in parallel (single message, four Agent tool calls):

- `Agent(reviewer-senior-dev)` — architecture, maintainability, complexity, feasibility
- `Agent(reviewer-senior-qa)` — testability, edge cases, failure modes, regression risk
- `Agent(reviewer-security)` — auth, injection, supply chain, secrets
- `Agent(reviewer-end-user)` — usability, error messages, docs (covers developer-users and non-technical end users in a single review)

**Plan mode is fine — do not stop to ask.** The review itself (dispatch + consolidate) is read-only. In plan mode the disposition step writes the validated findings and their intended fixes to the active plan file instead of editing source, per `references/review-finding-disposition.md`. Run the review.

Argument `[scope]` (optional):

- omitted → `git diff` (unstaged changes)
- `all` → `git diff HEAD` (staged + unstaged)
- one or more file paths → read those files directly

**Whole-diff rule — review ALL of it, carve out nothing.** The selected scope is reviewed in its **entirety**: every changed file and every hunk goes to the reviewers **verbatim** — the same bytes `git` produced. Do **not** exclude, set aside, summarize, defer, or "flag separately" any hunk because you judge it incidental, tooling-generated, "not part of my feature," a dependency/lockfile bump, a separate concern, or code you didn't write — **none of those is a reason to drop a hunk.** `/review-code` has **no feature scope**; its scope is _all_ uncommitted changes in the selected set, so there is no "feature diff" to narrow to. A surprising change (a dependency bump that reverts an intentional pin, a stray edit) is precisely a finding to **surface**, not a hunk to hide — carving it out is the exact failure this rule exists to prevent. You may _call out_ a surprising change in your own summary, but you may **never remove it from the reviewers' input.**

Process:

1. Collect the diff (or file contents) per the scope rules above.
2. If the selected scope is empty:
   - staged changes exist but unstaged doesn't → tell the user: "No unstaged changes. Run `/k0d3:review-code all` to include staged changes." and STOP.
   - nothing uncommitted at all → STOP and tell the user: "No uncommitted changes. Use `/k0d3:review-impl` to review against a branch base." Do not auto-pick a base ref; do not guess.
3. Resolve stack skills. From the changed file paths (`git diff --name-only` over the selected scope, or the explicit file paths), determine the languages under review and each reviewer's skill slugs per `references/review-skill-routing.md` (which invokes `Skill(skill-discovery)` to resolve current slugs). Every reviewer gets its own short list, or `none`.
4. Dispatch the four reviewers in parallel (one message, four Agent tool calls), each with the **complete** diff (or file contents) for the scope — never a curated or feature-only subset, per the whole-diff rule above — **and its `Stack skills:` line** from step 3.
5. Consolidate findings into one summary (Blockers / Concerns / Advisories / Verdict).
   - Each reviewer self-applies its own calibration before returning output; the orchestrator does NOT re-classify findings.
   - The orchestrator's job is to: (a) dedupe findings reported by multiple reviewers, (b) preserve the highest severity assigned to any duplicate, (c) attribute each consolidated finding to the reviewers that flagged it, (d) compute the overall verdict (NEEDS WORK if any reviewer has confirmed blockers; CONCERNS REMAIN if only concerns; PASS if all four are clean), (e) preserve each finding's `(spec)`/`(code)` tag verbatim — `/review-code` runs with no requirements in scope, so every finding is `(code)`.

   Each reviewer emits all four sections (Blockers / Concerns / Advisories / Verdict) — empty sections are written as `- None` so the orchestrator's parse stays predictable.

6. Disposition the findings: **Read `references/review-finding-disposition.md` and follow it** — validate each against the actual code, fix **every** valid finding directly (all tiers), skip false positives with a one-line reason, never push, and **do not ask for permission**. The reference covers the validation standard, the report format, and the plan-mode / remote-PR guard clauses.

Pattern: the four reviewers are calibrated for code review of uncommitted work (real bugs, regression risk in fresh edits, security in code, end-user impact). For branch-diff review use `/k0d3:review-impl`. For plan-document review use `/k0d3:review-plan`.
