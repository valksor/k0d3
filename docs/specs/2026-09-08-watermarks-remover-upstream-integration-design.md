# Watermarks Remover upstream integration design

## Decision

Expose Watermarks Remover as an upstream plugin in the `valksor-k0d3` Claude Code marketplace. Its marketplace entry points directly to `guillaumemeyer/watermarks-remover`; k0d3 does not copy, wrap, or modify upstream files.

Installing k0d3 automatically installs and enables Watermarks Remover through the k0d3 plugin's `dependencies` declaration. A separate `/plugin install watermarks-remover@valksor-k0d3` command remains available for direct installation or dependency repair.

## Boundaries

- Claude Code only: upstream does not currently publish a Codex plugin manifest.
- Watermarks Remover is k0d3's sole plugin dependency.
- No upstream version duplicated in k0d3. Claude Code resolves the upstream plugin manifest from its GitHub source.
- No bundled Watermarks Remover service. The upstream plugin documents its own service setup and optional hook behavior.
- Document the current upstream version mismatch and use Claude Code's `--plugin-dir` development path when a fresh upstream checkout is required before upstream advances its plugin manifest version.

## Verification

A marketplace regression test must prove that the entry uses the expected GitHub source, that k0d3 declares Watermarks Remover as its sole plugin dependency, and that no Watermarks Remover files are vendored under `skills/`. Claude Code's strict plugin validator must accept the resulting marketplace.

## Provenance

The upstream-only decision comes from the user's direction to avoid copying the third-party project. Automatic installation comes from the user's subsequent explicit request to add the dependency. The hook behavior is based on upstream's published `PostToolUse` configuration.
