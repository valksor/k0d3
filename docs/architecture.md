# Architecture (one-time orientation)

> This doc is a **one-time orientation** to k0d3's conceptual layout. It is NOT a live reference — for that, see `docs/skill-graph.md` (auto-generated) and `Skill(skill-discovery)` (auto-regenerated routing table). It will not be revised every time a new skill lands.
>
> **Counts here are illustrative and may not match the live catalogue.** Use this doc for the _conceptual grouping_; rely on `docs/skill-graph.md` and `ls skills/` for current counts.

## Layout decision: flat skills/, slug-prefixed namespace

Skills sit at one level under `skills/<slug>/SKILL.md`. The slug carries the namespace:

- `go-idioms` lives at `skills/go-idioms/SKILL.md`
- `frontend-tailwind` lives at `skills/frontend-tailwind/SKILL.md`
- `postgres` lives at `skills/postgres/SKILL.md`

**Why flat?** The proven Claude Code plugin layout is one-level-deep `skills/<name>/SKILL.md`. CC's plugin loader behavior at deeper nesting is unsupported, so k0d3 keeps every skill flat.

## Conceptual grouping (not directory structure)

The slug prefix encodes the conceptual group:

### Meta (entry points)

- `using-k0d3` — read first; tells Claude what to load for the current task
- `skill-discovery` — auto-regenerated keyword → slug routing table

### Core (cross-cutting process skills)

- Workflow primitives: `brainstorming`, `planning`, `tdd`, `debugging`, `refactoring`, `requirements-gathering`, `code-review`, `root-cause`, `commit-writer`, `pr-description`
- Collaboration & isolation: `using-git-worktrees`, `dispatching-parallel-agents`, `subagent-driven-development`, `receiving-code-review`, `finishing-a-development-branch`

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

Shell hooks under `hooks/`:

- `backup-before-write`, `block-deferred-issues`, `completeness-gate`, `guard-bash`, `log-changes`, `log-failures`, `log-stop-verdict`, `pre-compact-handoff`, `post-compact-resume`, `session-reset`
- `validate-skill-frontmatter` — PreToolUse on `/skills/`, fail-open + stderr echo

Most ship enabled by default in `hooks/hooks.json`; the repo-development-specific ones are opt-in. See `docs/hooks.md` for the per-hook enable order and rollback.

## Hard sequencing

A few hooks have read-after-write dependencies. When enabling the opt-in hooks:

- `post-compact-resume` must be live in k0d3 before `session-reset` is moved (session-reset reads what resume wrote).
- `pre-compact-handoff` and `post-compact-resume` are a pair — both should be live together.
- `log-changes` and `log-failures` are independent.
- `backup-before-write` has no dependency.

See `docs/hooks.md` for the full per-hook ordering.

## Bundled MCP servers

k0d3 ships two MCP servers, declared in the top-level `.mcp.json` (the conventional location for plugin-bundled servers; preferred over inlining `mcpServers` in `plugin.json`, and it stays clear of the `version-bump.yml` CI step, which only touches `plugin.json`'s `version` field). Plugin-bundled servers auto-enable on install with no approval prompt — stdio and HTTP alike.

- **context7** — Upstash's hosted library-docs service, over **remote HTTP** (`https://mcp.context7.com/mcp`).
- **memory** — the official `@modelcontextprotocol/server-memory`, a **local stdio** server (`npx -y @modelcontextprotocol/server-memory@<pinned>`). Gives Claude a persistent knowledge graph (entities, observations, relations) across sessions. Storage is **project-local and self-initializing**: `MEMORY_FILE_PATH` points at `${CLAUDE_PROJECT_DIR}/.claude/memory.jsonl`, so each project gets its own store under the (gitignored) `.claude/`. **Zero external service** — no network, no embeddings, no API key.

**On bundling a stdio server.** The rule isn't about transport: **bundle a server iff it can start and return a valid (if empty) response with zero pre-installed _project_ artifacts.** codegraph fails that test — it needs a locally-installed binary _and_ a pre-built per-repo index, so it errors or no-ops wherever either is missing. The memory server passes it: `npx` fetches the code on first use (cached after) and it self-initializes its store per project. The accepted costs — a Node/`npx` prerequisite and a one-time first-run download — are tolerable for a capability that fails soft (Node absent or an offline first run just means the server doesn't start) and is opt-out via `/mcp`.

Two operational notes. (1) The server self-initializes its store _file_ but **not** the parent directory — a write to a missing `.claude/` returns `ENOENT`. k0d3's `ensure-memory-gitignore` SessionStart hook guarantees `.claude/` exists and adds `memory.jsonl` to `.claude/.gitignore`, since the store is plaintext and must never be committed. (2) Unlike context7 (HTTP, no local code), a bundled stdio server auto-runs local code on every install — and npm version tags are not immutable. The pin is therefore vetted by `scripts/check-mcp-pin.sh` (CI plus a weekly schedule), which asserts the published tarball integrity still matches the vetted value; bumping the pin is a deliberate step that updates that expected hash. The trust basis for auto-enabling is that the package is the official, Anthropic-maintained `@modelcontextprotocol/server-memory`.

The context7 API key is per-user, never committed: `.mcp.json` references `${CONTEXT7_API_KEY:-}`. The `:-` empty default is load-bearing — Claude Code refuses to start a server that references an unset variable with no default, so the fallback is what keeps anonymous (keyless) use working. (The memory server needs no such default: plugin-bundled `.mcp.json` may reference `${CLAUDE_PROJECT_DIR}` directly, since Claude Code always sets it.)
