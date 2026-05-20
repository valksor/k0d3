#!/usr/bin/env bash
# Sync local k0d3 workspace to all Claude Code plugin locations.
# Run from anywhere — script resolves its own location.
#
# Usage: ./scripts/sync.sh [config-dir-name]
#   config-dir-name: directory name under $HOME to sync to (default: .claude)
#   Example: ./scripts/sync.sh .claude

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SOURCE_DIR/.claude-plugin/marketplace.json"

# Read metadata from marketplace.json (requires jq; fall back to hardcoded values)
if command -v jq &> /dev/null && [[ -f "$MANIFEST" ]]; then
  MARKETPLACE=$(jq -r '.name' "$MANIFEST")
  PLUGIN_NAME=$(jq -r '.plugins[0].name' "$MANIFEST")
  VERSION=$(jq -r '.plugins[0].version' "$MANIFEST")
else
  MARKETPLACE="valksor-k0d3"
  PLUGIN_NAME="k0d3"
  VERSION="0.1.0"
fi

CONFIG_DIRNAME="${1:-.claude}"
TARGET_DIR="$HOME/$CONFIG_DIRNAME"

sync_to() {
  local dest="$1"
  mkdir -p "$dest"
  rsync -a --delete --exclude=".git" "$SOURCE_DIR/" "$dest/"
  chmod +x "$dest"/hooks/*.sh 2> /dev/null || true
  chmod +x "$dest"/scripts/*.sh 2> /dev/null || true
  echo "  ✓ $dest"
}

update_installed_record() {
  local config_dir="$1"
  local installed="$config_dir/plugins/installed_plugins.json"
  [[ -f "$installed" ]] || return 0
  command -v jq &> /dev/null || return 0
  local key="${PLUGIN_NAME}@${MARKETPLACE}"
  local cache_path="$config_dir/plugins/cache/$MARKETPLACE/$PLUGIN_NAME/$VERSION"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  local updated
  updated="$(jq --arg key "$key" --arg ver "$VERSION" --arg path "$cache_path" --arg now "$now" '
        if .plugins[$key] then
            .plugins[$key][0] |= . + {"version": $ver, "installPath": $path, "lastUpdated": $now}
        else . end
    ' "$installed")"
  echo "$updated" > "$installed"
  echo "  ✓ updated installed_plugins.json → $key@$VERSION"
}

echo "Syncing $SOURCE_DIR → $TARGET_DIR..."

sync_to "$TARGET_DIR/plugins/$PLUGIN_NAME"
sync_to "$TARGET_DIR/plugins/cache/$MARKETPLACE/$PLUGIN_NAME/$VERSION"
sync_to "$TARGET_DIR/plugins/marketplaces/$MARKETPLACE"
update_installed_record "$TARGET_DIR"

# Register source path so /k0d3:update can rsync without arguments
echo "$SOURCE_DIR" > "$TARGET_DIR/plugins/$PLUGIN_NAME/.dev-source"
echo "  ✓ registered source → $TARGET_DIR/plugins/$PLUGIN_NAME/.dev-source"

echo ""
echo "Done. Restart your Claude Code session to pick up changes."
