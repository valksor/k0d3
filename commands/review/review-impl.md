---
name: review-impl
description: Dispatch the 4 calibrated reviewer agents in parallel against an implementation diff, then validate and auto-fix the findings.
argument-hint: "[base-ref] [requirements-path]"
allowed-tools: [Read, Edit, Write, Glob, Bash(git:*), Agent, Skill]
---

# /review-impl

Multi-perspective review of an implementation. Dispatches all four reviewers in parallel (single message, four Agent tool calls):

- `Agent(reviewer-senior-dev)` — architecture, maintainability, complexity, feasibility
- `Agent(reviewer-senior-qa)` — testability, edge cases, failure modes, regression risk
- `Agent(reviewer-security)` — auth, injection, supply chain, secrets
- `Agent(reviewer-end-user)` — usability, error messages, docs (covers developer-users and non-technical end users in a single review)

**Plan mode is fine — do not stop to ask.** The review itself (dispatch + consolidate) is read-only. In plan mode the disposition step writes the validated findings and their intended fixes to the active plan file instead of editing source, per `references/review-finding-disposition.md`. Run the review.

Arguments:

- `[base-ref]` (optional): the git ref to diff against. Defaults to `origin/main` (then `origin/master`, then `HEAD~1` if neither exists).
- `[requirements-path]` (optional): path to the plan or spec the implementation should satisfy. If omitted, reviewers evaluate the diff on its own merits.

Process:

1. Compute `BASE_SHA` and `HEAD_SHA`:
   ```bash
   BASE=$(git rev-parse origin/main 2>/dev/null \
       || git rev-parse origin/master 2>/dev/null \
       || git rev-parse HEAD~1 2>/dev/null)
   HEAD=$(git rev-parse HEAD)
   ```
   If `[base-ref]` was provided, validate it resolves first (`git rev-parse --verify "<base-ref>"`); if it fails (typo, deleted branch, detached HEAD that doesn't exist), STOP and tell the user: "[base-ref] does not resolve. Check the branch/tag/SHA spelling."
   If all three fallbacks fail (single-commit repo with no remote), STOP and tell the user: "Cannot compute a base ref — this repo has only one commit and no remote. Pass an explicit [base-ref] (or commit some changes first)."
2. Compute `git diff $BASE..$HEAD --stat` and the full diff, then apply `references/review-generated-file-exclusion.md`: classify the changed files (use `$HEAD:<path>` for the content-marker sniff), build the manifest, and construct the per-reviewer diffs — the **Standard** profile (all generated content dropped) and the **Security** profile (lockfile content kept) per the reference's §3. If every change was a generated artifact, still run the review with the manifest — that is not an empty diff.
3. Read `[requirements-path]` if provided.
4. Resolve stack skills. From `git diff $BASE..$HEAD --name-only` (the full pre-exclusion list), determine the languages under review and each reviewer's skill slugs per `references/review-skill-routing.md` (which invokes `Skill(skill-discovery)` to resolve current slugs). Every reviewer gets its own short list, or `none`.
5. Dispatch the four reviewers in parallel (one message, four Agent tool calls), each with the diff content, the **manifest** of excluded generated artifacts, (if available) the requirements text, **and its `Stack skills:` line** from step 4. `reviewer-security` receives the **Security profile** diff (lockfile content kept in full per `references/review-generated-file-exclusion.md`); the other three receive the Standard profile. Because `review-impl` is the command most often run on untrusted contributor branches, instruct `reviewer-security` to also `Read` any manifest-listed new or renamed file excluded only by a filename glob or `@generated` marker, per the reference's Security profile — these are the spoofable evasion signals.
6. Consolidate findings into one summary (Blockers / Concerns / Advisories / Verdict), and reproduce the **excluded-generated-artifacts manifest** in the summary so the skipped files stay visible.
   - Each reviewer self-applies its own calibration before returning output; the orchestrator does NOT re-classify findings.
   - The orchestrator's job is to: (a) dedupe findings reported by multiple reviewers, (b) preserve the highest severity assigned to any duplicate, (c) attribute each consolidated finding to the reviewers that flagged it, (d) compute the overall verdict (NEEDS WORK if any reviewer has confirmed blockers; CONCERNS REMAIN if only concerns; PASS if all four are clean), (e) preserve each finding's `(spec)`/`(code)` tag verbatim — never re-classify it (when a `[requirements-path]` was provided, `(spec)` findings flag the implementation diverging from it; if duplicate findings carry different tags, keep `(spec)`).

   Each reviewer emits all four sections (Blockers / Concerns / Advisories / Verdict) — empty sections are written as `- None` so the orchestrator's parse stays predictable.

7. Disposition the findings: **Read `references/review-finding-disposition.md` and follow it** — validate each against the actual code, fix **every** valid finding directly (all tiers), skip false positives with a one-line reason, never push, and **do not ask for permission**. The reference covers the validation standard, the report format, and the plan-mode / remote-PR guard clauses.

Pattern: the four reviewers are calibrated for implementation-diff review (real bugs, regression risk, security in code, end-user impact). For plan-document review use `/k0d3:review-plan`.
