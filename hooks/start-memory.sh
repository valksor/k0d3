#!/usr/bin/env bash
# start-memory.sh — launcher for the @modelcontextprotocol/server-memory MCP server.
#
# Why this exists: Codex expands ${PLUGIN_ROOT} in the manifest before launch but
# does not provide Claude's project/plugin environment variables to MCP servers.
# The MCP process inherits the workspace cwd, so resolve the project-local store
# from that stable runtime input and exec the real server.
#
# Storage stays project-local at <workspace>/.codex/memory.jsonl. Do not use
# ${PLUGIN_DATA}: that directory is shared by every project using this plugin.
set -eu

TARGET_DIR="$(pwd -P)/.codex"

mkdir -p "$TARGET_DIR"
export MEMORY_FILE_PATH="$TARGET_DIR/memory.jsonl"

exec npx -y @modelcontextprotocol/server-memory
