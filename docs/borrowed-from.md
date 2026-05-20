# Borrowed from

Plain credits for content adapted into k0d3. One line per item where the source was a clear copy. No SHAs, no license columns, no review ceremony — if something feels wrong about a source later, deal with it then.

## Skills

- `observability-sentry` — adapted from `~/.shared/skills/sentry-cli/`; stripped `sentry auth token` command for security
- `tooling-playwright-cli` — adapted from `~/.shared/skills/playwright-cli/`
- `dispatching-parallel-agents` — adapted from `obra/superpowers:dispatching-parallel-agents`

## Agents

The reviewer and code-quality cohorts adapt patterns from valksor's pre-existing `toolkit` and `pr-review-toolkit` plugins. The agent prompts were rewritten for k0d3 voice and the calibration system was unified across all four reviewers.

- `agents/reviewers/*` — calibration model derived from `toolkit`'s review agents
- `agents/experts/{code-reviewer,code-simplifier,silent-failure-hunter,comment-analyzer,type-design-analyzer,pr-test-analyzer}` — read-only review pattern from `pr-review-toolkit`

## Commands

- `commands/review/{review,review-plan,review-impl,security-audit}` — adapted from `toolkit:review*` commands; multi-perspective dispatch pattern preserved, calibration unified

## Hooks

The hook set was ported from valksor's personal `~/.shared/hooks/` toolkit, with fixes and one new addition:

- All ported: `backup-before-write`, `block-deferred-issues`, `completeness-gate`, `guard-bash`, `log-changes`, `log-failures`, `log-stop-verdict`, `pre-compact-handoff`, `post-compact-resume`, `session-reset`
- New: `validate-skill-frontmatter` (k0d3-specific)

Fixes applied during port (see `git log hooks/` for specifics): catastrophic-rm token-scan, shell-indirection bypass detection, `.env` read coverage, log-injection sanitization, clause-aware compound-command splitting, the `tail|mv` truncation race in `session-reset`, and the latent stdin-collision bug in `validate-skill-frontmatter`.
