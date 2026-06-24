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
( cd "$TMPREPO" && HOME="$TMPHOME" bash "$SCRIPT_DIR/install.sh" --commit-gate ) >/dev/null 2>&1

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

if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "FAILURES"; exit 1; fi
