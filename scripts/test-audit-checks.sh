#!/usr/bin/env bash
# Tests for scripts/audit-checks.sh and how commands/audit.md calls it.
#
# Claude Code refuses a `!` shell line in a command file when the line uses a
# shell variable, which stops /audit before any check runs. So every line that
# needs one calls scripts/audit-checks.sh <name> instead.
#
# Usage: bash scripts/test-audit-checks.sh

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AUDIT="$ROOT/commands/audit.md"
SCRIPT="$ROOT/scripts/audit-checks.sh"
passed=0
failed=0
record() { if [ "$1" = PASS ]; then passed=$((passed + 1)); else failed=$((failed + 1)); fi; echo "$1 $2"; }

# 1. No `!` line in commands/audit.md contains a `$`.
bad="$(grep -n '^!`' "$AUDIT" | grep -F '$')"
if [ -z "$bad" ]; then
  record PASS "no shell variable in any ! line of commands/audit.md"
else
  record FAIL "shell variable in ! lines of commands/audit.md:"
  printf '%s\n' "$bad" | cut -c1-100 | sed 's/^/    /'
fi

# 1b. No `!` line contains an escaped backtick: the line is itself delimited
# by backticks, so the command would be cut at it.
bad="$(grep -n '^!`' "$AUDIT" | grep -F '\`')"
if [ -z "$bad" ]; then
  record PASS "no escaped backtick in any ! line of commands/audit.md"
else
  record FAIL "escaped backtick in ! lines of commands/audit.md:"
  printf '%s\n' "$bad" | cut -c1-100 | sed 's/^/    /'
fi

# 2. Every audit-checks.sh name the command uses runs and exits 0.
names="$(grep -o 'bash scripts/audit-checks.sh [a-z0-9-]*' "$AUDIT" | awk '{ print $3 }' | sort -u)"
if [ -z "$names" ]; then
  record FAIL "commands/audit.md calls no audit-checks.sh subcommand"
fi
for n in $names; do
  if [ -f "$SCRIPT" ] && (cd "$ROOT" && bash "$SCRIPT" "$n" >/dev/null 2>&1); then
    record PASS "audit-checks.sh $n exits 0"
  else
    record FAIL "audit-checks.sh $n does not exit 0"
  fi
done

# 3. An unknown name fails loudly.
if [ -f "$SCRIPT" ]; then
  (cd "$ROOT" && bash "$SCRIPT" no-such-check >/dev/null 2>&1); rc=$?
else
  rc=0
fi
if [ "$rc" -ne 0 ]; then record PASS "unknown name exits non-zero ($rc)"; else record FAIL "unknown name exits 0"; fi

echo "test-audit-checks: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
