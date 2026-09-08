# Watermarks Remover upstream integration design

## Decision

Expose Watermarks Remover as an optional plugin in the `valksor-k0d3` Claude Code marketplace. Its marketplace entry points directly to `guillaumemeyer/watermarks-remover`; k0d3 does not copy, wrap, or modify upstream files.

Installing k0d3 does not install Watermarks Remover. Users opt in with a separate `/plugin install watermarks-remover@valksor-k0d3` command. This keeps the upstream plugin's file-scanning hook and service requirements behind an explicit installation action.

## Boundaries

- Claude Code only: upstream does not currently publish a Codex plugin manifest.
- No dependency declaration in k0d3's plugin manifest.
- No upstream version duplicated in k0d3. Claude Code resolves the upstream plugin manifest from its GitHub source.
- No bundled Watermarks Remover service. The upstream plugin documents its own service setup and optional hook behavior.
- Document the current upstream version mismatch and use Claude Code's `--plugin-dir` development path when a fresh upstream checkout is required before upstream advances its plugin manifest version.

## Verification

A marketplace regression test must prove that the optional entry uses the expected GitHub source, that k0d3 declares no plugin dependency, and that no Watermarks Remover files are vendored under `skills/`. Claude Code's strict plugin validator must accept the resulting marketplace.

## Provenance

The upstream-only and explicit-install decisions come from the user's direction to avoid copying the third-party project and from the completed-turn Advisor request to avoid transitive installation. The hook-consent rationale is based on upstream's published `PostToolUse` hook behavior.
