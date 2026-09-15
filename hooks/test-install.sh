#!/bin/bash
# Test harness for install.sh. Runs against a sandboxed HOME + throwaway git
# repo so it never touches the real ~/.claude or any real repo. Run directly:
#   bash hooks/test-install.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMPHOME=$(mktemp -d)
TMPREPO=$(mktemp -d)
cleanup() { rm -rf "$TMPHOME" "$TMPREPO"; }
trap cleanup EXIT

fail=0
check() { if eval "$2"; then echo "  PASS: $1"; else echo "  FAIL: $1"; fail=1; fi; }

# ── --commit-gate: model B (free editing, gate at commit) ───────────
# Sandbox a model-A settings.json (edit + stop guards registered) plus an
# unrelated non-TDD hook that must survive.
mkdir -p "$TMPHOME/.claude"
cat > "$TMPHOME/.claude/settings.json" <<JSON
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "$TMPHOME/.claude/hooks/tdd-edit-guard.sh" } ] },
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "/usr/local/bin/rtk hook claude" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "$TMPHOME/.claude/hooks/tdd-stop-guard.sh" } ] }
    ]
  }
}
JSON

git -C "$TMPREPO" init -q

echo "test: install.sh --commit-gate"
# env -u: the developer running this suite may have CLAUDE_CONFIG_DIR set, and install.sh now
# honors it — without the unset, this sandboxed run patched the REAL config dir (2026-09-14).
( cd "$TMPREPO" && HOME="$TMPHOME" env -u CLAUDE_CONFIG_DIR bash "$SCRIPT_DIR/install.sh" --commit-gate ) >/dev/null 2>&1

S="$TMPHOME/.claude/settings.json"
check "edit-guard removed from settings.json" \
  '! jq -e "[.hooks.PreToolUse[]?.hooks[]?.command] | any(test(\"tdd-edit-guard\"))" "$S" >/dev/null'
check "stop-guard removed from settings.json" \
  '! jq -e "[.hooks.Stop[]?.hooks[]?.command] | any(test(\"tdd-stop-guard\"))" "$S" >/dev/null'
check "non-TDD hook (rtk) preserved" \
  'jq -e "[.hooks.PreToolUse[]?.hooks[]?.command] | any(test(\"rtk hook\"))" "$S" >/dev/null'
check "pre-commit gate installed + executable" \
  '[ -x "$TMPREPO/.git/hooks/pre-commit" ]'
check "pre-commit runs the test suite" \
  'grep -q "TDD_GUARD_RUN_TESTS=1" "$TMPREPO/.git/hooks/pre-commit"'
check "pre-commit calls the shared guard" \
  'grep -q "pre-commit-tdd-guard.sh" "$TMPREPO/.git/hooks/pre-commit"'
check "settings.json is still valid JSON" \
  'jq -e . "$S" >/dev/null'

# ── CLAUDE_CONFIG_DIR: the settings file that COUNTS is the one the session reads ──
# Found 2026-09-14: every session on the owner's machine runs with CLAUDE_CONFIG_DIR set,
# so ~/.claude/settings.json — where this installer registered the destructive-git guard
# on 2026-08-26 — is read by nothing. The guard passed its 27 fixtures and never fired
# once. Registration must go to $CLAUDE_CONFIG_DIR/settings.json when that is set.
CFG="$TMPHOME/cfg"
mkdir -p "$CFG"
echo '{"hooks":{}}' > "$CFG/settings.json"
echo '{"hooks":{}}' > "$TMPHOME/.claude/settings.json"
echo "test: install.sh (default) honors CLAUDE_CONFIG_DIR"
( cd "$TMPREPO" && HOME="$TMPHOME" CLAUDE_CONFIG_DIR="$CFG" bash "$SCRIPT_DIR/install.sh" ) >/dev/null 2>&1
check "destructive-git guard registered in \$CLAUDE_CONFIG_DIR/settings.json" \
  'jq -e "[.hooks.PreToolUse[]?.hooks[]?.command] | any(test(\"destructive-git-guard\"))" "$CFG/settings.json" >/dev/null'
check "~/.claude/settings.json left untouched when CLAUDE_CONFIG_DIR is set" \
  '! jq -e "[.hooks.PreToolUse[]?.hooks[]?.command] | any(test(\"destructive-git-guard\"))" "$TMPHOME/.claude/settings.json" >/dev/null'

if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES"; exit 1; fi
