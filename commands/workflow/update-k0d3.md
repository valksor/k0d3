---
name: update-k0d3
description: Force a fresh load of k0d3 after in-place edits — uninstalls and reinstalls from the local marketplace path
argument-hint: ""
allowed-tools: [Bash(grep:*)]
---

# /update-k0d3

Forces Claude Code to re-read k0d3 from disk by uninstalling and reinstalling. Use after any in-place edit to k0d3 if you suspect CC has cached the previous version.

The uninstall/install steps are Claude Code meta-commands (slash commands typed in the chat) — they are NOT shell commands. Only the verification step shells out (`/help | grep`).

## Steps

1. **Uninstall** (type this as a slash command in the Claude Code chat, not a shell command):
   ```
   /plugin uninstall k0d3
   ```
2. **Reinstall from local marketplace** (also a CC slash command):
   ```
   /plugin install k0d3@local
   ```
3. **Verify** (this one is a shell command — `/help` here means CC's help output piped to grep):
   ```bash
   # Run inside Claude Code:
   /help | grep -i k0d3
   ```
   You should see the k0d3 commands listed. If you don't, the install didn't take — re-check the marketplace path.

## Resolution policy

Always installs from **`@local`** (the local checkout path). Never refetches from a network URI without explicit user instruction. See `docs/architecture.md` for the rationale.
