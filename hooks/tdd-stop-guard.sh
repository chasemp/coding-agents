#!/bin/bash
# TDD Stop Guard — Layer 1 (hardest backstop)
# Hook type: Stop
# Blocks session completion when production code was modified without
# corresponding test file changes in the working tree.
#
# This catches the case where Claude wrote production code and tries to
# wrap up without ever writing tests. It does NOT validate that tests
# pass — that's Layer 3 (pre-commit).

# Guards: skip silently if not in a git repo or jq missing
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

# Consume stdin (Stop hooks receive context JSON, but we use git state)
cat > /dev/null

# Collect all uncommitted changes (staged + unstaged + untracked new files)
CHANGED_FILES=$(
  {
    git diff --name-only 2>/dev/null
    git diff --cached --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null
  } | sort -u
)

# No changes at all — nothing to enforce
if [[ -z "$CHANGED_FILES" ]]; then
  exit 0
fi

# Pattern: files in standard source directories with code extensions
PROD_PATTERN='(src/|lib/|app/|pkg/|cmd/|internal/).*\.(py|ts|tsx|js|jsx|go|rs)$'

# Pattern: test files by path or naming convention
TEST_PATTERN='(tests?/|__tests__/|_test\.(go|py|ts|js)$|\.test\.(ts|tsx|js|jsx)$|\.spec\.(ts|tsx|js|jsx)$|/test_[^/]*\.py$|conftest\.py$)'

PROD_FILES=$(echo "$CHANGED_FILES" | grep -E "$PROD_PATTERN" || true)
TEST_FILES=$(echo "$CHANGED_FILES" | grep -E "$TEST_PATTERN" || true)

# No production file changes — nothing to enforce
if [[ -z "$PROD_FILES" ]]; then
  exit 0
fi

# Production changes exist — do test changes also exist?
if [[ -n "$TEST_FILES" ]]; then
  exit 0  # Both present — TDD likely followed
fi

# Production changes WITHOUT test changes — block
PROD_LIST=$(echo "$PROD_FILES" | head -8 | sed 's/^/  - /')
PROD_COUNT=$(echo "$PROD_FILES" | wc -l | tr -d ' ')

jq -n \
  --arg reason "$(cat <<MSG
TDD GUARD (Layer 1): Cannot complete session. ${PROD_COUNT} production file(s) modified without any corresponding test changes:

${PROD_LIST}

Either:
  1. Write tests for these changes (preferred — TDD)
  2. Commit your current work so the pre-commit hook can validate
  3. Revert the production changes if they were exploratory
MSG
)" \
  '{
    "hookSpecificOutput": {
      "decision": "block",
      "reason": $reason
    }
  }'
