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
- `rust-*` (8+): ownership, async-tokio, errors, cargo, traits, concurrency, axum-actix, testing, cli
- `php-*` (6): essentials, composer, symfony, doctrine, testing, quality (FrankenPHP app server → `infra-frankenphp`; Twig depth → `references/twig.md`)
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
- `verify-before-stop` — Stop + SubagentStop, blocks once on a detected failure so the agent can't claim "done" over a wall (companion skill: `honest-completion`)
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

k0d3 ships four MCP servers, declared in the top-level `.mcp.json` (the conventional location for plugin-bundled servers; preferred over inlining `mcpServers` in `plugin.json`, and it stays clear of the `version-bump.yml` CI step, which only touches `plugin.json`'s `version` field). Plugin-bundled servers auto-enable on install with no approval prompt — stdio and HTTP alike.

- **context7** — Upstash's hosted library-docs service, over **remote HTTP** (`https://mcp.context7.com/mcp`).
- **memory** — the official `@modelcontextprotocol/server-memory`, a **local stdio** server (`npx -y @modelcontextprotocol/server-memory`). Gives Claude a persistent knowledge graph (entities, observations, relations) across sessions. Storage is **project-local and self-initializing**: `MEMORY_FILE_PATH` points at `${CLAUDE_PROJECT_DIR}/.claude/memory.jsonl`, so each project gets its own store under the (gitignored) `.claude/`. **Zero external service** — no network, no embeddings, no API key.
- **sequential-thinking** — the official `@modelcontextprotocol/server-sequential-thinking`, a **local stdio** server (`npx -y @modelcontextprotocol/server-sequential-thinking`). A structured reasoning scratchpad: Claude logs revisable, branchable thought steps through one `sequentialthinking` tool. **Stateless** — no store, no env, no API key, and so (unlike memory) it needs no gitignore hook. It overlaps with Opus's native extended thinking; the value is the inspectable branch/revise workflow and parity with non-thinking models. Opt-out via `/mcp`.
- **codegraph** — a **third-party** local **stdio** server (`npx -y @colbymchenry/codegraph serve --mcp`, from `@colbymchenry/codegraph`). A pre-indexed code knowledge graph — symbols, edges, callers/callees, impact — exposed as `codegraph_*` tools so structural queries replace grep/file-scans. **Self-contained**: it bundles its own Node runtime (no native build), needs no account, and no network beyond the one-time `npx` fetch. `alwaysLoad: true` keeps its tools eagerly loaded (not deferred behind tool-search) so the agent actually reaches for them instead of defaulting to grep. Its one extra requirement — a per-repo index — is provisioned in the background by the `codegraph-autoindex` SessionStart hook (below); until that finishes a tool call returns "not initialized", i.e. it fails soft.

**On bundling a stdio server.** The rule isn't about transport — and isn't that a server must be useful with zero setup. It's about **prerequisites we refuse to impose**: a bundled server must need **no third-party account and no local language toolchain (rust/go/etc.)**. Running `npx`/`curl` to fetch a self-contained package is fine, as is a one-time first-run download. All four pass: context7 is hosted HTTP; memory and sequential-thinking are self-contained `npx` packages; codegraph is likewise self-contained (it bundles its own Node — no native build, no account). codegraph's one extra need — a per-repo index — is a _project_ artifact, but k0d3 provisions it itself via the `codegraph-autoindex` SessionStart hook (background, fail-soft), exactly as `ensure-memory-gitignore` provisions memory's parent dir. Everything still **fails soft**: no Node, an offline first run, or a not-yet-built index just means empty/fewer results, never a hard failure — and all are opt-out via `/mcp`.

Three operational notes. (1) The server self-initializes its store _file_ but **not** the parent directory — a write to a missing `.claude/` returns `ENOENT`. k0d3's `ensure-memory-gitignore` SessionStart hook guarantees `.claude/` exists and adds `memory.jsonl` to `.claude/.gitignore`, since the store is plaintext and must never be committed. (2) The bundled stdio servers are **unpinned** — `.mcp.json` names each package with no version, so `npx` resolves the npm `latest` tag on the user's machine. This keeps a codegraph (or memory / sequential-thinking) upstream release flowing to users without a k0d3 commit, and avoids the churn where a pin bump auto-cut a user-facing k0d3 release. The trade-off is accepted deliberately: pinning never gated an end user's install (`npx` fetches whatever npm serves, with no lockfile hash check), so the integrity machinery it required only ever served as a CI tripwire for republished tarballs — and that tripwire is gone. The health control is instead a per-server **smoke test** (`scripts/smoke-mcp-memory.sh`, `scripts/smoke-mcp-sequentialthinking.sh`, `scripts/smoke-mcp-codegraph.sh`) that drives a real MCP session and asserts each server launches and answers; the `mcp-guard` workflow runs these on push and on a **daily** schedule, so an upstream `latest` that breaks launch is caught as a canary before users hit it. Be precise about what this buys: the smoke is a **liveness** check, not a trust/integrity one — it proves a server still launches and advertises its tools, **not** that its code is safe, so a malicious-but-functional `latest` would pass it. Unpinning therefore deliberately trades away integrity detection; nothing replaces it. The remaining trust basis is provenance, not a control: memory and sequential-thinking are the official, Anthropic-maintained `@modelcontextprotocol/*` servers; codegraph is third-party (`@colbymchenry/codegraph`, a single maintainer) and self-contained. (One inherent consequence of unpinning: `npx -y <name>` may reuse a cached older `latest` until it refetches, so a machine can lag the newest release briefly.) (3) codegraph's `serve --mcp` serves an index but never builds one; the `codegraph-autoindex` SessionStart hook runs `codegraph init -i` / `index` in a detached background process when a git repo has source but no `.codegraph/`, so session start never blocks. codegraph's own `.codegraph/.gitignore` (written by `init`) ignores only the index **data** (`*.db`, `cache/`, `*.log`), leaving `.codegraph/config.json` and the `.gitignore` itself committable — so on its own `.codegraph/` is only _partially_ ignored. The `codegraph-autoindex` hook therefore adds `.codegraph/` to the repo's `.git/info/exclude` (repo-local, never committed), which keeps the **entire** directory out of git regardless of init success. Thus, unlike memory, codegraph needs no separate gitignore hook.

**Why a knowledge graph, not markdown-as-source-of-truth.** The memory server keeps its data as a JSONL knowledge graph, and the human-readable narrative lives separately in `.claude/memory.md` / `knowledge-base.md` — so k0d3's memory is _two_ stores: one queryable, one readable. A single markdown-as-source-of-truth design (markdown notes that are themselves the queryable store, e.g. via an FTS index — the model used by [Hearth](https://github.com/Tushar4059x/Hearth)) would unify the two and make the store git-versionable, human-readable, and ranked-searchable at once. k0d3 keeps the official `@modelcontextprotocol/server-memory` because its trust basis is Anthropic maintenance, it makes zero network calls, uses no embeddings, and writes plaintext that is already inspectable. Swapping to a markdown-source-of-truth server (`hearth-mcp`) is feasible under the bundling rule above (self-contained `npx`, no account, no toolchain) but trades that provenance for a single-maintainer v0.1 package; reconsider it when such a server reaches a stable 1.x with broader maintenance. Separately, the `project-memory` skill defines a consistent note taxonomy and `/drift-detect` checks memory-corpus consistency — the parts of this model that need no new server.

The context7 API key is per-user, never committed: `.mcp.json` references `${CONTEXT7_API_KEY:-}`. The `:-` empty default is load-bearing — Claude Code refuses to start a server that references an unset variable with no default, so the fallback is what keeps anonymous (keyless) use working. (The memory server needs no such default: plugin-bundled `.mcp.json` may reference `${CLAUDE_PROJECT_DIR}` directly, since Claude Code always sets it.)
