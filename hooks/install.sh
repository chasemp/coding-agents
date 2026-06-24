#!/bin/bash
# Install TDD enforcement hooks for Claude Code.
#
# Modes:
#   (default)        Model A (real-time): symlink the scripts into
#                    ~/.claude/hooks/ and register the edit + stop guards in
#                    ~/.claude/settings.json.
#   --commit-gate    Model B (free editing, gate at commit): remove the edit +
#                    stop guards from settings.json and install the pre-commit
#                    guard (run-tests) into the current repo's .git/hooks/.
#   --uninstall      Remove the symlinks and the edit/stop guard entries.
#
# Run from anywhere — the script locates itself. (--commit-gate installs the
# per-repo pre-commit gate into whatever repo you run it from.) See
# hooks/README.md for the two models and the multi-workspace wrapper.

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

# ── Commit-gate mode (model B) ──────────────────────────────
# Free editing, gate at commit: remove the real-time edit/stop guards from
# settings.json and install the pre-commit guard (run-tests) into THIS repo.
if [[ "${1:-}" == "--commit-gate" ]]; then
  echo "Setting up the commit-gate model (model B)..."
  echo ""

  if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not installed."
    echo "  brew install jq  (macOS)   |   apt install jq  (Debian/Ubuntu)"
    exit 1
  fi

  # Symlink the scripts (the pre-commit wrapper references the symlinked guard).
  mkdir -p "$CLAUDE_HOOKS_DIR"
  for hook in tdd-edit-guard.sh tdd-stop-guard.sh pre-commit-tdd-guard.sh; do
    ln -sf "$SCRIPT_DIR/$hook" "$CLAUDE_HOOKS_DIR/$hook"
  done
  chmod +x "$SCRIPT_DIR"/tdd-edit-guard.sh "$SCRIPT_DIR"/tdd-stop-guard.sh "$SCRIPT_DIR"/pre-commit-tdd-guard.sh

  # Remove the real-time guards from settings.json (keep all non-TDD hooks).
  if [[ -f "$SETTINGS" ]]; then
    BACKUP="${SETTINGS}.bak.$(date +%s)"
    cp "$SETTINGS" "$BACKUP"
    jq '
      if .hooks.PreToolUse then
        .hooks.PreToolUse |= map(select(.hooks | all(.command | test("tdd-edit-guard") | not)))
      else . end
      | if .hooks.Stop then
          .hooks.Stop |= map(select(.hooks | all(.command | test("tdd-stop-guard") | not)))
        else . end
      | if .hooks.PreToolUse == [] then del(.hooks.PreToolUse) else . end
      | if .hooks.Stop == [] then del(.hooks.Stop) else . end
    ' "$BACKUP" > "$SETTINGS"
    echo "  [edit] removed edit/stop guards from settings.json (backup: $BACKUP)"
  else
    echo "  [skip] no $SETTINGS — nothing to remove"
  fi

  # Install the pre-commit gate into the current repo.
  if REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    HOOK="$REPO_ROOT/.git/hooks/pre-commit"
    cat > "$HOOK" <<'PRECOMMIT'
#!/bin/bash
# TDD commit-gate (installed by coding-agents hooks/install.sh --commit-gate).
# Require tests staged with prod (inline Rust #[cfg(test)] counts) AND run the
# suite. For a multi-workspace repo with no root manifest, replace the export
# below with the per-workspace wrapper from hooks/README.md.
export TDD_GUARD_RUN_TESTS=1
exec "$HOME/.claude/hooks/pre-commit-tdd-guard.sh" "$@"
PRECOMMIT
    chmod +x "$HOOK"
    echo "  [add]  pre-commit gate -> $HOOK (TDD_GUARD_RUN_TESTS=1)"
  else
    echo "  [skip] not inside a git repo — run again from a repo root to install the gate"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Commit-gate model active. Restart Claude Code so the"
  echo "  removed edit/stop guards take effect. Editing is now"
  echo "  uninterrupted; commits run the suite and require tests."
  echo "  Multi-workspace repos: see hooks/README.md for the"
  echo "  per-workspace pre-commit wrapper."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
