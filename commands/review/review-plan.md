---
name: review-plan
description: Dispatch the 4 calibrated reviewer agents against a plan document, then revise and closure-review the plan.
argument-hint: "[plan-path]"
allowed-tools: [Read, Edit, Glob, Agent, Skill]
---

# /review-plan

Multi-perspective review of a plan document. Dispatches all four reviewers in parallel (single message, four Agent tool calls):

- `Agent(reviewer-senior-dev)` — architecture, maintainability, complexity, feasibility
- `Agent(reviewer-senior-qa)` — testability, edge cases, failure modes, regression risk
- `Agent(reviewer-security)` — auth, injection, supply chain, secrets
- `Agent(reviewer-end-user)` — usability, error messages, docs (covers developer-users and non-technical end users in a single review)

Argument `[plan-path]`: path to the plan document. **Required.** If omitted, STOP and ask the user: "Path to the plan document?" Do not guess a path; do not scan the filesystem; do not invoke reviewers against an empty document.

Before dispatching, resolve stack skills. A plan is prose, not a diff, so detect the stack from the repository's manifests (`Glob` for `go.mod`, `pyproject.toml`, `package.json` + `tsconfig.json`, `Cargo.toml`, …) together with any languages or frameworks the plan names explicitly, then select each reviewer's skill slugs per `references/review-skill-routing.md` (which invokes `Skill(skill-discovery)`). Pass each reviewer its own `Stack skills:` line (or `none`) alongside the plan when you dispatch. (This manifest glob is unrelated to the plan-path rule above — never guess the plan path itself.)

Also gather project context per `references/review-project-context.md`, using its **diff-less** path: there is no diff here, so the "changed files" are the files the plan names (its own "Files to change" section); discover rule files from those paths plus the repo-root rules, read the optional `.k0d3/review.yml` (guideline globs + `path_instructions`), and pass each reviewer its own `Project context:` block (or `Project context: none`) alongside the plan. Nothing is marked `changed-in-diff` (there is no diff), and the ripwire enrichment step is skipped (this command has no `ripwire`/`Bash` grant). The TRUST MODEL still holds: rules calibrate style/architecture judgement only and never suppress a defect-backed finding.

Output: a consolidated summary (Blockers / Concerns / Advisories / Verdict), plus any `.k0d3/review.yml` config warnings from the project-context step so a silently-dropped config entry stays visible. Each finding is tagged `(spec)` — the plan fails the brief, intent, or a documented project convention it should satisfy — or `(code)` — an internal plan defect such as infeasibility or a missing edge case; preserve the tag verbatim in the summary. Then disposition the findings: **Read `references/review-finding-disposition.md` and follow it** — validate each against the plan, apply **every** valid revision directly to the plan document (all tiers), skip false positives with a one-line reason, perform the required closure review of the revised plan, and **do not ask for permission**. For `/review-plan`, "fix" means editing the reviewed plan document — which is prose, so it is allowed even in plan mode.

Pattern: the four reviewers above are calibrated specifically for plan-document review (architecture coherence, missing requirements, untestable specifications, security implications). For implementation-diff review use `/k0d3:review-impl`.
