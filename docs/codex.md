# Using k0d3 with OpenAI Codex CLI

k0d3 runs in **both** Claude Code and OpenAI Codex CLI from one repo. Claude Code installs it as a plugin via the Claude marketplace; Codex installs the **same** `skills/`, MCP servers, **and hooks** as a Codex plugin. This is additive — nothing about the Claude Code experience changes.

> **Upgrading from an older k0d3?** If you ever ran `scripts/install-codex-hooks.sh` to install hooks into `~/.codex/hooks.json`, run **`scripts/install-codex-hooks.sh --uninstall` once, before upgrading the plugin** (the plugin hooks go live the moment `codex plugin add`/`upgrade` completes, so removing the old copy first avoids any double-fire window). k0d3 now ships hooks through the plugin channel; leaving the old out-of-band copy in place makes every hook **double-fire**, and the stale `verify-before-stop.sh` re-emits the old `{decision,reason}` Stop schema that Codex rejects (`hook returned invalid stop hook JSON output`). See [Hooks](#hooks).

## Install (Codex)

```bash
# 1. Register the k0d3 marketplace (local checkout, or the git repo pinned to a tag)
codex plugin marketplace add valksor/k0d3 --ref v0.1.30      # git, tag-pinned (recommended)
# or, from a local clone:
codex plugin marketplace add /path/to/k0d3

# 2. Install the plugin (skills + MCP + hooks all ride the plugin)
codex plugin add k0d3@valksor-k0d3

# 3. Trust the hooks
codex            # then run /hooks, review the k0d3 entries, and trust them
```

Verify:

```bash
codex plugin list | grep k0d3        # -> k0d3@valksor-k0d3  installed, enabled
codex                                # /skills lists k0d3 slugs; /hooks shows k0d3 hooks
```

> Always pin the git marketplace to a released tag (`--ref vX.Y.Z`), never to a moving branch — the install vendors whatever the ref points at.

## First use

Open `codex` in any project. k0d3's skills are now discoverable:

- **Explicitly** — type `/` for the slash menu and browse skills, or reference a skill by name with `$<slug>` (e.g. `$go-testing`, `$security`).
- **Implicitly** — Codex may load a skill on its own when your task matches the skill's `short_description`. (Implicit auto-trigger depends on Codex honoring `allow_implicit_invocation`, which k0d3 does not yet set — explicit `$slug` always works.)

There is **no `k0d3:` prefix** in Codex (that is a Claude Code plugin-namespacing concept). Skills are addressed by their bare slug.

## What rides the plugin

| Surface               | Codex delivery                                                                                                                                                                                                                                                                                                           |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Skills** (144)      | Plugin, via `skills/<slug>/`. Codex surfaces each skill from a generated **`skills/<slug>/agents/openai.yaml`** (`interface.display_name` / `short_description` / `default_prompt`), produced from the `SKILL.md` frontmatter by `scripts/generate-codex-skill-manifests.sh`. The instructions still live in `SKILL.md`. |
| **MCP servers** (4)   | Plugin, via `.mcp.codex.json` (context7, memory, sequential-thinking, codegraph).                                                                                                                                                                                                                                        |
| **Agents / commands** | Reframed as skills (Codex plugins don't bundle subagents or slash-commands).                                                                                                                                                                                                                                             |
| **Hooks**             | Plugin, via **`hooks/hooks.codex.json`** (generated from `hooks/hooks.json` by `scripts/generate-codex-hooks.sh`, referenced by `.codex-plugin/plugin.json`). Trust them with `/hooks`.                                                                                                                                  |

## Hooks

Current Codex supports plugin-channel hooks, so k0d3 ships them **in the plugin**. The manifest's `hooks` field points at `hooks/hooks.codex.json`, generated from the single source of truth (`hooks/hooks.json`) by `scripts/generate-codex-hooks.sh`. Each command is routed through `codex-hooks-shim.sh`, which synthesizes `CLAUDE_PROJECT_DIR` (Codex sets `CLAUDE_PLUGIN_ROOT` for plugin hooks but not the project dir) and exports `K0D3_HOST=codex` so dual-emit hooks pick the Codex output schema. Paths use `${CLAUDE_PLUGIN_ROOT}` and are quoted to survive spaces in the plugin cache path.

After installing/upgrading the plugin, run `codex`, open `/hooks`, and **trust** the k0d3 hooks through the normal review flow. Do **not** use `--bypass-hook-trust`. Per-hook trust is additive — your own hooks are untouched.

The Codex derivation drops what Codex doesn't support and keeps the rest:

- **Dropped:** `PostToolUseFailure` (no such Codex event), the `ExitPlanMode` PreToolUse matcher (no Codex plan-mode hook), and the async-only telemetry hooks `log-changes.sh` / `log-stop-verdict.sh` (Codex has no async hooks; running them synchronously on every write adds latency). `async` keys are stripped everywhere.
- **Kept, including `Stop`/`SubagentStop`:** `verify-before-stop.sh` dual-emits — Codex's `deny_unknown_fields` Stop schema accepts only the universal fields (`continue`, `stopReason`, `suppressOutput`, `systemMessage`), so under `K0D3_HOST=codex` it emits `{"continue": false, "stopReason": "…"}` instead of Claude's `{"decision": "block", "reason": "…"}`. The `stop_hook_active` loop backstop (which Codex sets) keeps it single-fire.

`scripts/install-codex-hooks.sh` is now a **migration/uninstaller only** — run it with `--uninstall` to remove a prior out-of-band install. A bare invocation prints a deprecation notice and exits non-zero.

## What you lose in Codex (vs. Claude Code)

- **`ExitPlanMode` review gate** — Codex has no plan-mode hook (it uses `permission_mode: "plan"`). The `review-plan-before-exit` gate is Claude-only.
- **`PostToolUseFailure` audit trail** — Codex has no equivalent event, so `log-failures.sh` (the `.claude/logs` failure log) does not run.
- **Async telemetry** — `log-changes.sh` and `log-stop-verdict.sh` are excluded because Codex has no async-hook support and running them synchronously would add per-event latency.
- **Parallel reviewers** — `/review-impl` etc. dispatch four isolated subagents _in parallel_ on Claude. A skill can't spawn isolated parallel subagents, so the Codex equivalent runs **sequentially in-session**. Same perspectives, one pass.
- **Claude-only `.mcp.json` keys** — `alwaysLoad` (codegraph eager-load) is a Claude concept; the Codex MCP manifest (`.mcp.codex.json`) omits it.

**Writing your own Codex Stop hook:** use the universal schema — to block: `jq -n --arg r "$reason" '{continue: false, stopReason: $r}'`; see `hooks/verify-before-stop.sh` for the transcript-scanning, single-fire, dual-emit pattern to adapt.

## Maintainer notes

- **Two manifests, one version.** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `.codex-plugin/plugin.json` are version-bumped together by `.github/workflows/version-bump.yml`, which hard-fails if any drifts.
- **Generated artifacts — never hand-edit.** `hooks/hooks.codex.json` ← `scripts/generate-codex-hooks.sh` (from `hooks/hooks.json`); `skills/*/agents/openai.yaml` ← `scripts/generate-codex-skill-manifests.sh` (from each `SKILL.md`). Both have a `--check` mode (re-derive + diff) that `scripts/test-codex.sh` runs, and both are regenerated by the pre-commit hook (`scripts/install-git-hooks.sh`). Edit the source, not the output.
- **MCP format differs.** Claude's `.mcp.json` uses `"type":"stdio"`; Codex's `.mcp.codex.json` omits `type` for stdio servers and resolves the memory path at runtime via `hooks/start-memory.sh`. Keep both files in sync when adding/removing a server.
- **Strict JSON, no inline comments.** Codex's plugin parsers reject unknown top-level keys. `hooks/hooks.json` must stay a bare `{"hooks": {…}}` (its `_comment` + `_disabled_examples` live in `hooks/hooks.examples.json`; see `docs/hooks.md`), and `.mcp.codex.json` carries no `_comment`. The same applies to the generated `hooks/hooks.codex.json` — which is why the "don't hand-edit" marker is enforced by the `--check` byte-diff, not an in-file key.
- **CI.** `scripts/test-codex.sh` (run by the `mcp-guard` workflow) validates the manifests, version sync, MCP shape, the generated hooks (in-sync, Codex-unsupported events/keys dropped, Stop/SubagentStop kept, every command shimmed + `${CLAUDE_PLUGIN_ROOT}`), the skill manifests (in-sync, valid `interface`), that `guard-bash` denies a dangerous command through the shim, that the shim fails closed on a bad delegate, and that `verify-before-stop.sh` dual-emits per host with a working backstop. The workflow's `paths:` filter includes the generators and `skills/**/agents/openai.yaml`.
- **Supply chain.** The four MCP servers are unpinned `npx` packages (a deliberate, documented choice — see `docs/architecture.md § Bundled MCP servers`). Codex widens that audience; revisit pinning if that changes the calculus.
