# Architecture (one-time orientation)

> This doc is a **one-time orientation** to k0d3's conceptual layout. It is NOT a live reference — for that, see `docs/skill-graph.md` (auto-generated) and `Skill(skill-discovery)` (auto-regenerated routing table). It will not be revised every time a new skill lands.
>
> **Numbers in this doc are aspirational from an earlier phase and may not match the live catalogue.** Use this doc for the _conceptual grouping_; rely on `docs/skill-graph.md` and `ls skills/` for current counts.

## Layout decision: flat skills/, slug-prefixed namespace

Skills sit at one level under `skills/<slug>/SKILL.md`. The slug carries the namespace:

- `go-idioms` lives at `skills/go-idioms/SKILL.md`
- `frontend-tailwind` lives at `skills/frontend-tailwind/SKILL.md`
- `postgres` lives at `skills/postgres/SKILL.md`

**Why flat?** The only proven Claude Code plugin layout (used by `superpowers`, `toolkit`) is one-level-deep `skills/<name>/SKILL.md`. CC's plugin loader behavior at deeper nesting is unknown. The Phase 0 loader spike confirmed this — deeper nesting was tested and rejected; the flat layout is the project's stable choice.

## Conceptual grouping (not directory structure)

The slug prefix encodes the conceptual group:

### Meta (entry points)

- `using-k0d3` — read first; tells Claude what to load for the current task
- `skill-discovery` — auto-regenerated keyword → slug routing table

### Core (cross-cutting process skills)

- Workflow primitives: `brainstorming`, `planning`, `tdd`, `debugging`, `refactoring`, `requirements-gathering`, `code-review`, `root-cause`, `commit-writer`, `pr-description`
- Ported from superpowers: `using-git-worktrees`, `dispatching-parallel-agents`, `subagent-driven-development`, `receiving-code-review`, `finishing-a-development-branch`

### Languages (you write code in)

- `go-*` (8): idioms, concurrency, errors, testing, gin-echo, grpc, generics, modules
- `python-*` (8): idioms, typing, async, testing, packaging, fastapi, django, pydantic
- `ts-*` (6): strict-mode, async, types, testing, node-interop, esm-cjs
- `react-*` (5): hooks, composition, performance, server-components, testing
- `rust-*` (8): ownership, async-tokio, errors, cargo, traits, concurrency, axum-actix, testing
- `gdscript-*` (5): fundamentals, types, signals, performance, godot-api

### Runtimes

- `bun-*` (4), `node-*` (3), `pnpm-*` (4)

### Databases (you talk to)

- `sql-*` (dialect-neutral fundamentals + optimization)
- `postgres-*` (schema, indexes, jsonb, partitioning, replication, 17-features, 18-features)
- `migrations-*` (alembic, sqlx, atlas, goose, drizzle, prisma)
- `orm-*` (sqlx, sqlalchemy, prisma, drizzle)

### Domains (cross-language disciplines)

- `security-*` (7): owasp, sast, secrets, sql-injection, xss, authn-authz, supply-chain
- `code-review-*` (4): silent-failure, type-design, comment-analysis, test-coverage
- `frontend-*` (9): design-tokens, design-systems, figma-to-code, component-architecture, typography, color-systems, tailwind, daisyui, shadcn-ui
- `ux-*` (5): nielsen-heuristics, wcag-a11y, mobile-first, error-messaging, information-architecture
- `architecture-*` (6): gof-patterns, solid, hexagonal, event-driven, cqrs, modular-monolith
- `testing-*` (9): unit, integration, e2e, property-based, mutation, fuzzing, chaos, flake-detection, coverage
- `game-dev-*` (13): godot-scene-system, godot-signals, godot-exports, godot-2d, godot-3d, godot-ui-control, godot-multiplayer, architecture-ecs, state-machines, game-loop, asset-pipelines, physics, audio

### Protocols (you exchange data over)

- `rest-*` (5), `graphql-*` (5), `websocket-*` (3), `unix-socket-*` (3)

### CI (you deploy through)

- `ci-github-actions-*` (5), `ci-gitlab-*` (5)

### Observability + Tooling

- `observability-*` (4): logging, metrics, tracing-otel, sentry
- `tooling-*` (6): git-advanced, shell-fish, jq, ripgrep, fzf, playwright-cli

## Why these groups

1. **One skill per logical use**: each topic owns its skill — `postgres` covers Postgres end-to-end, `react` covers React end-to-end. Chunks of one topic (version-specific feature lists, "advanced" splits) do not get their own skill; they live as sections, or as `references/<topic>-<subtopic>.md` files linked from the parent skill.
2. **Frameworks/libraries are their own skill, but link to the parent language**: `python-django`, `python-fastapi`, `go-grpc`, `ts-zod` each get their own skill — but the body assumes the language skill (`python`, `go`, `typescript`) covers the language. Frameworks reference, they don't duplicate.
3. **Runtimes ≠ Languages**: `bun` and `pnpm` are tooling around JS/TS, not the language itself. Keep `ts-*` for TypeScript semantics; `bun-*` for runtime workflows.
4. **GDScript + Godot split**: `gdscript` is the language; `godot` is the engine. They cross-reference.
5. **Frontend design vs UX**: tokens/systems/Tailwind/shadcn are _frontend design_ (how you build it); accessibility/heuristics/IA are _UX_ (how humans use it). Both link to React.

## Agents

Three cohorts under `agents/`:

- **workflow/** (9): process agents — auditor, unsticker, error-whisperer, rubber-duck, yak-shave-detector, debt-collector, archaeologist, onboarding-sherpa, pr-ghostwriter
- **reviewers/** (4 — collapsed): calibrated multi-perspective — senior-dev, senior-qa, security, end-user (covers both developer-users and non-technical end users in a single review; no role dispatch)
- **experts/** (16): language specialists (go, python, typescript, react, rust, gdscript, postgres) + domain specialists (security-auditor, frontend-designer, ci-cd-expert) + code-quality cohort (code-reviewer, code-simplifier, silent-failure-hunter, comment-analyzer, type-design-analyzer, pr-test-analyzer)

Code-quality cohort agents are read-only (`tools: [Read, Grep, Glob]`).

## Commands

Five categories under `commands/`:

- **workflow/**: `/start /sync /wrap-up /audit /safe-clear /unstick /retro /system-audit /standup /handoff /playbook /update-k0d3`
- **plan/**: `/brief /brainstorm /plan /onboard`
- **execute/**: `/tdd /refactor /migrate /debug /commit /pr /ship /release`
- **review/**: `/review /review-plan /review-impl /security-audit`
- **analyze/**: `/debt-map /drift-detect /report /competitive-intel /test /lint`

## Hooks

11 shell hooks under `hooks/` (10 ported from `~/.shared/hooks/` + 1 new):

- Ported: `backup-before-write`, `block-deferred-issues`, `completeness-gate`, `guard-bash` (with fixes), `log-changes`, `log-failures`, `log-stop-verdict`, `pre-compact-handoff`, `post-compact-resume`, `session-reset`
- New: `validate-skill-frontmatter` (PreToolUse on `/skills/`, fail-open + stderr echo)

All ship disabled-by-default in `hooks/hooks.json`. Enabled one-at-a-time during Phase 6 cutover per the per-hook interleave procedure.

## Hard sequencing

A few hooks have read-after-write dependencies. When enabling during cutover:

- `post-compact-resume` must be live in k0d3 before `session-reset` is moved (session-reset reads what resume wrote).
- `pre-compact-handoff` and `post-compact-resume` are a pair — both should be live together.
- `log-changes` and `log-failures` are independent.
- `backup-before-write` has no dependency.

See `docs/hooks-migration.md` for the full per-hook ordering.
