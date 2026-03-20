#!/bin/bash
# Install TDD enforcement hooks (Layers 1 & 2) for Claude Code.
#
# What this does:
#   1. Symlinks hook scripts into ~/.claude/hooks/
#   2. Patches ~/.claude/settings.json to register the hooks
#
# Run from anywhere — the script locates itself.
#
# To uninstall, run: hooks/install.sh --uninstall

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

# ── Uninstall mode ──────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  echo "Removing TDD enforcement hooks..."

  rm -f "$CLAUDE_HOOKS_DIR/tdd-edit-guard.sh"
  rm -f "$CLAUDE_HOOKS_DIR/tdd-stop-guard.sh"
  rm -f "$CLAUDE_HOOKS_DIR/pre-commit-tdd-guard.sh"

  if [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
    BACKUP="${SETTINGS}.bak.$(date +%s)"
    cp "$SETTINGS" "$BACKUP"

    # Remove TDD hook entries from PreToolUse and Stop arrays
    jq '
      if .hooks.PreToolUse then
        .hooks.PreToolUse |= map(select(.hooks | all(.command | test("tdd-edit-guard") | not)))
      else . end
      |
      if .hooks.Stop then
        .hooks.Stop |= map(select(.hooks | all(.command | test("tdd-stop-guard") | not)))
      else . end
      |
      # Clean up empty arrays
      if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end
      |
      if .hooks.Stop == [] then del(.hooks.Stop) else . end
    ' "$BACKUP" > "$SETTINGS"

    echo "  Updated settings.json (backup: $BACKUP)"
  fi

  echo "Done. Restart Claude Code for changes to take effect."
  exit 0
fi

# ── Install mode ────────────────────────────────────────────
echo "Installing TDD enforcement hooks (Layers 1 & 2)..."
echo ""

# Check dependencies
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed."
  echo "  brew install jq  (macOS)"
  echo "  apt install jq   (Debian/Ubuntu)"
  exit 1
fi

# Create hooks directory
mkdir -p "$CLAUDE_HOOKS_DIR"

# Symlink all hook scripts (including pre-commit for consuming repos to reference)
for hook in tdd-edit-guard.sh tdd-stop-guard.sh pre-commit-tdd-guard.sh; do
  SOURCE="$SCRIPT_DIR/$hook"
  TARGET="$CLAUDE_HOOKS_DIR/$hook"

  if [[ -L "$TARGET" ]] && [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
    echo "  [skip] $hook already linked"
  else
    ln -sf "$SOURCE" "$TARGET"
    echo "  [link] $TARGET -> $SOURCE"
  fi
done

# Make scripts executable
chmod +x "$SCRIPT_DIR/tdd-edit-guard.sh" "$SCRIPT_DIR/tdd-stop-guard.sh" "$SCRIPT_DIR/pre-commit-tdd-guard.sh"

# ── Patch settings.json ─────────────────────────────────────
if [[ ! -f "$SETTINGS" ]]; then
  echo ""
  echo "WARNING: $SETTINGS not found. Creating minimal settings."
  echo '{"hooks":{}}' > "$SETTINGS"
fi

# Backup
BACKUP="${SETTINGS}.bak.$(date +%s)"
cp "$SETTINGS" "$BACKUP"
echo ""
echo "  Settings backup: $BACKUP"

# Check if hooks are already registered
EDIT_GUARD_EXISTS=$(jq '[.hooks.PreToolUse // [] | .[].hooks[]?.command] | any(test("tdd-edit-guard"))' "$SETTINGS" 2>/dev/null || echo "false")
STOP_GUARD_EXISTS=$(jq '[.hooks.Stop // [] | .[].hooks[]?.command] | any(test("tdd-stop-guard"))' "$SETTINGS" 2>/dev/null || echo "false")

# Add edit guard to PreToolUse
if [[ "$EDIT_GUARD_EXISTS" == "true" ]]; then
  echo "  [skip] Edit guard already registered in PreToolUse"
else
  EDIT_HOOK_ENTRY=$(jq -n --arg cmd "$CLAUDE_HOOKS_DIR/tdd-edit-guard.sh" '{
    "matcher": "Edit|Write",
    "hooks": [{"type": "command", "command": $cmd}]
  }')

  jq --argjson entry "$EDIT_HOOK_ENTRY" '
    .hooks.PreToolUse = (.hooks.PreToolUse // []) + [$entry]
  ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

  echo "  [add]  Edit guard registered (PreToolUse: Edit|Write)"
fi

# Add stop guard to Stop
if [[ "$STOP_GUARD_EXISTS" == "true" ]]; then
  echo "  [skip] Stop guard already registered in Stop"
else
  STOP_HOOK_ENTRY=$(jq -n --arg cmd "$CLAUDE_HOOKS_DIR/tdd-stop-guard.sh" '{
    "hooks": [{"type": "command", "command": $cmd}]
  }')

  jq --argjson entry "$STOP_HOOK_ENTRY" '
    .hooks.Stop = (.hooks.Stop // []) + [$entry]
  ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

  echo "  [add]  Stop guard registered (Stop event)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TDD hooks installed. Restart Claude Code to activate."
echo ""
echo "  Edit guard: Prompts when editing production code"
echo "    without test file changes in the working tree."
echo "    Debounced to once per 2 minutes."
echo ""
echo "  Stop guard: Blocks session completion when production"
echo "    files changed without test file changes."
echo ""
echo "  Pre-commit guard: Symlinked to ~/.claude/hooks/ for"
echo "    consuming repos. See hooks/README.md to opt in."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
