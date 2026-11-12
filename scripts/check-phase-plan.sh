#!/usr/bin/env bash
# Structural check for the phase-plan skill text.
#
# Usage: bash scripts/check-phase-plan.sh [ROOT]
#        bash scripts/check-phase-plan.sh --list-anchors | --list-absent | --list-table-map | --list-line-limits
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
#   CHK-LINES          CLAUDE.md held at its line count at base 8e6fc33 (plan-scoped; removed at close)
#   CHK-SIZE           skills/phase-plan.md under its 500-line budget (D13)
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
p1-paste-loads-main|skills/phase-plan/pass1.md|Next pass handoff|starts with `/phase-plan <pass> <absolute plan path>`
p3-test-validity|skills/phase-plan/pass3.md|Checks|**1b. Tests that can fail**
p3-hedges|skills/phase-plan/pass3.md|Checks|**Hedges.**
p3-external-write|skills/phase-plan/pass3.md|Checks|external-write tier
p3-previous-additions|skills/phase-plan/pass3.md|Steps|start from the previous pass'"'"'s additions
p3-deliverable|skills/phase-plan/pass3.md|Steps|**Deliverable anchor.**
p3-ready|skills/phase-plan/pass3.md|Output|every walk-through answer is written into the plan and re-checked
p3-walkthrough|skills/phase-plan/pass3.md|Output|`walk-through.md`
p3-next-pass|skills/phase-plan/pass3.md|Output|`pass1.md` § Next pass handoff
claude-md-walkthrough|CLAUDE.md|Explaining Design and Protocol Work|one per message for any list of decisions
aq-walkthrough|skills/ask-questions-if-underspecified.md|Relationship to phase-plan|decision-first walk-through
tpl-problem|skills/phase-plan.md|Problem Statement|## Problem Statement
tpl-reasoning|skills/phase-plan.md|Reasoning|## Reasoning
tpl-status|skills/phase-plan.md|[Title]|**Status:** one line of current state
tpl-not-observed|skills/phase-plan.md|Verified Assumptions|"not observed live"
tpl-delivery|skills/phase-plan.md|Delivery shape|## Delivery shape
tpl-concurrency-line|skills/phase-plan.md|Concurrency Map|`All phases sequential: <reason>`
tpl-readset-optional|skills/phase-plan.md|Phase N: [Name]|**Read-set (optional):**
tpl-shared-optional|skills/phase-plan.md|Phase N: [Name]|**Shared-state contract (optional for sequential phases):**
tpl-external-write|skills/phase-plan.md|Phase N: [Name]|**External write:**
tpl-closeout|skills/phase-plan.md|Phase N+1: Close-out|"which pass should have caught this?"
tpl-walkthrough|skills/phase-plan.md|Open Questions|`walk-through.md`
tpl-execution-log|skills/phase-plan.md|Execution Log|## Execution Log
tpl-next-pass|skills/phase-plan.md|Next pass|## Next pass
m-trigger-phase-plan|skills/phase-plan.md|^|"phase plan"
m-trigger-three-pass|skills/phase-plan.md|^|"three-pass plan"
m-trigger-plan-review|skills/phase-plan.md|^|"plan review"
m-trigger-bulk-write|skills/phase-plan.md|^|bulk writes to an external system
m-compat-heading|skills/phase-plan.md|Compatibility rule|## Compatibility rule
m-compat-label|skills/phase-plan.md|Compatibility rule|other than `Pass 2: Independent review`
m-changelog-pointer|skills/phase-plan.md|Per-pass skill files|`skills/phase-plan/CHANGELOG.md`
m-files-walkthrough|skills/phase-plan.md|Per-pass skill files|`walk-through.md`
m-guardrail-replace|skills/phase-plan.md|Guardrails|**Extend the structure; replace superseded planning text.**
m-guardrail-scope|skills/phase-plan.md|Guardrails|execution records stay append-only
m-batch-walkthrough|skills/phase-plan.md|A batch approved in conversation|Walk-through answers that add work count toward this trigger
p1-phase0-heading|skills/phase-plan/pass1.md|Phase 0 template|## Phase 0 template
p1-phase0-disposition|skills/phase-plan/pass1.md|Phase 0 template|**Disposition:**
p1-compat-ref|skills/phase-plan/pass1.md|Gap-analysis step|`phase-plan.md` § Compatibility rule
main-phase0-pointer|skills/phase-plan.md|Phase 0: Discovery|`pass1.md` § Phase 0 template
m-discovery-summary|skills/phase-plan.md|Discovery Exemption (summary)|## Discovery Exemption (summary)
x-start-heading|skills/phase-plan/execute.md|Before starting|## Before starting
x-pass3-gate|skills/phase-plan/execute.md|Before starting|refuse to start without a Pass 3 Review Log entry
x-batch-exempt|skills/phase-plan/execute.md|Before starting|A batch-approved plan
x-remeasure|skills/phase-plan/execute.md|Before starting|Re-measure gating figures
x-phase-states|skills/phase-plan/execute.md|Phase completion checklist|built → merged → deployed → observed
x-external-write|skills/phase-plan/execute.md|Phase completion checklist|external-write tier
x-mutation-exit|skills/phase-plan/execute.md|Phase completion checklist|**Mutation testing**
x-parallel-entry|skills/phase-plan/execute.md|Executing Parallel Phases|Only when the Concurrency Map declares a parallel set
x-late-change|skills/phase-plan/execute.md|When new findings surface mid-execution|**A late change gets a scoped re-check.**
x-walkthrough-exec|skills/phase-plan/execute.md|When new findings surface mid-execution|`walk-through.md`
x-append-only|skills/phase-plan/execute.md|When a phase ships|planning text is replaced, execution records are appended
x-closeout-phase|skills/phase-plan/execute.md|When the plan closes|the plan'"'"'s last numbered phase
x-which-pass|skills/phase-plan/execute.md|When the plan closes|which pass should have caught this?
x-fixtures-repo|skills/phase-plan/execute.md|When the plan closes|Probe results kept as fixtures go into the repo'

# Retired phrases, as name|file|literal. File "*" means every live file.
# Checked outside comments, so history in TRACKING blocks may still quote them.
ABSENT='p1-confirm-as|*|Confirm as [SEVERITY]
p1-confirm-severity|skills/phase-plan/pass1.md|to confirm severity
p2-old-title|skills/phase-plan/pass2.md|Pass 2: Gap Analysis
route-pass12-gone|skills/phase-plan.md|"pass 1+2" / "plan and review together"
quick-skips-pass2|skills/phase-plan.md|`pass1.md`, `pass2.md`, and `pass3.md` together
p2-blocker-only|skills/phase-plan/pass2.md|every BLOCKER and every new fact
p3-confirmed-severity|*|confirmed the severity
p3-confirmed-every|skills/phase-plan/pass3.md|confirmed every open question'"'"'s severity
p3-apply-confirmed|skills/phase-plan/pass3.md|Apply the confirmed severities
p3-additive|skills/phase-plan/pass3.md|**Apply fixes additively.**
p3-pass2-word|skills/phase-plan/pass3.md|take Pass 2'"'"'s word
pass1-output-ref|*|`pass1.md` § Output
aq-severity-based|skills/ask-questions-if-underspecified.md|severity-based
tpl-confirms-overrides|*|confirms or overrides the severity
m-desc-old|skills/phase-plan.md|Pass 2 reviews for gaps
m-oneplan-old|skills/phase-plan.md|extends the base with gap analysis
m-fills-gaps|skills/phase-plan.md|Pass 2 fills gaps
m-combined|skills/phase-plan.md|### Combined Pass 1+2
m-load12|skills/phase-plan.md|Load pass1.md + pass2.md
m-additive|skills/phase-plan.md|**Passes are additive, not destructive.**
p1-compat-unchecked|skills/phase-plan/pass1.md|main file § compatibility rule
x-pass2-disjoint|skills/phase-plan/execute.md|Pass 2 disjointness check
m-build-on-base|skills/phase-plan.md|**Build on the base, don'"'"'t rebuild it.**'

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

# Line limits, as id|file|max lines. CHK-LINES holds CLAUDE.md at net zero for
# this plan only (D13); it is removed when no later phase edits CLAUDE.md.
LINE_LIMITS='CHK-LINES|CLAUDE.md|291
CHK-SIZE|skills/phase-plan.md|499'

# Illustrative § references that are not meant to resolve, as
# source basename|target basename|normalised words|reason.
# A listed reference that starts to resolve, or disappears, fails: the list
# can only shrink.
SECTION_ALLOW='external-learn.md|testing-anti-patterns.md|mock misuse|example of a specific overlap claim, not a link'

case "${1:-}" in
  --list-anchors) printf '%s\n' "$ANCHORS"; exit 0 ;;
  --list-absent) printf '%s\n' "$ABSENT"; exit 0 ;;
  --list-table-map) printf '%s\n' "$TABLE_MAP"; exit 0 ;;
  --list-line-limits) printf '%s\n' "$LINE_LIMITS"; exit 0 ;;
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

LIVE="$(live_files)"
# Reference targets: the live files plus the ledgers. Ledgers hold history,
# so references are not read from them, but they are valid things to point at.
TARGETS="$(printf '%s\nREFINEMENTS.md\nEXTERNAL-LEARNINGS.md\n' "$LIVE" | while read -r t; do [ -f "$ROOT/$t" ] && echo "$t"; done)"

# Every target file once, with <!-- --> comment text blanked (line numbers
# kept), into a cache that the checks below read. One awk for all files keeps
# the check fast enough to run per fixture.
CACHE="$(mktemp -d "${TMPDIR:-/tmp}/check-phase-plan-cache.XXXXXX")"
trap 'rm -rf "$CACHE"' EXIT
for t in $TARGETS; do mkdir -p "$CACHE/$(dirname "$t")"; done
( cd "$ROOT" && awk -v cache="$CACHE" '
  FNR == 1 { if (out != "") close(out); out = cache "/" FILENAME; inc = 0 }
  {
    res = ""; line = $0
    while (1) {
      if (inc) { j = index(line, "-->"); if (!j) { line = ""; break } line = substr(line, j + 3); inc = 0 }
      i = index(line, "<!--"); if (!i) { res = res line; break }
      res = res substr(line, 1, i - 1); line = substr(line, i + 4); inc = 1
    }
    print res > out
  }' $TARGETS )

# Run an awk program over the cached live files; FILENAME is relative to ROOT.
over_live() { ( cd "$CACHE" && awk "$@" $LIVE ); }

# --- CHK-TABLE ---------------------------------------------------------------

table_cells="$(awk '
  /^#+ / { insec = (index($0, "Loading the Per-Pass Files") > 0); next }
  insec && /^\|/ {
    if ($0 ~ /^\|[-| ]+\|$/ || index($0, "User says")) next
    rows++; line = $0
    while (match(line, /`[^`]*\.md`/)) { print NR "|" substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH) }
  }
  END { print "ROWS|" rows + 0 }' "$CACHE/$MAIN")"
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

table_rows="$(awk '
  /^#+ / { insec = (index($0, "Loading the Per-Pass Files") > 0); next }
  insec && /^\|/ { print }' "$CACHE/$MAIN")"
while IFS='|' read -r m_name m_phrase m_file; do
  [ -n "$m_name" ] || continue
  case "$table_rows" in
    *"$m_phrase"*)
      if printf '%s\n' "$table_rows" | awk -v a="$m_phrase" -v b="$m_file\`" 'index($0, a) && index($0, b) { found = 1 } END { exit found ? 0 : 1 }'; then
        pass_; continue
      fi ;;
  esac
  fail_ "CHK-TABLE-MAP:$m_name" "$MAIN: no loading-table row holds both $m_phrase and \`$m_file\`"
done <<EOF
$TABLE_MAP
EOF

# --- CHK-PATH ----------------------------------------------------------------

paths="$(over_live '{
  line = $0
  while (match(line, /skills\/phase-plan\/[A-Za-z0-9_.{},-]+\.md/)) { print FILENAME "|" FNR "|" substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH) }
}')"
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
done <<EOF
$paths
EOF

# --- CHK-SECTION / CHK-SECTION-ALLOW -----------------------------------------

# Extract every `<file>.md` § <words> reference from the live files, then
# resolve them all in one pass. A reference resolves when its leading words
# match a heading's leading words for at least min(2, heading words,
# reference words), after dropping markdown punctuation and dashes.
refs_file="$CACHE/.refs"
over_live '{
  line = $0
  while (match(line, /`[A-Za-z0-9_.\/-]+\.md` §/)) {
    target = substr(line, RSTART + 1, RLENGTH - 1); sub(/` §$/, "", target)
    line = substr(line, RSTART + RLENGTH)
    words = line; sub(/^ +/, "", words)
    if (match(words, /[`*.,;:()"]/)) words = substr(words, 1, RSTART - 1)
    w = tolower(words); gsub(/[^a-z0-9 ]/, "", w); gsub(/ +/, " ", w); sub(/^ /, "", w); sub(/ $/, "", w)
    print FILENAME "|" FNR "|" target "|" w "|" words
  }
}' > "$refs_file"
printf '%s\n' "$TARGETS" > "$CACHE/.targets"
resolved="$( cd "$CACHE" && awk -F'|' '
  BEGIN {
    nt = 0
    while ((getline t < ".targets") > 0) tl[++nt] = t
    close(".targets")
    for (i = 1; i <= nt; i++) {
      if (tl[i] == "") continue
      n = split(tl[i], parts, "/"); b = parts[n]; count[b]++; path[b] = tl[i]
      while ((getline l < tl[i]) > 0) {
        if (l !~ /^#+ /) continue
        sub(/^#+ +/, "", l); h = tolower(l); gsub(/[^a-z0-9 ]/, "", h); gsub(/ +/, " ", h); sub(/^ /, "", h); sub(/ $/, "", h)
        nh[tl[i]]++; heads[tl[i], nh[tl[i]]] = h
      }
      close(tl[i])
    }
  }
  {
    n = split($3, parts, "/"); b = parts[n]
    if (count[b] != 1) { print "AMBIG|" (count[b] + 0) "|" $0; next }
    if ($4 == "") { print "EMPTY|" path[b] "|" $0; next }
    p = path[b]; nr = split($4, r, " "); ok = 0
    for (j = 1; j <= nh[p] && !ok; j++) {
      m = split(heads[p, j], hw, " "); k = 0
      while (k < nr && k < m && r[k + 1] == hw[k + 1]) k++
      need = 2; if (m < need) need = m; if (nr < need) need = nr
      if (need > 0 && k >= need) ok = 1
    }
    print (ok ? "OK" : "UNRES") "|" p "|" $0
  }' "$refs_file" )"
refs=0
seen_allow=""
while IFS='|' read -r status info f ln target words raw; do
  [ -n "$status" ] || continue
  refs=$((refs + 1))
  tbase="${target##*/}"
  allow_key="${f##*/}|$tbase|$words|"
  allowed=0
  case "$SECTION_ALLOW" in *"$allow_key"*) allowed=1; seen_allow="$seen_allow
$allow_key" ;; esac
  case "$status" in
    AMBIG) fail_ CHK-SECTION "$f:$ln \`$target\` § $raw: $info files named $tbase among the targets" ;;
    EMPTY) fail_ CHK-SECTION "$f:$ln \`$target\` §: no heading text after the section sign" ;;
    OK) if [ "$allowed" -eq 1 ]; then fail_ CHK-SECTION-ALLOW "$f:$ln \`$target\` § $raw now resolves; remove it from SECTION_ALLOW"; else pass_; fi ;;
    UNRES) if [ "$allowed" -eq 1 ]; then pass_; else fail_ CHK-SECTION "$f:$ln \`$target\` § $raw: no heading in $info starts with those words"; fi ;;
  esac
done <<EOF
$resolved
EOF
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

# One awk over every anchor file: an anchor holds when its literal appears in
# its section (heading line to the next heading of any level; "^" = before the
# first heading), outside comments.
anchor_files="$(printf '%s\n' "$ANCHORS" | awk -F'|' 'NF { print $2 }' | sort -u)"
present=""
for af in $anchor_files; do [ -f "$CACHE/$af" ] && present="$present $af"; done
printf '%s\n' "$ANCHORS" > "$CACHE/.anchors"
found_anchors="$( cd "$CACHE" && awk -F'|' '
  NR == FNR { if (NF) { n++; an[n] = $1; af[n] = $2; as[n] = $3; al[n] = substr($0, length($1 $2 $3) + 4) } next }
  FNR == 1 { started = 0; h = "" }
  {
    if ($0 ~ /^#+ /) { h = $0; sub(/^#+ +/, "", h); started = 1 }
    for (i = 1; i <= n; i++) {
      if (af[i] != FILENAME || ok[i]) continue
      insec = (as[i] == "^") ? !started : (started && index(h, as[i]) == 1)
      if (insec && index($0, al[i])) ok[i] = 1
    }
  }
  END { for (i = 1; i <= n; i++) if (ok[i]) print an[i] }' .anchors $present )"
while IFS='|' read -r a_name a_file a_section a_literal; do
  [ -n "$a_name" ] || continue
  if [ ! -f "$ROOT/$a_file" ]; then fail_ "CHK-ANCHOR:$a_name" "$a_file not found"; continue; fi
  case "
$found_anchors
" in
    *"
$a_name
"*) pass_ ;;
    *) fail_ "CHK-ANCHOR:$a_name" "$a_file: \"$a_literal\" not found in section \"$a_section\" (outside comments)" ;;
  esac
done <<EOF
$ANCHORS
EOF

# --- CHK-ABSENT --------------------------------------------------------------

while IFS='|' read -r x_name x_file x_literal; do
  [ -n "$x_name" ] || continue
  if [ "$x_file" = "*" ]; then x_files="$LIVE"; else x_files="$x_file"; fi
  x_list=""
  for f in $x_files; do [ -f "$CACHE/$f" ] && x_list="$x_list $f"; done
  x_hits=""
  [ -n "$x_list" ] && x_hits="$( cd "$CACHE" && awk -v lit="$x_literal" 'index($0, lit) { printf "%s:%d ", FILENAME, FNR }' $x_list )"
  if [ -z "$x_hits" ]; then pass_; else fail_ "CHK-ABSENT:$x_name" "\"$x_literal\" still present at $x_hits"; fi
done <<EOF
$ABSENT
EOF

# --- line limits -------------------------------------------------------------

while IFS='|' read -r l_id l_file l_max; do
  [ -n "$l_id" ] || continue
  n="$(wc -l < "$ROOT/$l_file" | tr -d ' ')"
  if [ "$n" -le "$l_max" ]; then pass_; else fail_ "$l_id" "$l_file: $n lines, limit $l_max"; fi
done <<EOF
$LINE_LIMITS
EOF

# --- sizes (reported; made a failing assertion in a later phase) -------------

for pair in "$MAIN:500" "CLAUDE.md:200"; do
  f="${pair%%:*}"; budget="${pair##*:}"
  [ -f "$ROOT/$f" ] && echo "INFO size $f $(wc -l < "$ROOT/$f" | tr -d ' ')/$budget lines"
done

echo "check-phase-plan: $assertions assertions, $failures failed"
[ "$failures" -eq 0 ]
