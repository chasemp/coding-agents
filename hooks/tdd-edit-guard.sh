#!/bin/bash
# TDD Edit Guard — Layer 2 (real-time nudge)
# Hook type: PreToolUse (matcher: Edit|Write)
# Prompts for confirmation when editing production code files while
# no test files have been modified in the working tree.
#
# During normal TDD flow (write test → write code), the test file
# changes exist in the working tree when production code is edited,
# so this hook stays silent. It only fires when production code is
# being edited WITHOUT any test file changes — the signal that
# TDD may have been skipped.
#
# Debounce: warns at most once per 2 minutes to avoid fatigue.

# Guards: skip silently if dependencies missing
if ! command -v jq &>/dev/null; then
  exit 0
fi
if ! git rev-parse --git-dir &>/dev/null 2>&1; then
  exit 0
fi

# Opt-out: .notdd in repo root disables all TDD enforcement for this repo
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -n "$REPO_ROOT" ]] && [[ -f "$REPO_ROOT/.notdd" ]]; then
  exit 0
fi

set -euo pipefail

INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

# --- Is this a test file? Allow silently (writing tests = good). ---
TEST_PATTERN='(tests?/|__tests__/|_test\.(go|py|ts|js)$|\.test\.(ts|tsx|js|jsx)$|\.spec\.(ts|tsx|js|jsx)$|/test_[^/]*\.py$|conftest\.py$)'
if echo "$FILE_PATH" | grep -qE "$TEST_PATTERN"; then
  exit 0
fi

# --- Is this a production source file? ---
# Must be a code file extension...
if ! echo "$FILE_PATH" | grep -qE '\.(py|ts|tsx|js|jsx|go|rs)$'; then
  exit 0  # Not source code (config, docs, scripts, etc.)
fi
# ...in a standard source directory
if ! echo "$FILE_PATH" | grep -qE '(src/|lib/|app/|pkg/|cmd/|internal/)'; then
  exit 0  # Top-level scripts, CLI entry points, etc. — skip
fi

# --- Check if test files have been modified in the working tree ---
TEST_CHANGES=$(
  {
    git diff --name-only 2>/dev/null
    git diff --cached --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | grep -cE "$TEST_PATTERN" || true
)

if [[ "$TEST_CHANGES" -gt 0 ]]; then
  exit 0  # Test file changes exist — TDD likely being followed
fi

# --- Debounce: don't nag more than once per 120 seconds ---
REPO_ID=$(git rev-parse --show-toplevel 2>/dev/null | md5 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null | md5sum 2>/dev/null | cut -d' ' -f1 || echo "unknown")
DEBOUNCE_FILE="/tmp/.tdd-edit-guard-${REPO_ID}"

if [[ -f "$DEBOUNCE_FILE" ]]; then
  # macOS: stat -f %m; Linux: stat -c %Y
  FILE_MTIME=$(stat -f %m "$DEBOUNCE_FILE" 2>/dev/null || stat -c %Y "$DEBOUNCE_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  AGE=$(( NOW - FILE_MTIME ))
  if [[ "$AGE" -lt 120 ]]; then
    exit 0  # Already warned recently
  fi
fi

touch "$DEBOUNCE_FILE"

# --- Warn: production code edit without test changes ---
BASENAME=$(basename "$FILE_PATH")

jq -n \
  --arg reason "TDD GUARD (Layer 2): Editing production code ($BASENAME) but no test files have been modified yet. Write a failing test first, then make it pass by editing production code." \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "ask",
      "permissionDecisionReason": $reason
    }
  }'
