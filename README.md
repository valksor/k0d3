# k0d3

valksor's consolidated Claude Code skills, agents, commands, and hooks. Single source of truth — replaces the legacy `~/.shared/`, `toolkit`, `pr-review-toolkit`, `code-simplifier`, and `superpowers` plugin sprawl. Zero plugin dependencies.

## Install

```bash
# From GitHub (once the repo is published)
/plugin marketplace add valksor/k0d3
/plugin install k0d3@valksor
```

For local development on the plugin itself:

```bash
# Replace /path/to/k0d3 with your local checkout path
/plugin marketplace add /path/to/k0d3
/plugin install k0d3@local
```

After install, in any Claude Code session, type `Skill(k0d3:using-k0d3)` as a message in the chat (not a slash command). Claude Code's Skill tool loads the named skill into context.

## Dependencies

- **Python 3** — all data-heavy validation lives in Python helpers under `scripts/_*.py`. Install via your package manager (`brew install python@3`, `apt install python3`). macOS Sequoia and later don't ship `python3` by default outside Xcode tooling.
- **PyYAML** (Python) — required by the lint/smoke/skill-graph scripts. Install with `pip install pyyaml`. The scripts use `yaml.safe_load()` only — never `yaml.load()` — so the historical PyYAML deserialization CVEs do not apply.
- **jq** — used by hooks for JSON parsing. Install via your package manager (`brew install jq`, `apt install jq`).
- **bash 3.2+** — the project targets the macOS system bash, so hooks and scripts avoid bash 4+ features (associative arrays, `mapfile`).

## Coexistence

While k0d3 sits alongside the legacy plugins (Phases 1–5), **always type the explicit `k0d3:` prefix** for k0d3 commands, agents, and skills. Bare `/review` is ambiguous and Claude resolves by plugin load order. Once the legacy plugins are uninstalled (Phase 6), the prefix becomes optional. See `CLAUDE.md`.

**What "Phase 6" means**: the cutover point at which the legacy plugins (listed below) are uninstalled and k0d3 is the sole installed plugin in your Claude Code config. Walk-through in `docs/hooks-migration.md`.

## Supersession matrix

| Legacy plugin                                 | What it does                                                                                           | Replaced by                                              | Status                                |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- | ------------------------------------- |
| `~/.shared/` (personal commands/hooks/skills) | valksor's pre-k0d3 personal toolkit                                                                    | every k0d3 category                                      | replaced at Phase 6                   |
| `toolkit`                                     | calibrated multi-perspective code review (`/review`, `/review-plan`, `/review-impl`) + reviewer agents | `commands/review/`, `agents/reviewers/`                  | replaced at Phase 6                   |
| `pr-review-toolkit`                           | code-quality cohort of read-only review agents (code-reviewer, silent-failure-hunter, etc.)            | `agents/experts/` (code-quality cohort, read-only tools) | replaced at Phase 6                   |
| `code-simplifier`                             | refactor-for-clarity agent                                                                             | `agents/experts/code-simplifier.md`                      | replaced at Phase 6                   |
| `superpowers`                                 | process skills (TDD, debugging, brainstorming, etc.)                                                   | `skills/{tdd,debugging,brainstorming,…}`                 | replaced at Phase 6                   |
| `coderabbit`                                  | AI-powered PR review via CodeRabbit                                                                    | none                                                     | optional — keep if you use CodeRabbit |
| `ralph-loop`, `claude-md-management`          | loop and CLAUDE.md maintenance utilities                                                               | none                                                     | optional                              |

Phase 6 cutover is mandatory but reversible at every step boundary. The per-hook ordering and rollback procedure live in `docs/hooks-migration.md`.

## Layout

```
.claude-plugin/plugin.json    — manifest
.mcp.json                     — bundled MCP servers (context7, auto-enabled)
skills/                       — ~145 active at one level (slug == directory)
agents/                       — workflow/, reviewers/, experts/
commands/                     — workflow/, plan/, execute/, review/, analyze/
hooks/                        — 11 shell hooks (disabled-by-default in hooks.json)
scripts/                      — validators, smoke runner, graph generator
tests/                        — fixtures for validator + hook tests
docs/                         — conventions, architecture, hooks-migration, …
references/                   — long-form material linked from skills
```

## MCP servers

k0d3 bundles one MCP server, **context7** (Upstash's hosted up-to-date library-docs service), defined in the top-level `.mcp.json`. Because it ships with the plugin, it **auto-enables when k0d3 is installed** — no per-server approval prompt, unlike a project-level `.mcp.json`. It is a remote HTTP server (`https://mcp.context7.com/mcp`), so there is nothing to install locally and no per-project index to build.

By default it talks to context7's anonymous tier (rate-limited). To raise the limits, get a free key at <https://context7.com> and export it before launching Claude Code:

```fish
set -x CONTEXT7_API_KEY <your-key>   # fish
```

```bash
export CONTEXT7_API_KEY=<your-key>   # bash/zsh
```

The key is never committed — `.mcp.json` references `${CONTEXT7_API_KEY:-}`, which falls back to empty (anonymous) when the variable is unset. To disable the server entirely, run `/mcp` in a session, or remove the context7 block from your installed plugin's `.mcp.json`.

## Editorial conventions (skill voice)

Every active skill follows these rules — enforced by `sharpness-check.sh` as soft signals and `validate-skills.sh` as hard rules:

- **Iron rule in the first 5 lines** — an opinionated do/don't that fires immediately. The skill body opens with a rule, not preamble. Verbs in imperative mood (MUST, NEVER, Always, Forbidden).
- **Opinion tables** — when comparing approaches, the skill picks a winner and explains the tradeoff in a row of a table. No "depends on context" surveys.
- **Anti-patterns / Red flags section** — concrete things that look right but aren't. Pattern matched against `Anti-patterns | Red flags | Forbidden | Never | Don't | Stop` section headers.
- **Body ≤200 lines (target ≤150)** — long-form goes to `references/<topic>.md`. The validator hard-fails at >200 lines; sharpness-check warns at >150.
- **No marketing copy** — skip "this skill helps you …" intros. Cut to the rule.

Collectively the team calls this the "k0d3 voice". A skill that reads like generic ML training-data prose has missed the bar.

## Verification

```bash
bash scripts/validate-skills.sh   # lint (frontmatter, slugs, body length, related-resolution, agent skills)
bash scripts/test-validator.sh    # CI for validate-skill-frontmatter.sh
bash scripts/test-hooks.sh        # CI for guard-bash.sh (catastrophic-rm, secret-exfil, etc.)
bash scripts/smoke-skills.sh      # iterate every status:active skill, write pass/fail log
bash scripts/sharpness-check.sh   # advisory: iron-rule, anti-pattern section, body length, opinion signal
```

All five wrappers either exit 0 (success) or non-zero (failure with stderr explaining). The advisory `sharpness-check.sh` always exits 0. The wrappers themselves are thin shells around Python helpers (`scripts/_*.py`) — `validate-skills.sh` and `new-skill.sh` use `set -euo pipefail`; the test wrappers use `set -uo pipefail` because they tally per-fixture PASS/FAIL counters rather than failing on the first error.

## Formatting

`make format` runs the full pipeline:

- **Markdown + JSON** — Prettier (latest, via `bunx` — unpinned). `proseWrap: preserve` so SKILL.md bodies aren't reflowed. `embeddedLanguageFormatting: auto` reformats fenced code, so keep an eye on the 200-line skill-body cap after large edits.
- **Shell** — `shfmt -i 2 -ci -sr` (install: `brew install shfmt`).
- **Python** — `ruff format` (via `uvx`; install `uv` from <https://docs.astral.sh/uv/>).

`make format-check` is the CI-friendly variant — it exits non-zero on any diff and writes nothing.

`make lint` runs **ShellCheck** over all tracked `*.sh` files (install: `brew install shellcheck`). Linting is separate from formatting — `shfmt` owns shell style, ShellCheck owns shell correctness.

The initial setup intentionally did **not** reformat or fix the existing tree. Files get formatted on first touch, so `make format-check` and `make lint` will report pre-existing drift on day one; that's expected.

## Authoring a new skill

```bash
bash scripts/new-skill.sh <kebab-case-slug>
# Edit skills/<slug>/SKILL.md to fill in description, type, body content
# Flip status from `draft` to `active` when ready
bash scripts/validate-skills.sh    # confirm lint passes
bash scripts/smoke-skills.sh       # confirm smoke passes
```

See `docs/conventions.md` for the full frontmatter schema and lint rules.

## Contributing

Open an issue at `https://github.com/valksor/k0d3/issues` (once the repo is public). Before submitting a PR, run the five verification scripts above and confirm `0 fail`. Skills that don't follow the voice rules will be revised in review.

## License

MIT. A `LICENSE` file will be added when the repo is published; until then `plugin.json` is the canonical license declaration. Borrowed content is one-line credited in `docs/borrowed-from.md`.
