#!/usr/bin/env bash
# Structural check for the phase-plan skill text.
#
# Usage: bash scripts/check-phase-plan.sh [ROOT]
#        bash scripts/check-phase-plan.sh --list-anchors | --list-absent | --list-table-map
#
# ROOT defaults to this script's parent directory (not git: the fixture
# copies made by scripts/test-check-phase-plan.sh have no .git).
#
# Output: one line per failure, "FAIL <id>: <file>:<line> <detail>", then
# "check-phase-plan: <n> assertions, <m> failed". Exit 1 when m > 0.
#
# Ids:
#   CHK-TABLE          main file's loading table: >= 5 rows, every named file exists
#   CHK-PATH           every skills/phase-plan/<name>.md path in a live file exists
#   CHK-SECTION        every `<file>.md` § <words> reference in a live file resolves to a
#                      heading in a live file or ledger; >= 10 extracted
#   CHK-SECTION-ALLOW  allowlisted illustrative references still exist and still do not resolve
#   CHK-MARKER         skills/phase-plan.md holds the split marker
#   CHK-ANCHOR:<name>  an applied change's literal is still in its own section
#   CHK-ABSENT:<name>  a retired phrase is gone from its file (or every live file)
#   CHK-TABLE-MAP:<name> some loading-table row holds both a trigger phrase and its file
#
# "Live" files: skills/ (except skills/phase-plan/CHANGELOG.md), commands/,
# and the root .md files except the two ledgers. plans/ and .claude/ are
# out of scope. Text inside <!-- --> comments is ignored everywhere except
# for CHK-MARKER, which is itself a comment.
#
# Portable to bash 3.2 and BSD awk/grep/sed.

set -u
export LC_ALL=C

MAIN="skills/phase-plan.md"
MIN_TABLE_ROWS=5
MIN_SECTION_REFS=10
SPLIT_MARKER="TRACKING: File split (2026-04-16)"

# Applied changes the rewrite must keep (plan VA-11), as
# name|file|section heading prefix|literal. Section "^" means the text
# before the first heading (front matter).
ANCHORS='ask-questions-xref|skills/phase-plan/pass1.md|Steps|`ask-questions-if-underspecified` skill first
docimpact-template|skills/phase-plan.md|Documentation Impact|Every doc file that will be added, renamed, moved, removed, or
docimpact-inventory|skills/phase-plan/pass1.md|Steps|**Inventory documentation impact.**
docimpact-gate|skills/phase-plan/pass3.md|Checks|**7. Documentation impact coverage**
docimpact-checklist|skills/phase-plan/execute.md|Phase completion checklist|**Documentation updates scheduled for this phase are done.**
one-plan|skills/phase-plan.md|One plan, three passes|## One plan, three passes
banner-pass1|skills/phase-plan/pass1.md|Phase Plan — Pass 1|> **Not a plan template.**
banner-pass2|skills/phase-plan/pass2.md|Phase Plan — Pass 2|> **Not a plan template.**
banner-pass3|skills/phase-plan/pass3.md|Phase Plan — Pass 3|> **Not a plan template.**
batch-trigger|skills/phase-plan.md|^|ALSO trigger when a batch of work approved in CONVERSATION
batch-section|skills/phase-plan.md|A batch approved in conversation|### A batch approved in conversation
new-entry-point|skills/phase-plan.md|Guardrails|A new entry point invalidates every prior "wired" claim
reachability-gate|skills/phase-plan.md|Guardrails|**reachability gate**
plan-file-pass1|skills/phase-plan/pass1.md|Output|**Plan file:**
plan-file-pass2|skills/phase-plan/pass2.md|Output|**Plan file:**
plan-file-pass3|skills/phase-plan/pass3.md|Output|**Plan file:**
plan-matches-reality|skills/phase-plan/execute.md|The execution reminder|Plan matches reality.
exec-guardrails|skills/phase-plan/execute.md|Execution guardrails|## Execution guardrails (repeated for forefront)
reminders-pass1|skills/phase-plan/pass1.md|Reminders|## Reminders (critical, repeated for forefront)
reminders-pass2|skills/phase-plan/pass2.md|Reminders|## Reminders (critical, repeated for forefront)
reminders-pass3|skills/phase-plan/pass3.md|Reminders|## Reminders (critical, repeated for forefront)
step4-consolidate|skills/phase-plan/execute.md|Step 4|### Step 4 — Consolidate locally
closeout-template|skills/phase-plan/execute.md|When the plan closes|### Plan close-out — YYYY-MM-DD
worktree-removal|skills/phase-plan/execute.md|When the plan closes|**The plan'"'"'s worktrees and branches are removed**
agents-scripts-row|agents.md|File reference|`scripts/`
walkthrough-procedure|skills/phase-plan/walk-through.md|Procedure|## Procedure
walkthrough-mapping|skills/phase-plan/walk-through.md|Review grades and question tags|a BLOCKER finding that needs a user decision becomes a BLOCKING question
walkthrough-wired|skills/phase-plan.md|Guardrails|`skills/phase-plan/walk-through.md`
p1-gap-heading|skills/phase-plan/pass1.md|Gap-analysis step|## Gap-analysis step
p1-reverse-search|skills/phase-plan/pass1.md|Gap-analysis step|**Reverse search.**
p1-value-domains|skills/phase-plan/pass1.md|Gap-analysis step|**Value domains, not existence.**
p1-sibling-table|skills/phase-plan/pass1.md|Gap-analysis step|**Sibling comparison table**
p1-neighbour-check|skills/phase-plan/pass1.md|Gap-analysis step|**Neighbour check.**
p1-probe-heading|skills/phase-plan/pass1.md|Probe rules|## Probe rules
p1-probe-readonly|skills/phase-plan/pass1.md|Probe rules|**Read-only by definition.**
p1-not-observed-live|skills/phase-plan/pass1.md|Probe rules|not observed live
p1-delivery-shape|skills/phase-plan/pass1.md|Steps|**Fill the Delivery shape section.**
p1-size-rule|skills/phase-plan/pass1.md|Steps|3 files maximum; 4 or more must split
p1-next-pass|skills/phase-plan/pass1.md|Next pass handoff|## Next pass handoff
p1-compacted|skills/phase-plan/pass1.md|Next pass handoff|A compacted context is not fresh
p1-walkthrough-ref|skills/phase-plan/pass1.md|Output|`walk-through.md`
p2-lens-a|skills/phase-plan/pass2.md|Lens A|### Lens A: outcome and failure walk
p2-lens-b|skills/phase-plan/pass2.md|Lens B|### Lens B: outward consistency
p2-lens-c|skills/phase-plan/pass2.md|Lens C|### Lens C: facts against code and live data
p2-brief|skills/phase-plan/pass2.md|Reviewer brief|## Reviewer brief
p2-refute-first|skills/phase-plan/pass2.md|Reviewer brief|Refute first
p2-model|skills/phase-plan/pass2.md|Running the reviewers|pass `model` explicitly
p2-vetting|skills/phase-plan/pass2.md|Vetting|## Vetting
p2-rerun|skills/phase-plan/pass2.md|When to re-run|## When to re-run
p2-next-pass|skills/phase-plan/pass2.md|Output|`pass1.md` § Next pass handoff
main-base-dir|skills/phase-plan.md|Loading the Per-Pass Files|`~/.claude/coding-agents/skills/phase-plan/`
p1-quick-close|skills/phase-plan/pass1.md|Output|Pass 3 for a quick plan
p1-paste-loads-main|skills/phase-plan/pass1.md|Next pass handoff|starts with `/phase-plan <pass> <absolute plan path>`'

# Retired phrases, as name|file|literal. File "*" means every live file.
# Checked outside comments, so history in TRACKING blocks may still quote them.
ABSENT='p1-confirm-as|skills/phase-plan/pass1.md|Confirm as [SEVERITY]
p1-confirm-severity|skills/phase-plan/pass1.md|to confirm severity
p2-old-title|skills/phase-plan/pass2.md|Pass 2: Gap Analysis
route-pass12-gone|skills/phase-plan.md|"pass 1+2" / "plan and review together"
quick-skips-pass2|skills/phase-plan.md|`pass1.md`, `pass2.md`, and `pass3.md` together
p2-blocker-only|skills/phase-plan/pass2.md|every BLOCKER and every new fact'

# Loading-table routes, as name|trigger phrase|file basename: some row of the
# main file's loading table holds both.
TABLE_MAP='route-pass1|"pass 1"|pass1.md
route-lets-plan|"let'"'"'s plan"|pass1.md
route-gap|"gap analysis"|pass1.md
route-pass2|"pass 2"|pass2.md
route-independent|"independent review"|pass2.md
route-review-plan|"review the plan"|pass2.md
route-plan-review|"plan review"|pass2.md
route-pass3|"pass 3"|pass3.md
route-quality|"quality gates"|pass3.md
route-final|"final review"|pass3.md
route-execute|"let'"'"'s execute"|execute.md
route-decisions|any list of decisions|walk-through.md'

# Illustrative § references that are not meant to resolve, as
# source basename|target basename|normalised words|reason.
# A listed reference that starts to resolve, or disappears, fails: the list
# can only shrink.
SECTION_ALLOW='external-learn.md|testing-anti-patterns.md|mock misuse|example of a specific overlap claim, not a link'

case "${1:-}" in
  --list-anchors) printf '%s\n' "$ANCHORS"; exit 0 ;;
  --list-absent) printf '%s\n' "$ABSENT"; exit 0 ;;
  --list-table-map) printf '%s\n' "$TABLE_MAP"; exit 0 ;;
esac

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
if [ ! -f "$ROOT/$MAIN" ]; then
  echo "FAIL CHK-TABLE: $MAIN missing under $ROOT"
  echo "check-phase-plan: 1 assertions, 1 failed"
  exit 1
fi

assertions=0
failures=0
pass_() { assertions=$((assertions + 1)); }
fail_() { assertions=$((assertions + 1)); failures=$((failures + 1)); echo "FAIL $1: $2"; }

# Live files, relative to ROOT, one per line.
live_files() {
  ( cd "$ROOT" &&
    { find skills commands -name '*.md' 2>/dev/null; ls *.md 2>/dev/null; } |
      grep -v -e '^skills/phase-plan/CHANGELOG\.md$' -e '^REFINEMENTS\.md$' -e '^EXTERNAL-LEARNINGS\.md$' |
      sort )
}

# Print FILE with <!-- --> comment text blanked, keeping line numbers.
strip_comments() {
  awk '{
    out = ""; line = $0
    while (1) {
      if (inc) { j = index(line, "-->"); if (!j) { line = ""; break } line = substr(line, j + 3); inc = 0 }
      i = index(line, "<!--"); if (!i) { out = out line; break }
      out = out substr(line, 1, i - 1); line = substr(line, i + 4); inc = 1
    }
    print out
  }' "$1"
}

LIVE="$(live_files)"
# Reference targets: the live files plus the ledgers. Ledgers hold history,
# so references are not read from them, but they are valid things to point at.
TARGETS="$(printf '%s\nREFINEMENTS.md\nEXTERNAL-LEARNINGS.md\n' "$LIVE" | while read -r t; do [ -f "$ROOT/$t" ] && echo "$t"; done)"

# --- CHK-TABLE ---------------------------------------------------------------

table_cells="$(strip_comments "$ROOT/$MAIN" | awk '
  /^#+ / { insec = (index($0, "Loading the Per-Pass Files") > 0); next }
  insec && /^\|/ {
    if ($0 ~ /^\|[-| ]+\|$/ || index($0, "User says")) next
    rows++; line = $0
    while (match(line, /`[^`]*\.md`/)) { print NR "|" substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH) }
  }
  END { print "ROWS|" rows + 0 }')"
rows="$(printf '%s\n' "$table_cells" | sed -n 's/^ROWS|//p')"
if [ "$rows" -ge "$MIN_TABLE_ROWS" ]; then pass_; else fail_ CHK-TABLE "$MAIN: loading table has $rows rows, need at least $MIN_TABLE_ROWS"; fi
while IFS='|' read -r ln cell; do
  [ "$ln" = ROWS ] && continue
  [ -n "$cell" ] || continue
  base="${cell##*/}"
  if [ -f "$ROOT/skills/phase-plan/$base" ]; then pass_; else fail_ CHK-TABLE "$MAIN:$ln loading table names $cell, not found under skills/phase-plan/"; fi
done <<EOF
$table_cells
EOF

table_rows="$(strip_comments "$ROOT/$MAIN" | awk '
  /^#+ / { insec = (index($0, "Loading the Per-Pass Files") > 0); next }
  insec && /^\|/ { print }')"
while IFS='|' read -r m_name m_phrase m_file; do
  [ -n "$m_name" ] || continue
  if printf '%s\n' "$table_rows" | awk -v a="$m_phrase" -v b="$m_file\`" 'index($0, a) && index($0, b) { found = 1 } END { exit found ? 0 : 1 }'; then
    pass_
  else
    fail_ "CHK-TABLE-MAP:$m_name" "$MAIN: no loading-table row holds both $m_phrase and \`$m_file\`"
  fi
done <<EOF
$TABLE_MAP
EOF

# --- CHK-PATH ----------------------------------------------------------------

for f in $LIVE; do
  strip_comments "$ROOT/$f" | awk -v f="$f" '{
    line = $0
    while (match(line, /skills\/phase-plan\/[A-Za-z0-9_.{},-]+\.md/)) { print f "|" NR "|" substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH) }
  }'
done > "${TMPDIR:-/tmp}/check-phase-plan-paths.$$"
while IFS='|' read -r f ln p; do
  [ -n "$p" ] || continue
  case "$p" in
    *'{'*'}'*)
      prefix="${p%%\{*}"; rest="${p#*\{}"; inner="${rest%%\}*}"; suffix="${rest#*\}}"
      expanded="$(printf '%s\n' "$inner" | tr ',' '\n' | sed "s|^|$prefix|; s|\$|$suffix|")" ;;
    *) expanded="$p" ;;
  esac
  for e in $expanded; do
    if [ -f "$ROOT/$e" ]; then pass_; else fail_ CHK-PATH "$f:$ln names $e (from $p), not found"; fi
  done
done < "${TMPDIR:-/tmp}/check-phase-plan-paths.$$"
rm -f "${TMPDIR:-/tmp}/check-phase-plan-paths.$$"

# --- CHK-SECTION / CHK-SECTION-ALLOW -----------------------------------------

# Normalised headings of a file, one per line.
headings_of() {
  strip_comments "$1" | awk '/^#+ / { sub(/^#+ +/, ""); h = tolower($0); gsub(/[^a-z0-9 ]/, "", h); gsub(/ +/, " ", h); sub(/^ /, "", h); sub(/ $/, "", h); print h }'
}

# 0 when the reference words resolve to one of the headings on stdin.
resolves() { # words
  awk -v ref="$1" '
    BEGIN { nr = split(ref, r, " ") }
    {
      nh = split($0, h, " "); k = 0
      while (k < nr && k < nh && r[k + 1] == h[k + 1]) k++
      need = 2; if (nh < need) need = nh; if (nr < need) need = nr
      if (need > 0 && k >= need) { found = 1; exit }
    }
    END { exit found ? 0 : 1 }'
}

refs=0
seen_allow=""
for f in $LIVE; do
  strip_comments "$ROOT/$f" | awk -v f="$f" '{
    line = $0
    while (match(line, /`[A-Za-z0-9_.\/-]+\.md` §/)) {
      target = substr(line, RSTART + 1, RLENGTH - 1); sub(/` §$/, "", target)
      line = substr(line, RSTART + RLENGTH)
      words = line; sub(/^ +/, "", words)
      if (match(words, /[`*.,;:()"]/)) words = substr(words, 1, RSTART - 1)
      w = tolower(words); gsub(/[^a-z0-9 ]/, "", w); gsub(/ +/, " ", w); sub(/^ /, "", w); sub(/ $/, "", w)
      print f "|" NR "|" target "|" w "|" words
    }
  }'
done > "${TMPDIR:-/tmp}/check-phase-plan-refs.$$"
while IFS='|' read -r f ln target words raw; do
  [ -n "$f" ] || continue
  refs=$((refs + 1))
  tbase="${target##*/}"
  matches="$(printf '%s\n' "$TARGETS" | awk -v b="$tbase" '{ n = split($0, p, "/"); if (p[n] == b) print }')"
  count="$(printf '%s' "$matches" | grep -c .)"
  allow_key="${f##*/}|$tbase|$words|"
  allowed=0
  case "$SECTION_ALLOW" in *"$allow_key"*) allowed=1; seen_allow="$seen_allow
$allow_key" ;; esac
  if [ "$count" -ne 1 ]; then
    fail_ CHK-SECTION "$f:$ln \`$target\` § $raw: $count files named $tbase among the targets"
    continue
  fi
  if [ -z "$words" ]; then
    fail_ CHK-SECTION "$f:$ln \`$target\` §: no heading text after the section sign"
    continue
  fi
  if headings_of "$ROOT/$matches" | resolves "$words"; then
    if [ "$allowed" -eq 1 ]; then fail_ CHK-SECTION-ALLOW "$f:$ln \`$target\` § $raw now resolves; remove it from SECTION_ALLOW"; else pass_; fi
  else
    if [ "$allowed" -eq 1 ]; then pass_; else fail_ CHK-SECTION "$f:$ln \`$target\` § $raw: no heading in $matches starts with those words"; fi
  fi
done < "${TMPDIR:-/tmp}/check-phase-plan-refs.$$"
rm -f "${TMPDIR:-/tmp}/check-phase-plan-refs.$$"
if [ "$refs" -ge "$MIN_SECTION_REFS" ]; then pass_; else fail_ CHK-SECTION "live scope: $refs section references extracted, need at least $MIN_SECTION_REFS (extractor broken?)"; fi
while IFS='|' read -r a_src a_target a_words a_reason; do
  [ -n "$a_src" ] || continue
  case "$seen_allow" in
    *"$a_src|$a_target|$a_words|"*) pass_ ;;
    *) fail_ CHK-SECTION-ALLOW "SECTION_ALLOW entry $a_src → $a_target § $a_words no longer appears; remove it" ;;
  esac
done <<EOF
$SECTION_ALLOW
EOF

# --- CHK-MARKER --------------------------------------------------------------

if grep -qF "$SPLIT_MARKER" "$ROOT/$MAIN"; then pass_; else fail_ CHK-MARKER "$MAIN: missing \"$SPLIT_MARKER\""; fi

# --- CHK-ANCHOR --------------------------------------------------------------

while IFS='|' read -r a_name a_file a_section a_literal; do
  [ -n "$a_name" ] || continue
  if [ ! -f "$ROOT/$a_file" ]; then fail_ "CHK-ANCHOR:$a_name" "$a_file not found"; continue; fi
  if strip_comments "$ROOT/$a_file" | awk -v sec="$a_section" -v lit="$a_literal" '
      /^#+ / { h = $0; sub(/^#+ +/, "", h); insec = (sec != "^" && index(h, sec) == 1); started = 1 }
      { if ((sec == "^" && !started) || insec) if (index($0, lit)) { found = 1; exit } }
      END { exit found ? 0 : 1 }'; then
    pass_
  else
    fail_ "CHK-ANCHOR:$a_name" "$a_file: \"$a_literal\" not found in section \"$a_section\" (outside comments)"
  fi
done <<EOF
$ANCHORS
EOF

# --- CHK-ABSENT --------------------------------------------------------------

while IFS='|' read -r x_name x_file x_literal; do
  [ -n "$x_name" ] || continue
  if [ "$x_file" = "*" ]; then x_files="$LIVE"; else x_files="$x_file"; fi
  x_hits=""
  for f in $x_files; do
    [ -f "$ROOT/$f" ] || continue
    h="$(strip_comments "$ROOT/$f" | awk -v lit="$x_literal" -v f="$f" 'index($0, lit) { printf "%s:%d ", f, NR }')"
    x_hits="$x_hits$h"
  done
  if [ -z "$x_hits" ]; then pass_; else fail_ "CHK-ABSENT:$x_name" "\"$x_literal\" still present at $x_hits"; fi
done <<EOF
$ABSENT
EOF

# --- sizes (reported; made a failing assertion in a later phase) -------------

for pair in "$MAIN:500" "CLAUDE.md:200"; do
  f="${pair%%:*}"; budget="${pair##*:}"
  [ -f "$ROOT/$f" ] && echo "INFO size $f $(wc -l < "$ROOT/$f" | tr -d ' ')/$budget lines"
done

echo "check-phase-plan: $assertions assertions, $failures failed"
[ "$failures" -eq 0 ]
