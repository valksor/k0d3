#!/usr/bin/env bash
# test-codex.sh — regression checks for k0d3's Codex CLI integration.
#
# Static checks: manifests parse, versions are in sync, MCP/skills pointers
# resolve, the derived Codex hooks JSON drops the Claude-only events and routes
# every command through the shim. Behavioral check: a dangerous Bash command fed
# through the shim into guard-bash.sh actually returns a Codex `deny` decision —
# proving Codex's tool_input.command field name reaches the script.
#
# Mirrors scripts/test-hooks.sh; wired into the mcp-guard workflow.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0
pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

command -v jq >/dev/null 2>&1 || { echo "error: jq required" >&2; exit 1; }

# 1. Codex plugin manifest parses and version matches the Claude manifest.
if jq empty .codex-plugin/plugin.json 2>/dev/null; then pass "codex plugin.json parses"; else fail "codex plugin.json invalid JSON"; fi
CV=$(jq -r '.version' .codex-plugin/plugin.json)
PV=$(jq -r '.version' .claude-plugin/plugin.json)
[ "$CV" = "$PV" ] && pass "version sync ($CV)" || fail "version drift: codex=$CV claude=$PV"

# 2. Skills + MCP pointers resolve.
SK=$(jq -r '.skills' .codex-plugin/plugin.json)
[ -d "$ROOT/${SK#./}" ] && pass "skills pointer resolves ($SK)" || fail "skills pointer missing: $SK"
MP=$(jq -r '.mcpServers' .codex-plugin/plugin.json)
[ -f "$ROOT/${MP#./}" ] && pass "mcpServers pointer resolves ($MP)" || fail "mcpServers pointer missing: $MP"

# 3. Codex MCP manifest: parses, stdio servers carry no Claude-only "type":"stdio",
#    memory routes through the launcher.
if jq empty .mcp.codex.json 2>/dev/null; then pass ".mcp.codex.json parses"; else fail ".mcp.codex.json invalid JSON"; fi
BADTYPE=$(jq -r '[.mcpServers[] | select(.type=="stdio")] | length' .mcp.codex.json)
[ "$BADTYPE" = "0" ] && pass "no Claude-only type:stdio in codex mcp" || fail "$BADTYPE servers use type:stdio (Codex omits it)"
MEMCMD=$(jq -r '.mcpServers.memory.command' .mcp.codex.json)
case "$MEMCMD" in *start-memory.sh) pass "memory uses launcher" ;; *) fail "memory command not launcher: $MEMCMD" ;; esac

# 3b. Codex strict-parser hygiene: hooks.json must contain ONLY `hooks` (Codex rejects
#     any other top-level key, e.g. _comment/_disabled_examples), and the plugin must ship
#     NO plugin-channel hooks (manifest `hooks` -> an empty file; installer delivers them).
HK_KEYS=$(jq -r '[keys[] | select(. != "hooks")] | length' hooks/hooks.json)
[ "$HK_KEYS" = "0" ] && pass "hooks.json has only 'hooks' key" || fail "hooks.json has extra top-level keys (Codex parser rejects them)"
HPTR=$(jq -r '.hooks // empty' .codex-plugin/plugin.json)
[ -n "$HPTR" ] && [ -f "$ROOT/${HPTR#./}" ] && pass "plugin hooks pointer resolves ($HPTR)" || fail "plugin hooks pointer missing: $HPTR"
EMPTY=$(jq -r '.hooks | length' "$ROOT/${HPTR#./}" 2>/dev/null)
[ "$EMPTY" = "0" ] && pass "plugin ships empty plugin-channel hooks" || fail "plugin-channel hooks not empty ($EMPTY events) — would double-fire with installer"
jq -e 'has("_comment") | not' .mcp.codex.json >/dev/null && pass ".mcp.codex.json has no _comment" || fail ".mcp.codex.json has _comment (strict-parser risk)"

# 4. Codex marketplace manifest valid + accepted authentication variant.
if jq empty .agents/plugins/marketplace.json 2>/dev/null; then pass "marketplace.json parses"; else fail "marketplace.json invalid JSON"; fi
AUTH=$(jq -r '.plugins[0].policy.authentication' .agents/plugins/marketplace.json)
case "$AUTH" in ON_INSTALL|ON_USE) pass "marketplace auth variant ($AUTH)" ;; *) fail "invalid auth variant: $AUTH" ;; esac

# 5. Derived Codex hooks JSON: valid, Claude-only events dropped, codegraph retained, all commands shimmed.
HJSON=$(bash scripts/install-codex-hooks.sh --print)
if printf '%s' "$HJSON" | jq empty 2>/dev/null; then pass "derived hooks JSON parses"; else fail "derived hooks JSON invalid"; fi
printf '%s' "$HJSON" | jq -e '.hooks.PostToolUseFailure == null' >/dev/null && pass "PostToolUseFailure dropped" || fail "PostToolUseFailure present"
printf '%s' "$HJSON" | jq -e '.hooks.Stop == null' >/dev/null && pass "Stop dropped from Codex hooks" || fail "Stop present in Codex hooks (verify-before-stop uses Claude Code output format)"
printf '%s' "$HJSON" | jq -e '.hooks.SubagentStop == null' >/dev/null && pass "SubagentStop dropped from Codex hooks" || fail "SubagentStop present in Codex hooks"
printf '%s' "$HJSON" | jq -e '[.hooks.PreToolUse[].matcher] | index("ExitPlanMode") == null' >/dev/null && pass "ExitPlanMode dropped" || fail "ExitPlanMode present"
printf '%s' "$HJSON" | jq -e '[.hooks.PreToolUse[].matcher] | index("mcp__codegraph__.*") != null' >/dev/null && pass "allow-codegraph retained" || fail "codegraph matcher dropped"
UNSHIMMED=$(printf '%s' "$HJSON" | jq -r '[.. | objects | select(has("command")) | .command | select(contains("codex-hooks-shim.sh") | not)] | length')
[ "$UNSHIMMED" = "0" ] && pass "all commands shimmed" || fail "$UNSHIMMED commands not shimmed"

# 6. Behavioral: dangerous Bash via shim -> guard-bash returns a Codex deny decision.
DANGER='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /etc"},"cwd":"/tmp"}'
DECISION=$(printf '%s' "$DANGER" | bash hooks/codex-hooks-shim.sh "$ROOT/hooks/guard-bash.sh" | jq -r '.hookSpecificOutput.permissionDecision // empty')
[ "$DECISION" = "deny" ] && pass "guard-bash denies dangerous command via shim" || fail "guard-bash did not deny (got: '$DECISION')"

# 7. Behavioral: auto-review-merge.sh exits cleanly (no output) for a Codex Stop event
#    with a non-worktree cwd — confirms the hook_event_name detection branch doesn't crash.
CODEX_STOP='{"hook_event_name":"Stop","cwd":"/tmp","stop_hook_active":false}'
if [ -f "$HOME/.codex/hooks/auto-review-merge.sh" ]; then
  OUT=$(printf '%s' "$CODEX_STOP" | bash "$HOME/.codex/hooks/auto-review-merge.sh" 2>/dev/null || true)
  [ -z "$OUT" ] && pass "auto-review-merge: no output for non-worktree cwd under Codex" || fail "auto-review-merge: unexpected output for non-worktree cwd: '$OUT'"
else
  pass "auto-review-merge: hook not installed at ~/.codex/hooks/ (skip)"
fi

echo "----"
if [ "$FAIL" -eq 0 ]; then echo "test-codex.sh: all checks passed"; exit 0; else echo "test-codex.sh: $FAIL check(s) failed" >&2; exit 1; fi
