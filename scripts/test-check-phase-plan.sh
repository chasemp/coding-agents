#!/usr/bin/env bash
# Tests for scripts/check-phase-plan.sh.
#
# Each refusal fixture copies the live tree into a fresh temp directory,
# breaks one thing, runs the check against the copy, and passes only when
# the check exits non-zero AND prints a line starting "FAIL <expected id>:".
# Matching the id (not just the exit code) is what stops a crash, or a
# failure from some other assertion, from counting as a refusal.
#
# Anchor fixtures are generated from the check's own table
# (--list-anchors), so a phase that adds an anchor gets its fixture for
# free. The real tree is the independent oracle: a typo in a table literal
# fails the pass fixture.
#
# Portable to bash 3.2 and BSD tools. Usage: bash scripts/test-check-phase-plan.sh

set -u

SRC="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$SRC/scripts/check-phase-plan.sh"
MAIN="skills/phase-plan.md"

passed=0
failed=0
TMPS=""
cleanup() { for d in $TMPS; do rm -rf "$d"; done; }
trap cleanup EXIT

if [ ! -f "$CHECK" ]; then
  echo "FAIL setup: $CHECK does not exist"
  exit 1
fi

# --- helpers ---------------------------------------------------------------

new_copy() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/check-phase-plan.XXXXXX")"
  TMPS="$TMPS $d"
  cp -R "$SRC/skills" "$SRC/commands" "$d/"
  cp "$SRC"/*.md "$d/"
  echo "$d"
}

# Fixed-string edits (the literals hold **, § and backticks). Each helper
# exits 2 when it changed nothing, so a fixture whose target text has gone
# reports a setup error instead of silently testing nothing.

delete_lines_with() { # file literal
  local f="$1" lit="$2" tmp
  tmp="$f.tmp"
  LC_ALL=C awk -v lit="$lit" 'index($0, lit) { hit=1; next } { print } END { exit hit ? 0 : 2 }' "$f" > "$tmp" || { rm -f "$tmp"; return 2; }
  mv "$tmp" "$f"
}

replace_all() { # file old new
  local f="$1" old="$2" new="$3" tmp
  tmp="$f.tmp"
  LC_ALL=C awk -v old="$old" -v new="$new" '
    {
      out = ""; line = $0
      while ((i = index(line, old)) > 0) { out = out substr(line, 1, i - 1) new; line = substr(line, i + length(old)); hit = 1 }
      print out line
    }
    END { exit hit ? 0 : 2 }' "$f" > "$tmp" || { rm -f "$tmp"; return 2; }
  mv "$tmp" "$f"
}

replace_on_table_rows() { # file old new  (only lines starting with "|")
  local f="$1" old="$2" new="$3" tmp
  tmp="$f.tmp"
  LC_ALL=C awk -v old="$old" -v new="$new" '
    /^\|/ && (i = index($0, old)) > 0 && !hit { $0 = substr($0, 1, i - 1) new substr($0, i + length(old)); hit = 1 }
    { print }
    END { exit hit ? 0 : 2 }' "$f" > "$tmp" || { rm -f "$tmp"; return 2; }
  mv "$tmp" "$f"
}

delete_table_rows() { # file
  local f="$1" tmp
  tmp="$f.tmp"
  LC_ALL=C awk '/^\|/ { hit=1; next } { print } END { exit hit ? 0 : 2 }' "$f" > "$tmp" || { rm -f "$tmp"; return 2; }
  mv "$tmp" "$f"
}

comment_out_lines_with() { # file literal
  local f="$1" lit="$2" tmp
  tmp="$f.tmp"
  LC_ALL=C awk -v lit="$lit" 'index($0, lit) { print "<!-- " $0 " -->"; hit=1; next } { print } END { exit hit ? 0 : 2 }' "$f" > "$tmp" || { rm -f "$tmp"; return 2; }
  mv "$tmp" "$f"
}

append_line() { # file line
  printf '%s\n' "$2" >> "$1"
}

strip_all_section_signs() { # root
  local f
  for f in $(find "$1/skills" "$1/commands" -name '*.md') "$1"/*.md; do
    replace_all "$f" "§" "" || true
  done
}

record() { # status name detail
  if [ "$1" = PASS ]; then passed=$((passed + 1)); else failed=$((failed + 1)); fi
  echo "$1 $2 ($3)"
}

# expect_refused NAME ID SETUP_FN [ARGS...]
expect_refused() {
  local name="$1" id="$2"; shift 2
  local root out rc got
  root="$(new_copy)"
  if ! "$@" "$root"; then
    record FAIL "$name" "setup error: fixture target text not found"
    return
  fi
  out="$("$BASH" "$CHECK" "$root" 2>&1)"; rc=$?
  got="$(printf '%s\n' "$out" | awk '/^FAIL / { sub(/^FAIL /, ""); sub(/: .*/, ""); print }' | sort -u | tr '\n' ' ')"
  if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | awk -v want="FAIL $id:" 'index($0, want) == 1 { found=1 } END { exit found ? 0 : 1 }'; then
    record PASS "$name" "expected $id, got ${got:-none}"
  else
    record FAIL "$name" "expected $id, got ${got:-none}, exit $rc"
  fi
}

# --- fixture setups (each takes the copy root as its last argument) --------

fx_table_missing_file() { replace_on_table_rows "$1/$MAIN" "pass3.md" "pass9.md"; }
fx_table_no_rows()      { delete_table_rows "$1/$MAIN"; }
fx_path_brace()         { replace_all "$1/$MAIN" "pass{1,2,3}.md" "pass{1,2,4}.md"; }
fx_section_injected()   { append_line "$1/skills/phase-plan/pass3.md" 'See `execute.md` § No such heading here.'; }
fx_section_none()       { strip_all_section_signs "$1"; }
fx_section_one_word()   { append_line "$1/skills/phase-plan/pass3.md" 'See `execute.md` § Step 9 does not exist.'; }
fx_section_allow_gone() { delete_lines_with "$1/external-learn.md" "§ Mock misuse"; }
fx_section_allow()      { append_line "$1/skills/testing-anti-patterns.md" "## Mock misuse"; }
fx_marker()             { replace_all "$1/$MAIN" "TRACKING: File split (2026-04-16)" "TRACKING: File gone"; }
fx_anchor_removed()     { delete_lines_with "$2/$1" "$ANCHOR_LITERAL"; }
fx_absent_added()       { append_line "$2/$1" "$ABSENT_LITERAL"; }
fx_route_removed()      { replace_on_table_rows "$1/$MAIN" "$ROUTE_PHRASE" '"no such trigger"'; }
fx_anchor_in_comment()  { comment_out_lines_with "$1/$MAIN" "**reachability gate**"; }
fx_anchor_moved()       {
  delete_lines_with "$1/skills/phase-plan/pass3.md" "**Plan file:**" &&
    append_line "$1/skills/phase-plan/pass3.md" '> **Plan file:** `plans/x.md`'
}

# --- pass fixtures ----------------------------------------------------------

expect_clean() { # name root-or-empty
  local name="$1" root="$2" out rc fails count
  if [ -n "$root" ]; then out="$("$BASH" "$CHECK" "$root" 2>&1)"; else out="$("$BASH" "$CHECK" 2>&1)"; fi
  rc=$?
  fails="$(printf '%s\n' "$out" | grep -c '^FAIL ')"
  count="$(printf '%s\n' "$out" | sed -n 's/^check-phase-plan: \([0-9][0-9]*\) assertions.*/\1/p')"
  if [ "$rc" -eq 0 ] && [ "$fails" -eq 0 ] && [ -n "$count" ] && [ "$count" -gt 0 ]; then
    record PASS "$name" "exit 0, $count assertions"
  else
    record FAIL "$name" "exit $rc, $fails FAIL lines, assertions '${count:-none}'"
    printf '%s\n' "$out" | grep '^FAIL ' | sed 's/^/    /'
  fi
}

# --- run --------------------------------------------------------------------

expect_clean "pass: unmodified copy" "$(new_copy)"
expect_clean "pass: default root (real tree)" ""

expect_refused "table names a missing file" CHK-TABLE fx_table_missing_file
expect_refused "table has no rows" CHK-TABLE fx_table_no_rows
expect_refused "brace path names a missing file" CHK-PATH fx_path_brace
expect_refused "section reference does not resolve" CHK-SECTION fx_section_injected
expect_refused "reference matches only a heading's first word" CHK-SECTION fx_section_one_word
expect_refused "no section references extracted" CHK-SECTION fx_section_none
expect_refused "allowlisted reference no longer appears" CHK-SECTION-ALLOW fx_section_allow_gone
expect_refused "allowlisted reference now resolves" CHK-SECTION-ALLOW fx_section_allow
expect_refused "split marker gone from main file" CHK-MARKER fx_marker
expect_refused "anchor only inside a comment" CHK-ANCHOR:reachability-gate fx_anchor_in_comment
expect_refused "anchor moved to another section" CHK-ANCHOR:plan-file-pass3 fx_anchor_moved

anchors="$("$BASH" "$CHECK" --list-anchors)" || { echo "FAIL setup: --list-anchors failed"; exit 1; }
n_anchors="$(printf '%s\n' "$anchors" | grep -c '|')"
if [ "$n_anchors" -lt 1 ]; then
  record FAIL "anchor table" "--list-anchors printed no anchors"
fi
while IFS='|' read -r a_name a_file a_section a_literal; do
  [ -n "$a_name" ] || continue
  ANCHOR_LITERAL="$a_literal"
  expect_refused "anchor removed: $a_name" "CHK-ANCHOR:$a_name" fx_anchor_removed "$a_file"
done <<EOF
$anchors
EOF

absent="$("$BASH" "$CHECK" --list-absent)" || { echo "FAIL setup: --list-absent failed"; exit 1; }
while IFS='|' read -r x_name x_file x_literal; do
  [ -n "$x_name" ] || continue
  [ "$x_file" = "*" ] && x_file="skills/phase-plan/pass3.md"
  ABSENT_LITERAL="$x_literal"
  expect_refused "retired phrase added back: $x_name" "CHK-ABSENT:$x_name" fx_absent_added "$x_file"
done <<EOF
$absent
EOF

routes="$("$BASH" "$CHECK" --list-table-map)" || { echo "FAIL setup: --list-table-map failed"; exit 1; }
while IFS='|' read -r m_name m_phrase m_file; do
  [ -n "$m_name" ] || continue
  ROUTE_PHRASE="$m_phrase"
  expect_refused "table route removed: $m_name" "CHK-TABLE-MAP:$m_name" fx_route_removed
done <<EOF
$routes
EOF

echo "test-check-phase-plan: $passed passed, $failed failed ($n_anchors anchor fixtures)"
[ "$failed" -eq 0 ]
