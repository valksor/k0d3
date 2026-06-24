---
name: using-k0d3
description: Use at session start to orient Claude in a k0d3-enabled repo. Establishes slug convention, prefix rule, navigation, and the one-skill-per-use rule.
metadata:
  added: 2026-05-18
  last_reviewed: 2026-05-25
  type: meta
  status: active
  invokes_shell: false
  shell_reviewed: "valksor 2026-05-17"
  related: [skill-discovery]
---

# Using k0d3

You are working in (or with) k0d3 — valksor's consolidated Claude Code plugin. One skill per logical use — no packs, no multi-chunk splits of a single topic. Single source of truth.

## What to do right now

1. **Slug convention**: every skill is `skills/<slug>/SKILL.md` at one level under `skills/`. Slug is bare for singleton topics (`postgres`, `react`), namespace-prefixed for frameworks under a language (`go-cobra`, `python-django`). No nested directories.
2. **Find the right skill**: invoke `Skill(skill-discovery)` for the keyword → slug routing table.
3. **Live graph**: `docs/skill-graph.md` is auto-generated and reflects current skill relationships.
4. **Architecture orientation**: `docs/architecture.md` is a one-time read explaining the conceptual grouping.

## Prefix rule

Type the explicit `k0d3:` prefix for k0d3 commands, agents, and skills when another installed plugin defines the same name — bare names resolve by plugin load order, so they collide silently:

- `Skill(k0d3:tdd)` not `Skill(tdd)`
- `Agent(k0d3:python-expert)` not `Agent(python-expert)`
- `/k0d3:review` not `/review`

## When to invoke an agent vs a skill

- **Skill**: you need knowledge or a checklist. Skills are read-once context.
- **Agent**: you need an independent perspective with its own tool set and its own brief. Agents dispatch and return findings.

See `AGENTS.md` for the agent catalogue. Three cohorts: `workflow/`, `reviewers/`, `experts/`.

## Default to action — research proportional to the task

Before exploring to learn how to build / test / run / lint / release, **check the obvious entry points first**: `Makefile`, `package.json` scripts, `justfile`, `Taskfile.yml`, `pyproject.toml`, `composer.json`, `README`. The command almost always already exists — reuse it instead of rediscovering it with a grep-and-read sweep.

- Spend research budget proportional to the task. A one-line change doesn't warrant a codebase survey.
- Structural questions (what calls what, where X is defined) go to codegraph — sub-millisecond index reads beat grep+read loops.
- On small, well-scoped tasks, act directly rather than fanning out Explore/Plan agents — they bias toward research by design.
- Writing a concrete reference — env var, path, command, schema, version — into a plan or code? Confirm it exists first (`Skill(verify-before-asserting)`); a name that fits the convention is still a guess.

## Right-size the process — execution ceremony proportional to the stakes

Just as research budget scales to the task (above), so does _execution ceremony_ — how much verification, independent review, and durable logging a change earns. This is the rigor that follows design, not whether to design. Match the tier to the blast radius; **when unsure, round up.**

- 🟢 **Trivial** (typo, rename, local one-liner): execute with minimal ceremony — verification beyond "it builds" is over-process.
- 🟡 **Substantial** (multi-file, reversible, touches no auth/money/data/security/privacy): verify the load-bearing claims and name the biggest weakness before you ship.
- 🔴 **High-stakes** (auth, money, data, security, privacy; hard to undo; long session): spawn an independent reviewer to read ground truth (`Skill(k0d3:code-review)`, or the calibrated `/k0d3:review-impl` / `/k0d3:review-code` flow) and keep a durable progress file.

Two rules hold at every tier:

- **Internal consistency is not correctness.** A clean diff is not evidence it works — run it and observe.
- **Persist deferrals in writing.** A gap that lives only in the conversation is lost the moment the session resets — graduate it to a durable file, not just this reply.

This governs _execution_ rigor only — what you do **after** the design is set. It does **not** relax the `Skill(brainstorming)` design gate: every change still gets a design first, even when that's one sentence stated before acting (Trivial) rather than a written spec.

<!-- Right-sizing tiers adapted from tale-mode (https://github.com/alicicek/tale-mode), MIT. -->

## When something seems missing

If a skill you expect isn't there, check `Skill(skill-discovery)` for the keyword routing table or `ls skills/` for the live catalogue. If still missing, it hasn't been authored yet — `git log skills/` shows when things landed.

## Validator hint

If a write to `skills/**` gets blocked by `validate-skill-frontmatter.sh`:

- **One-shot (preferred)**: `env K0D3_SKIP_VALIDATOR=1 claude` — bypass is logged to `$CLAUDE_PROJECT_DIR/.claude/logs/validator-bypass.log` (auditable). Note: if `CLAUDE_PROJECT_DIR` is unset, the hook still bypasses but cannot write the log; it emits a stderr line instead.
- Persistent disable (last resort — silent, no audit trail): `chmod -x hooks/validate-skill-frontmatter.sh`. **Re-enable immediately** with `chmod +x hooks/validate-skill-frontmatter.sh` after the sweep finishes.

See `docs/conventions.md § Validator bypass` for the full procedure.

## Context health

Sessions have finite context; heavy operations burn it fast. Run `/k0d3:workflow:safe-clear` proactively when you notice any of:

- ~30+ tool calls deep, or after 3+ large file reads;
- a "compacting conversation" warning appears — clear immediately;
- output quality degrades (repetition, dropped details);
- a clean task boundary, before switching to an unrelated task.

**Automatic safety net.** With k0d3's hooks active you also get this for free: `pre-compact-handoff` writes a state marker before auto-compaction and `post-compact-resume` restores it on the next `SessionStart(compact)`; `session-reset` clears stale gate files on each fresh `startup`. `safe-clear` is the _deliberate_ version you trigger yourself before quality slips.
