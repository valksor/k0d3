# k0d3 — Claude session guide

k0d3 is valksor's consolidated Claude Code plugin: skills, agents, commands, and hooks in one place. It supersedes `~/.shared/`, `toolkit`, `pr-review-toolkit`, `code-simplifier`, and (after Phase 6 cutover) `superpowers`. Single source of truth.

## Required action at session start

**Invoke `Skill(using-k0d3)` immediately.** It chains the meta-skills needed to navigate this repo and tells you which skills to load for the current task.

## Slug convention

- Every skill is `skills/<slug>/SKILL.md` at **one level** under `skills/` (no nested dirs).
- Slug is globally unique, kebab-case (`go-idioms`, `frontend-tailwind`, `postgres`).
- Slug == directory name, always.
- Cross-references between skills use the slug, not paths: `metadata.related: [tdd, debugging]`.

## Navigation

- **First-time orientation**: read `docs/architecture.md` (the conceptual grouping behind the flat slug namespace).
- **Live skill graph**: `docs/skill-graph.md` (auto-generated Mermaid). Open it for an up-to-date view of skills + their `related:` edges.
- **Topic → skills routing**: `Skill(skill-discovery)` returns a keyword table you can scan.
- **Per-skill body cap**: ~200 lines. Long-form lives in `references/<topic>.md`.

## Coexistence rule (Phases 1–5)

While k0d3 is being built alongside the existing plugins, **always type the explicit `k0d3:` prefix** for k0d3 commands, agents, and skills:

```
✅ /k0d3:review        Skill(k0d3:tdd)        Agent(k0d3:python-expert)
❌ /review             Skill(tdd)             Agent(python-expert)
```

Bare names are ambiguous — Claude Code resolves by load order. No in-session warning exists for this; discipline is yours. After Phase 6 cutover the old plugins are uninstalled and the prefix becomes optional.

## Recommended tool permissions

For a session working in this repo:

- `Skill` — always
- `Agent` — always
- `Read`, `Edit`, `Write` — always
- `Bash` — yes, but most skills don't need it; review agents (code-reviewer, silent-failure-hunter, comment-analyzer, type-design-analyzer, pr-test-analyzer) explicitly drop Bash and are read-only

## Validator bypass (emergency)

If `validate-skill-frontmatter.sh` blocks a needed write:

- **One-shot (preferred)**: `env K0D3_SKIP_VALIDATOR=1 claude` — bypass is logged to `.claude/logs/validator-bypass.log` (auditable).
- Per-session (fish): `set -x K0D3_SKIP_VALIDATOR 1` then launch Claude Code in that shell — same audit-trail behavior.
- Persistent disable (last resort, no audit trail): `chmod -x hooks/validate-skill-frontmatter.sh` — re-enable immediately afterwards.

See `docs/conventions.md § Validator bypass` for the full procedure.

## Where to file things

| You're working on…                   | Goes in…                                                      |
| ------------------------------------ | ------------------------------------------------------------- |
| A new domain-agnostic skill          | `skills/<slug>/SKILL.md`                                      |
| Long-form reference material         | `references/<topic>.md`, linked from the skill                |
| A new agent persona                  | `agents/{workflow,reviewers,experts}/<name>.md`               |
| A new slash command                  | `commands/<category>/<name>.md`                               |
| A bundled MCP server                 | `.mcp.json` at the repo root (auto-enabled on install)        |
| Borrowed content credit              | one line in `docs/borrowed-from.md`                           |
| Build decisions / structural choices | `docs/architecture.md` (one-time orientation; rarely revised) |
