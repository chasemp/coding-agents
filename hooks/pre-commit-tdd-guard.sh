#!/bin/bash
# TDD Pre-Commit Guard — Layer 3 (strictest enforcement)
# Hook type: git pre-commit (lives in .git/hooks/pre-commit)
#
# Rejects commits where production source files are staged without
# any corresponding test file changes. Optionally runs the test suite.
#
# This is the hardest gate: no commit gets through without evidence
# of test-driven development. Unlike Layers 1-2 (Claude Code hooks),
# this applies to ALL commits — Claude or human.
#
# INSTALLATION (in consuming repo):
#   Option A — symlink:
#     ln -sf ~/.claude/hooks/pre-commit-tdd-guard.sh .git/hooks/pre-commit
#
#   Option B — copy:
#     cp ~/.claude/hooks/pre-commit-tdd-guard.sh .git/hooks/pre-commit
#     chmod +x .git/hooks/pre-commit
#
#   Option C — if using pre-commit framework, add as a local hook.
#
# CONFIGURATION (environment variables):
#   TDD_GUARD_RUN_TESTS=1     — also run test suite before allowing commit
#   TDD_GUARD_TEST_CMD="..."  — custom test command (default: auto-detect)
#   TDD_GUARD_STRICT=1        — require test:prod file ratio >= 1:1
#   TDD_GUARD_SKIP_DIRS="..."  — colon-separated dirs to exclude from prod check

set -euo pipefail

# Opt-out: .notdd in repo root disables all TDD enforcement for this repo
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -n "$REPO_ROOT" ]] && [[ -f "$REPO_ROOT/.notdd" ]]; then
  exit 0
fi

# --- Collect staged files (Added, Copied, Modified only) ---
STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)

if [[ -z "$STAGED" ]]; then
  exit 0  # Nothing staged
fi

# --- Configurable source directories ---
SKIP_DIRS="${TDD_GUARD_SKIP_DIRS:-}"
PROD_PATTERN='(src/|lib/|app/|pkg/|cmd/|internal/).*\.(py|ts|tsx|js|jsx|go|rs)$'
TEST_PATTERN='(tests?/|__tests__/|_test\.(go|py|ts|js)$|\.test\.(ts|tsx|js|jsx)$|\.spec\.(ts|tsx|js|jsx)$|/test_[^/]*\.py$|conftest\.py$)'

PROD_FILES=$(echo "$STAGED" | grep -E "$PROD_PATTERN" || true)
TEST_FILES=$(echo "$STAGED" | grep -E "$TEST_PATTERN" || true)

# Filter out skip dirs
if [[ -n "$SKIP_DIRS" ]]; then
  IFS=':' read -ra SKIP_ARRAY <<< "$SKIP_DIRS"
  for dir in "${SKIP_ARRAY[@]}"; do
    PROD_FILES=$(echo "$PROD_FILES" | grep -v "^${dir}/" || true)
  done
fi

# --- No production files staged — allow ---
if [[ -z "$PROD_FILES" ]]; then
  exit 0
fi

PROD_COUNT=$(echo "$PROD_FILES" | wc -l | tr -d ' ')

# --- No test files staged — reject ---
if [[ -z "$TEST_FILES" ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  TDD GUARD (Layer 3): Commit rejected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "  ${PROD_COUNT} production file(s) staged without any test files:"
  echo ""
  echo "$PROD_FILES" | sed 's/^/    - /'
  echo ""
  echo "  Write tests first (TDD), then commit both together."
  echo "  Emergency bypass: git commit --no-verify"
  echo ""
  exit 1
fi

TEST_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d ' ')

# --- Optional strict mode: require ratio ---
if [[ "${TDD_GUARD_STRICT:-0}" == "1" ]]; then
  if [[ "$TEST_COUNT" -lt "$PROD_COUNT" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  TDD GUARD (Layer 3, strict): Insufficient test coverage"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  ${PROD_COUNT} production file(s) but only ${TEST_COUNT} test file(s) staged."
    echo "  Strict mode requires at least 1:1 ratio."
    echo ""
    exit 1
  fi
fi

# --- Optional: run test suite ---
if [[ "${TDD_GUARD_RUN_TESTS:-0}" == "1" ]]; then
  TEST_CMD="${TDD_GUARD_TEST_CMD:-}"

  # Auto-detect test command if not specified
  if [[ -z "$TEST_CMD" ]]; then
    if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
      TEST_CMD="python -m pytest --tb=short -q"
    elif [[ -f "package.json" ]]; then
      TEST_CMD="npm test"
    elif [[ -f "go.mod" ]]; then
      TEST_CMD="go test ./..."
    elif [[ -f "Cargo.toml" ]]; then
      TEST_CMD="cargo test"
    fi
  fi

  if [[ -n "$TEST_CMD" ]]; then
    echo "TDD GUARD: Running tests ($TEST_CMD)..."
    if ! eval "$TEST_CMD"; then
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "  TDD GUARD (Layer 3): Tests failed — commit rejected"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      exit 1
    fi
  fi
fi

# Both production and test files staged — allow
exit 0
