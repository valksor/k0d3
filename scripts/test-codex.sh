#!/usr/bin/env bash
# test-codex.sh — regression checks for k0d3's Codex CLI integration.
#
# Static checks: manifests parse, versions are in sync, MCP/skills/hooks pointers
# resolve, the generated Codex plugin-channel hooks (hooks/hooks.codex.json) are in
# sync with the source of truth, drop the Codex-unsupported events/keys, and route
# every command through the shim with ${CLAUDE_PLUGIN_ROOT}. Behavioral checks: a
# dangerous Bash command through the shim returns a Codex deny; verify-before-stop.sh
# dual-emits the Codex vs Claude block schema; the shim fails closed on a bad delegate.
#
# Mirrors scripts/test-hooks.sh; wired into the mcp-guard workflow.
# shellcheck disable=SC2015 # pass/fail helpers are side-effect-only checks and return success.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0
pass() { printf 'PASS %s\n' "$1"; }
fail() {
  printf 'FAIL %s\n' "$1" >&2
  FAIL=$((FAIL + 1))
}

command -v jq > /dev/null 2>&1 || {
  echo "error: jq required" >&2
  exit 1
}

# 1. Codex plugin manifest parses and version matches the Claude manifest.
if jq empty .codex-plugin/plugin.json 2> /dev/null; then pass "codex plugin.json parses"; else fail "codex plugin.json invalid JSON"; fi
CV=$(jq -r '.version' .codex-plugin/plugin.json)
PV=$(jq -r '.version' .claude-plugin/plugin.json)
[ "$CV" = "$PV" ] && pass "version sync ($CV)" || fail "version drift: codex=$CV claude=$PV"

# 2. Skills + MCP pointers resolve.
SK=$(jq -r '.skills' .codex-plugin/plugin.json)
[ -d "$ROOT/${SK#./}" ] && pass "skills pointer resolves ($SK)" || fail "skills pointer missing: $SK"
MP=$(jq -r '.mcpServers' .codex-plugin/plugin.json)
[ -f "$ROOT/${MP#./}" ] && pass "mcpServers pointer resolves ($MP)" || fail "mcpServers pointer missing: $MP"

# 3. Codex MCP manifest: parses, stdio servers carry no Claude-only "type":"stdio",
#    memory bootstraps directly from the inherited workspace cwd without host
#    variables, no _comment (strict-parser hygiene).
if jq empty .mcp.codex.json 2> /dev/null; then pass ".mcp.codex.json parses"; else fail ".mcp.codex.json invalid JSON"; fi
BADTYPE=$(jq -r '[.mcpServers[] | select(.type=="stdio")] | length' .mcp.codex.json)
[ "$BADTYPE" = "0" ] && pass "no Claude-only type:stdio in codex mcp" || fail "$BADTYPE servers use type:stdio (Codex omits it)"
MEMCMD=$(jq -r '.mcpServers.memory.command' .mcp.codex.json)
MEMARG0=$(jq -r '.mcpServers.memory.args[0] // empty' .mcp.codex.json)
MEMARG1=$(jq -r '.mcpServers.memory.args[1] // empty' .mcp.codex.json)
MEMARG2=$(jq -r '.mcpServers.memory.args[2] // empty' .mcp.codex.json)
# shellcheck disable=SC2016 # The manifest script must retain these expansions for the child shell.
MEM_SCRIPT='set -eu
memory_dir="$(pwd -P)/.codex"
mkdir -p "$memory_dir"
export MEMORY_FILE_PATH="$memory_dir/memory.jsonl"
exec npx -y @modelcontextprotocol/server-memory'
MEM_BOOTSTRAP_OK=0
[ "$MEMCMD" = "bash" ] && [ "$MEMARG0" = "-c" ] && [ "$MEMARG1" = "$MEM_SCRIPT" ] && [ -z "$MEMARG2" ] && MEM_BOOTSTRAP_OK=1
[ "$MEM_BOOTSTRAP_OK" = "1" ] &&
  pass "memory uses variable-free workspace bootstrap" || fail "memory command not variable-free workspace bootstrap"
MEM_KEYS=$(jq -r '[.mcpServers.memory | keys[] | select(. == "cwd")] | length' .mcp.codex.json)
[ "$MEM_KEYS" = "0" ] && pass "memory preserves inherited workspace cwd" || fail "memory overrides workspace cwd"
jq -e '.mcpServers.memory | tostring | test("CLAUDE_|CODEX_PROJECT_DIR|PLUGIN_ROOT|PLUGIN_DATA") | not' .mcp.codex.json > /dev/null &&
  pass "memory bootstrap has no project/plugin variables" || fail "memory bootstrap depends on a project/plugin variable"
jq -e 'has("_comment") | not' .mcp.codex.json > /dev/null && pass ".mcp.codex.json has no _comment" || fail ".mcp.codex.json has _comment (strict-parser risk)"

# 3b. Strict-parser hygiene + plugin-channel hooks pointer.
HK_KEYS=$(jq -r '[keys[] | select(. != "hooks")] | length' hooks/hooks.json)
[ "$HK_KEYS" = "0" ] && pass "hooks.json has only 'hooks' key" || fail "hooks.json has extra top-level keys (Codex parser rejects them)"
HPTR=$(jq -r '.hooks // empty' .codex-plugin/plugin.json)
[ "$HPTR" = "./hooks/hooks.codex.json" ] && pass "plugin hooks pointer is ./hooks/hooks.codex.json" || fail "plugin hooks pointer wrong: $HPTR"
[ -n "$HPTR" ] && [ -f "$ROOT/${HPTR#./}" ] && pass "plugin hooks file exists" || fail "plugin hooks file missing: $HPTR"
EVENTS=$(jq -r '.hooks | length' "$ROOT/${HPTR#./}" 2> /dev/null || echo 0)
[ "$EVENTS" -gt 0 ] 2> /dev/null && pass "plugin ships $EVENTS hook events" || fail "plugin hooks file empty (would load no hooks)"

# 4. Codex marketplace manifest valid + accepted authentication variant.
if jq empty .agents/plugins/marketplace.json 2> /dev/null; then pass "marketplace.json parses"; else fail "marketplace.json invalid JSON"; fi
AUTH=$(jq -r '.plugins[0].policy.authentication' .agents/plugins/marketplace.json)
case "$AUTH" in ON_INSTALL | ON_USE) pass "marketplace auth variant ($AUTH)" ;; *) fail "invalid auth variant: $AUTH" ;; esac

# 5. Generated Codex hooks (hooks/hooks.codex.json): in sync, valid, Codex-unsupported
#    events/keys dropped, Stop/SubagentStop kept, every command shimmed.
HJ="hooks/hooks.codex.json"
if jq empty "$HJ" 2> /dev/null; then pass "hooks.codex.json parses"; else fail "hooks.codex.json invalid JSON"; fi
bash scripts/generate-codex-hooks.sh --check > /dev/null && pass "hooks.codex.json in sync with generator" || fail "hooks.codex.json stale/errored — run scripts/generate-codex-hooks.sh"
jq -e '.hooks.PostToolUseFailure == null' "$HJ" > /dev/null && pass "PostToolUseFailure dropped" || fail "PostToolUseFailure present (no such Codex event)"
jq -e '[.hooks.PreToolUse[].matcher] | index("ExitPlanMode") == null' "$HJ" > /dev/null && pass "ExitPlanMode dropped" || fail "ExitPlanMode present"
jq -e '.hooks.Stop != null and .hooks.SubagentStop != null' "$HJ" > /dev/null && pass "Stop/SubagentStop present" || fail "Stop/SubagentStop missing from Codex hooks"
ASYNC=$(jq -r '[.. | objects | select(has("async"))] | length' "$HJ")
[ "$ASYNC" = "0" ] && pass "no async keys remain" || fail "$ASYNC async hooks present (Codex has no async support)"
UNSHIMMED=$(jq -r '[.. | objects | select(has("command")) | .command | select(contains("codex-hooks-shim.sh") | not)] | length' "$HJ")
[ "$UNSHIMMED" = "0" ] && pass "all commands shimmed" || fail "$UNSHIMMED commands not shimmed"
UNINTERP=$(jq -r '[.. | objects | select(has("command")) | .command | select(contains("${CLAUDE_PLUGIN_ROOT}") | not)] | length' "$HJ")
[ "$UNINTERP" = "0" ] && pass "all commands use \${CLAUDE_PLUGIN_ROOT}" || fail "$UNINTERP commands lack \${CLAUDE_PLUGIN_ROOT}"
TELEM=$(jq -r '[.. | objects | select(has("command")) | .command | select(test("log-changes.sh|log-stop-verdict.sh"))] | length' "$HJ")
[ "$TELEM" = "0" ] && pass "async telemetry excluded" || fail "$TELEM async telemetry hooks leaked into Codex"

# 6. Codex skill manifests: every non-draft skill has a parseable agents/openai.yaml
#    with the interface fields Codex surfaces; committed files are in sync.
bash scripts/generate-codex-skill-manifests.sh --check > /dev/null && pass "openai.yaml manifests in sync" || fail "openai.yaml stale/errored — run scripts/generate-codex-skill-manifests.sh"
MISS=0
for d in skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  case "$(basename "$d")" in _probe-*) continue ;; esac
  # Draft detection must match the generator's PyYAML path exactly (metadata.status),
  # not a raw text sniff, or the two could disagree on which skills are draft.
  status=$(python3 -c "import sys,yaml; t=open(sys.argv[1]).read().split('---',2); fm=yaml.safe_load(t[1]) if len(t)>=3 else {}; print(((fm or {}).get('metadata') or {}).get('status') or '')" "$d/SKILL.md" 2> /dev/null || true)
  [ "$status" = "draft" ] && continue
  [ -f "$d/agents/openai.yaml" ] || {
    MISS=$((MISS + 1))
    continue
  }
  python3 -c "import sys,yaml; d=yaml.safe_load(open(sys.argv[1])); i=d.get('interface',{}); sys.exit(0 if i.get('display_name') and i.get('short_description') else 1)" "$d/agents/openai.yaml" 2> /dev/null || MISS=$((MISS + 1))
done
[ "$MISS" = "0" ] && pass "all non-draft skills have a valid openai.yaml" || fail "$MISS skills missing/invalid openai.yaml"

# 7. Behavioral: dangerous Bash via shim -> guard-bash returns a Codex deny decision.
DANGER='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /etc"},"cwd":"/tmp"}'
DECISION=$(printf '%s' "$DANGER" | bash hooks/codex-hooks-shim.sh "$ROOT/hooks/guard-bash.sh" | jq -r '.hookSpecificOutput.permissionDecision // empty')
[ "$DECISION" = "deny" ] && pass "guard-bash denies dangerous command via shim" || fail "guard-bash did not deny (got: '$DECISION')"

# 7b. Behavioral: shim fails closed on a missing delegate (non-zero, not silent success).
if printf '%s' '{}' | bash hooks/codex-hooks-shim.sh "$ROOT/hooks/does-not-exist.sh" > /dev/null 2>&1; then
  fail "shim silently succeeded on a missing delegate (should fail closed)"
else
  pass "shim fails closed on a missing delegate"
fi

# 7c. Behavioral: launch from a workspace with every project/plugin variable
# unset. The inherited workspace cwd alone must select
# <workspace>/.codex/memory.jsonl.
MEM_TMP="$(mktemp -d)"
trap 'rm -rf "${TT:-}" "${MEM_TMP:-}"' EXIT
MEM_OUT="$MEM_TMP/out.txt"
MEM_ERR="$MEM_TMP/err.txt"
mkdir -p "$MEM_TMP/bin" "$MEM_TMP/project"
MEM_PROJECT="$(cd "$MEM_TMP/project" && pwd -P)"
cat > "$MEM_TMP/bin/npx" << 'FAKE_NPX'
#!/usr/bin/env bash
printf '%s\n' "$MEMORY_FILE_PATH" > "$K0D3_MEMORY_TEST_OUT"
printf '%s\n' "$*" > "$K0D3_MEMORY_TEST_ARGS"
exit 0
FAKE_NPX
chmod +x "$MEM_TMP/bin/npx"
if [ "$MEM_BOOTSTRAP_OK" != "1" ]; then
  fail "memory MCP bootstrap smoke skipped because manifest command validation failed"
elif (
  cd "$MEM_TMP/project"
  unset CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR CODEX_PROJECT_DIR PLUGIN_ROOT PLUGIN_DATA
  export PATH="$MEM_TMP/bin:$PATH"
  export K0D3_MEMORY_TEST_OUT="$MEM_TMP/memory-path.txt"
  export K0D3_MEMORY_TEST_ARGS="$MEM_TMP/npx-args.txt"
  "$MEMCMD" "$MEMARG0" "$MEMARG1" > "$MEM_OUT" 2> "$MEM_ERR" < /dev/null
); then
  [ -d "$MEM_PROJECT/.codex" ] &&
    [ "$(cat "$MEM_TMP/memory-path.txt" 2> /dev/null)" = "$MEM_PROJECT/.codex/memory.jsonl" ] &&
    [ "$(cat "$MEM_TMP/npx-args.txt" 2> /dev/null)" = "-y @modelcontextprotocol/server-memory" ] &&
    pass "memory MCP bootstrap uses workspace cwd without project/plugin variables" || fail "memory MCP bootstrap did not resolve the expected project-local path"
else
  fail "memory MCP command failed without project/plugin variables: $(cat "$MEM_ERR" "$MEM_OUT" 2> /dev/null | tr '\n' ' ' | sed 's/  */ /g')"
fi

# 8. Behavioral: verify-before-stop.sh dual-emits the right block schema per host.
TT="$(mktemp)"
{
  printf '%s\n' '{"message":{"role":"user","content":[{"type":"text","text":"fix it"}]}}'
  printf '%s\n' '{"message":{"role":"user","content":[{"type":"tool_result","content":[{"type":"text","text":"bash: foo: command not found"}]}]}}'
} > "$TT"
STOP_EVT=$(jq -n --arg t "$TT" '{hook_event_name:"Stop",stop_hook_active:false,transcript_path:$t}')
# Codex host -> {continue:false}
COUT=$(printf '%s' "$STOP_EVT" | K0D3_HOST=codex bash hooks/verify-before-stop.sh)
echo "$COUT" | jq -e '.continue == false and (.stopReason | type == "string") and (has("decision") | not)' > /dev/null 2>&1 &&
  pass "verify-before-stop emits Codex schema under K0D3_HOST=codex" || fail "Codex Stop schema wrong: $COUT"
# Claude host (no marker) -> {decision:block}. Use a subshell unset (portable;
# `env -u` is a GNU extension absent from BSD/macOS env).
LOUT=$(printf '%s' "$STOP_EVT" | (
  unset K0D3_HOST
  exec bash hooks/verify-before-stop.sh
))
echo "$LOUT" | jq -e '.decision == "block" and (.reason | type == "string") and (has("continue") | not)' > /dev/null 2>&1 &&
  pass "verify-before-stop emits Claude schema without marker" || fail "Claude Stop schema wrong: $LOUT"
# Backstop: stop_hook_active true -> no output (no infinite block).
BACK=$(printf '%s' "$STOP_EVT" | jq '.stop_hook_active=true' | K0D3_HOST=codex bash hooks/verify-before-stop.sh)
[ -z "$BACK" ] && pass "stop_hook_active backstop fires (no output)" || fail "backstop did not fire: $BACK"

echo "----"
if [ "$FAIL" -eq 0 ]; then
  echo "test-codex.sh: all checks passed"
  exit 0
else
  echo "test-codex.sh: $FAIL check(s) failed" >&2
  exit 1
fi
