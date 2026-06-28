# Using k0d3 with OpenAI Codex CLI

k0d3 runs in **both** Claude Code and OpenAI Codex CLI from one repo. Claude Code installs it as a plugin via the Claude marketplace; Codex installs the **same** `skills/` and MCP servers as a Codex plugin. This is additive — nothing about the Claude Code experience changes.

## Install (Codex)

```bash
# 1. Register the k0d3 marketplace (local checkout, or the git repo pinned to a tag)
codex plugin marketplace add valksor/k0d3 --ref v0.1.30      # git, tag-pinned (recommended)
# or, from a local clone:
codex plugin marketplace add /path/to/k0d3

# 2. Install the plugin
codex plugin add k0d3@valksor-k0d3

# 3. (Optional) install the hooks — see "Hooks" below
/path/to/k0d3/scripts/install-codex-hooks.sh
```

Verify:

```bash
codex plugin list | grep k0d3        # -> k0d3@valksor-k0d3  installed, enabled
```

> Always pin the git marketplace to a released tag (`--ref vX.Y.Z`), never to a moving branch — the install vendors whatever the ref points at.

## First use

Open `codex` in any project. k0d3's skills are now discoverable:

- **Implicitly** — Codex loads a skill on its own when your task matches the skill's `description`. Just describe what you want ("write a table-driven Go test", "review this for SQL injection").
- **Explicitly** — type `/` for the slash menu and browse `prompts:`/skills, or reference a skill by name with `$<slug>` (e.g. `$go-testing`, `$security`).

There is **no `k0d3:` prefix** in Codex (that is a Claude Code plugin-namespacing concept). Skills are addressed by their bare slug.

## What rides the plugin vs. what you install separately

| Surface | Codex delivery |
|---|---|
| **Skills** (143) | Plugin. The same `skills/<slug>/SKILL.md` Claude uses. Codex only reads `name`+`description`; the `metadata:` block is ignored. |
| **MCP servers** (4) | Plugin, via `.mcp.codex.json` (context7, memory, sequential-thinking, codegraph). |
| **Agents / commands** | Reframed as skills (Codex plugins don't bundle subagents or slash-commands). |
| **Hooks** | **Separate installer.** The plugin's Codex manifest points its `hooks` field at an empty file, so the plugin ships no plugin-channel hooks; they install separately (the scripts need a project-dir env that only the installer's shim provides). See below. |

## Hooks

Codex no longer lets a plugin ship hooks, so k0d3 installs them at the user or project level:

```bash
scripts/install-codex-hooks.sh            # global  -> ~/.codex/hooks.json
scripts/install-codex-hooks.sh --project  # project -> ./.codex/hooks.json
scripts/install-codex-hooks.sh --dry-run  # preview, write nothing
scripts/install-codex-hooks.sh --uninstall
```

The installer derives the wiring from the single source of truth (`hooks/hooks.json`), routes every hook through `codex-hooks-shim.sh` (which synthesizes the `CLAUDE_PROJECT_DIR`/`CLAUDE_PLUGIN_ROOT` env vars the scripts expect), and **merges** into any existing `hooks.json` without clobbering your own hooks (re-runs are idempotent; uninstall removes only k0d3's entries).

After installing, run `codex`, open `/hooks`, and **trust** them through the normal review flow. Do **not** use `--bypass-hook-trust`.

## What you lose in Codex (vs. Claude Code)

- **`ExitPlanMode` review gate** — Codex has no plan-mode hook (it uses `permission_mode: "plan"`). The `review-plan-before-exit` gate is Claude-only.
- **`PostToolUseFailure` audit trail** — Codex has no equivalent event, so `log-failures.sh` (the `.claude/logs` failure log) does not run.
- **Parallel reviewers** — `/review-impl` etc. dispatch four isolated subagents *in parallel* on Claude. A skill can't spawn isolated parallel subagents, so the Codex equivalent runs **sequentially in-session**. Same perspectives, one pass.
- **Stop / SubagentStop hooks** (`verify-before-stop`, `log-stop-verdict`) — excluded from the Codex install. Codex's Stop hook output schema (`deny_unknown_fields`) accepts only universal fields: `continue` (bool), `stopReason` (string), `suppressOutput` (bool), `systemMessage` (string). The k0d3 hooks output `{"decision":"block","reason":"..."}` (Claude Code format); Codex rejects both fields as unknown and raises "hook returned invalid stop hook JSON output". The async `log-stop-verdict.sh` logger is also excluded — its `CLAUDE_PROJECT_DIR` guard makes it a conditional no-op in Codex anyway, but since session-end telemetry would silently stop writing if that var happens to be set, it is cleaner to drop the whole Stop event. **Upgrade note**: if you installed k0d3 Codex hooks before this fix, re-run `scripts/install-codex-hooks.sh` — the updated installer strips stale Stop/SubagentStop entries from your `~/.codex/hooks.json` on re-install. **Writing your own Codex Stop hook**: use the universal schema — e.g., to block: `jq -n --arg r "$reason" '{continue: false, stopReason: $r}'`; see `hooks/verify-before-stop.sh` for the transcript-scanning, single-fire pattern to adapt. Note: Codex Stop events include `stop_hook_active`, so the loop-backstop pattern in k0d3 hooks functions correctly if adapted.
- **Claude-only `.mcp.json` keys** — `alwaysLoad` (codegraph eager-load) is a Claude concept; the Codex MCP manifest (`.mcp.codex.json`) omits it.

## Maintainer notes

- **Two manifests, one version.** `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `.codex-plugin/plugin.json` are version-bumped together by `.github/workflows/version-bump.yml`, which hard-fails if any drifts.
- **MCP format differs.** Claude's `.mcp.json` uses `"type":"stdio"`; Codex's `.mcp.codex.json` omits `type` for stdio servers and resolves the memory path at runtime via `hooks/start-memory.sh`. Keep both files in sync when adding/removing a server.
- **Strict JSON, no inline comments.** Codex's plugin parsers reject unknown top-level keys. `hooks/hooks.json` must stay a bare `{"hooks": {…}}` (its `_comment` + `_disabled_examples` live in `hooks/hooks.examples.json`; see `docs/hooks.md`), and `.mcp.codex.json` carries no `_comment`. The plugin's Codex manifest points `hooks` at `.codex-plugin/no-plugin-hooks.json` (empty) so Codex auto-loads no plugin-channel hooks — they come via `scripts/install-codex-hooks.sh`, whose shim sets the `CLAUDE_PROJECT_DIR` the scripts need (Codex sets `CLAUDE_PLUGIN_ROOT` for plugin hooks but not `CLAUDE_PROJECT_DIR`). `scripts/test-codex.sh` guards all of this.
- **CI.** `scripts/test-codex.sh` (run by the `mcp-guard` workflow) validates the manifests, version sync, MCP shape, the derived hooks JSON, and that `guard-bash` denies a dangerous command through the shim.
- **Supply chain.** The four MCP servers are unpinned `npx` packages (a deliberate, documented choice — see `docs/architecture.md § Bundled MCP servers`). Codex widens that audience; revisit pinning if that changes the calculus.
