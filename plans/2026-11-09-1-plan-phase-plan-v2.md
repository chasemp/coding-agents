# phase-plan v2: outward-looking passes, an independent review, and a leaner template

**Status:** Executing. Phases 1–9a shipped (Phase 4 dogfood review folded in); next Phase 9b. Passes 1–3 done (D1–D20, no open questions; Pass 3
decisions by agent listed under Open Questions).
**Branch / worktree:** `phase-plan-v2` at `~/git/chasemp/coding-agents.worktrees/phase-plan-v2`, off
`origin/main` `8e6fc33`.

## Outcome Summary

| Phase | Outcome | Commit | Note |
|---|---|---|---|
| 1 | ✅ | `3d39dd1`, `07bd294` | Structural check (68 assertions) and its test (38 fixtures); 9 hand mutations all killed after 2 fixtures added |
| 2 | ✅ | `c3660fd` | `walk-through.md` (67 lines) and its Guardrails reference; 3 anchors |
| 3 | ✅ | `23d0bc7` | `pass1.md` rewritten (257 lines) with the gap-analysis step; check gains CHK-ABSENT and CHK-TABLE-MAP (87 assertions, 57 fixtures) |
| 4 | ✅ | `d06e0f8`, `9a576b8` | New `pass2.md` (independent review) and full loading table; dogfood review: 1 BLOCKER, 25 REVISE, all folded in |
| 5 | ✅ | `1c52532` | `pass3.md` rewritten (232 lines): tests that can fail, hedges, ready gate, walk-through; 133 assertions, 98 fixtures |
| 6a | ✅ | `96781c5` | `CLAUDE.md` bullet folded (291 lines, net zero); `LINE_LIMITS` table with `CHK-LINES` |
| 6b | ✅ | `0be79c4` | `ask-questions-if-underspecified.md` names the decision-first walk-through; 138 assertions, 102 fixtures |
| 7 | ✅ | `fb3c764` | Template: Status, Delivery shape, one-line Concurrency Map, optional fields, close-out phase, Next pass; main file 628 lines; 153 assertions, 116 fixtures |
| 8a | ✅ | `e1dd358` | Frame, triggers, § Compatibility rule, D5 guardrail; 6 TRACKING blocks → `CHANGELOG.md`; main file 524; 174 assertions, 134 fixtures |
| 8b | ✅ | `bf6760d` | Phase 0 template → `pass1.md` § Phase 0 template; main file **478** (D13 met); `CHK-SIZE`; 183 assertions, 141 fixtures |
| 9a | ✅ | `5020a8f` | `execute.md` § Before starting (Pass 3 gate, re-measure), phase states, external-write tier, mutation exit; 195 assertions |

## Problem Statement

`phase-plan` runs every non-trivial change through three planning passes. In practice the user keeps adding
a fourth, freeform pass ("work backwards from anticipated outcomes … all the way up through deployment and
issues being created"), and it keeps finding real defects after Pass 3 has declared the plan ready. Plans also
pay for required sections that rarely affect outcomes, and the user repeats the same process instructions in
most sessions (walk questions one at a time in plain English; write me a prompt to come back for the next pass).

A usage review on 2026-11-09 measured this across:

- 41 Claude Code sessions (2026-10-13 → 11-09, the on-disk retention window): 105 incidents.
- 101 extra review entries in 49 plan docs (2026-03 → 11): 555 findings, each tagged by gap type and by
  whether an existing check should have caught it.
- 149 recent plan docs (94 template plans, 691 phases): 30 execution-time gaps and section-compliance metrics.
- The user's `/insights` report (38 sessions, 2026-08-20 → 11-09) as a cross-check.

Headline results (counts are agent-tagged; read them as proportions):

- 47% of extra-pass findings fell under checks Passes 2/3 already have; 52% fell where no pass looks.
- Pass 3 "ready" was followed by blocker-class findings in at least 15 plans.
- Independent non-author reviews averaged 8.7 findings per entry; generic fresh re-runs of a defined pass 4.2.
- Execution misses cluster after merge: deploy, first scheduled run, first real write.
- Concurrency Map: 61% "all sequential"; 21 plans declared parallel sets; 0 recorded parallel dispatches.
- Close-out entries exist in 20 of 83 plans with execution evidence.
- 14 user requests across 9 sessions for "a comprehensive prompt to clear context and come back for pass N".

The raw evidence contains employer-internal detail and is kept outside this public repo (see Verified
Assumptions, VA-8). Examples below are described generically.

## Approach

Restructure the passes around what the productive extra passes did differently. They changed **direction**
(outward to sibling systems, other plans, live data and record lifecycle; backward from the outcome),
**stance** (try to refute, "the plan's text is not evidence"), and **author** (a non-author reviewer per lens,
with every claim re-checked). New shape:

```
Pass 1: plan + gap analysis ─→ Pass 2: independent review ─→ Pass 3: quality gates ─→ execute ─→ close-out phase
 • read-only probes: counted,   • 3 subagent lenses:           • tests that can fail     • built→merged→      • Outcome Summary
   dated, as the execution        outcome + failure walk,      • fakes/fixtures match      deployed→observed  • "which pass should
   identity; data sources and     outward consistency,           real data               • external-write       have caught this?"
   terms confirmed with user      facts vs code + live data    • last word, fresh          tier: dry run →    • worktree cleanup
 • then explicit gap-analysis   • main session re-checks         context                   supervised → sched
   checklist + outward sweep      every claim
         │                               │                          │
         └──── any later change → scoped re-check; superseded text replaced in place ───┘
   Every pass ends by rewriting the plan's "Next pass" section (one-line paste to resume)
   Every decision list: one at a time, plain English, decision first, answers saved immediately
```

Pay for the additions by cutting sections that do not earn their place, so the always-loaded main file
shrinks rather than grows.

## Reasoning

- **Why not "one more pass" as-is.** Fresh re-runs of the same checklist found about half as much as a
  differently-briefed reviewer; the most comprehensive plan's fresh Pass 3 found zero just before a later pass
  found three critical defects. A check that cannot see a category does not see it on the second run either.
  The gain comes from stance and authorship, so Pass 2 is defined by those, not by "fresh context".
- **Why merge planning and gap analysis.** The user already runs them together. The non-author eyes a separate
  gap-analysis pass was meant to supply now come from Pass 2. The evidence also shows same-session combined
  passes quietly skip their own checks (a field verified to exist but not its values; one "Pass 2" never loaded
  `pass2.md`), so the gap analysis stays an explicit, separately logged step inside Pass 1.
- **Why gates last.** Pass 3 is mostly consistency, clarity, and test-first/wiring/validation gates. Placing it
  after the review means it also checks the reviewers' fixes; today nothing reviews a pass's own additions, and
  several plans record defects introduced by a pass.
- **Why probes are read-only reconnaissance, not "testing against live systems".** (User correction during the
  walk-through.) Probes gather intelligence (what data exists, how much, its shape, how it changes) and config
  (fields, screens, permissions, limits, retention). Proving behaviour belongs in tests. Failure behaviour that
  was not observed live is labelled as such so the plan does not carry false confidence.
- **Why cut sections.** Required fields that are filled as boilerplate cost reading time and train readers to
  skim. Concurrency Map, Read-set and Shared-state contract show no traceable effect on outcomes; their useful
  parts (declared parallel sets, production/ops state) move to where they are used.
- **Alternatives rejected.**
  - Keep four separate passes (gap analysis on its own): rejected; adds a context switch the user does not use.
  - Make the independent review optional / on request: rejected; it produced the largest share of findings.
  - Planner-chosen review lenses: rejected for now; a fixed set is easier to audit. Revisit after use.
  - A separate handoff file per plan: rejected; the plan stays the single handoff artifact.

## Decisions (walk-through 2026-11-09, user-confirmed)

All recorded one at a time. These are locked; later passes extend them, not reopen them.

- **D1 Independent review is a defined pass.** Runs on every full plan; skipped for "quick plan". Three fixed
  lenses: (a) outcome + failure walk (first-run result traced backward; abort, partial batch, retry, rerun,
  close-on-absence, rollback of written data); (b) outward consistency (sibling systems, in-flight plans/PRs,
  numbers already shown on existing surfaces); (c) facts vs code and live data. Refute-first; findings graded
  BLOCKER / REVISE / CONFIRMED; the main session re-checks every claim before folding it in. Reviewers run on the
  session's model, passed explicitly. The user's freeform pass stays available after.
- **D2 Pass order.** Pass 1 plan + gap analysis → Pass 2 independent review → Pass 3 quality gates → execute.
  Old plans keep their old labels.
- **D3 Gap analysis looks outward** (inside Pass 1, as an explicit checklist step with its own Review Log
  entry): reverse search of every name and literal value the plan adds/renames/removes across all file types,
  including sibling repos and sibling plans (record the search and hit count); value domains, not existence;
  sibling comparison table only when a sibling system exists (each difference fixed or recorded as deliberate);
  neighbour check (open PRs, other sessions' plans and worktrees, reserved version numbers, the `origin/<default>`
  SHA verified against, other writers and reactors on the same records).
- **D4 Probes and discovery.** Read-only by definition (anything that writes is a validation step: sandbox or
  user approval). For behaviour-driving facts a probe beats reading: command, full count, date; samples flagged.
  Probe as the execution identity. Read the destination's config. Learn lifecycle by observing records already
  in later states. Confirm data sources and domain terms with the user after checking memory. Re-measure gating
  figures at execution start. Failure behaviour: learn from source, docs or logs; unknown → open question and the
  test fakes cover both outcomes; never provoked live. Failure behaviour not observed live is marked "not observed
  live" in Verified Assumptions and carried as a risk; a harmless read-only failure call (for example a read with
  a bad token) is the named way to close the gap when clearly safe and user-approved.
- **D5 Late changes are re-checked; superseded text is replaced.** Any change after a pass (walk-through answer
  that adds design, addendum, new phase, scope expansion, a pass's own fixes) gets a scoped gap-analysis step +
  Pass 3 on the changed part; Pass 2 also runs when the change adds a phase, a new external-system interaction,
  or a new write path. Each pass starts by reviewing the previous pass's additions. "Ready" only after
  walk-through answers are in the plan and re-checked. Replace superseded text in place across the plan and
  sibling plans; history lives only in the Review Log. Hedges ("consider", "grep to confirm") are run or become
  open questions before ready. *Scope (decided by agent in Pass 2, override if wanted):* replacement applies to
  planning text. Execution-time records stay append-only: "Delivered:" notes and skip records
  (`execute.md` § When a phase ships / § When a phase is skipped) keep the original spec as the contract.
- **D6 Tests and validation that can fail** (Pass 3): each named test states what it shows if the feature is
  missing or wrong; fakes refuse what the real service refuses; fixtures match probed real states with timestamps
  relative to now; the expected value is independent of the changed code; sets compared where identity matters;
  tests target reachable states; read-only validation commands are dry-run during the pass. Execution: mutation
  testing is an exit step for logic-heavy phases.
- **D7 Delivery and rollout.** New "External write" validation tier: dry run showing exactly what would be
  written → small supervised live run with read-back of every write → schedule or full run; safe reruns; rollback
  covers data already written; bulk writes state batch size, rate, and triggered automation. Phase states
  built → merged → deployed → observed; ✅ only at observed (with run id) for scheduled jobs, deploys and live
  data. New template section **Delivery shape**: PR count (default one per plan), merge order, gates, manual deploy
  steps, calendar dependencies, where unattended jobs run; Pass 1 fills it from saved preferences.
- **D8 Walk-through redesign.** Decision-first: situation, concrete example, options with consequences,
  recommendation; severity is a proposed tag, not the question. One per message, plain English, terms glossed.
  The agent decides engineering-internal choices and records "Decided by agent: X, because Y", listed in the
  end-of-walk summary for override. Echo every answer in one line and flag conflicts with earlier answers. Write
  each answer into the plan immediately. Same format for Pass 2 findings, plan-changing probe results, and
  execution decisions. "Accept all as recommended" kept. Also one line in `CLAUDE.md` § Explaining Design and
  Protocol Work making this the default for any list of decisions.
- **D9 Handoff prompt.** Each pass's close-out replaces a **Next pass** section at the end of the plan: plan
  path, base commit, branch/worktree, pass file to load, locked decisions, open items, named risk targets, the
  next pass's deliverable and done-when. The user's paste is one line. A compacted context is not fresh: say so
  and hand off. The same mechanism writes the Pass 2 reviewer briefs.
- **D10 Template cuts.** Concurrency Map → one required line by default; full parallel block only when a set is
  declared; the planner asks "could any phases run in parallel?" once. Read-set optional. Shared-state contract
  optional for sequential phases; its ops part moves into Delivery shape. Write-set stays, traced from the reverse
  search, including tests, fixtures and docs. 4-file rule reworded ("3 files maximum; 4 or more must split") with
  a worked example; atomic units count as one (version-bump pair, test-enforced parity twins, guard + allowlist
  entry). Review Log oldest-first; execution log in its own section; a short current-state summary at the top;
  fixed names for extra rounds. The parallel-execution protocol stays, reached only when parallelism is declared.
- **D11 Close the loop.** Close-out becomes a numbered final phase in every plan. Each Discovery records "which
  pass should have caught this?". Probe results kept as fixtures go into the repo at capture, never a session
  scratchpad. Trigger fixes: bulk external writes trigger the skill without code changes; execution refuses to
  start without the Pass 3 Review Log entry; walk-through answers that add work count toward the
  batch-approved-in-conversation trigger. *Scope (decided by agent in Pass 2):* the Pass 3 start gate applies to
  full and quick plans; a batch-approved plan (`### A batch approved in conversation`) is exempt.
- **D12 The test for skill text (was OQ-1; user, 2026-11-09).** Three layers: the Phase 1 structural check
  (`scripts/check-phase-plan.sh`, with a refusal fixture and a pass fixture) for wiring between files; `/audit`
  for repo hygiene; dogfooding the new Pass 2 on this plan for whether the instructions produce the intended
  behaviour. Each phase adds its assertion to the structural check and watches it fail before editing text.
- **D13 Size budgets (was OQ-2; user, 2026-11-09).** `skills/phase-plan.md` must end under 500 lines, enforced
  as a failing assertion in the structural check, not a report. Route: TRACKING history to
  `skills/phase-plan/CHANGELOG.md` (one marker line stays in the main file for `/audit` Check 6), the D10
  Concurrency Map cut, and Usage Patterns detail into the per-pass files where needed. `CLAUDE.md` is held at
  net zero lines: the D8 rule is folded into the existing "Lead with the decision and its options" bullet. Its
  pre-existing overage (291 vs 200) is out of scope and noted as a follow-up.
- **D14 Evidence stays local (was OQ-3; user, 2026-11-09).** The raw usage-review evidence (session excerpts,
  plan citations from employer repos) is never committed to this public repo, cleaned or otherwise. Public text
  carries only counts and generic descriptions; the local folder is named by basename only (VA-8). The
  decisions rest on the user's direct confirmation, not on readers re-checking the evidence.
- **D15 In-flight plans (was GA-W1; user, 2026-11-09).** One compatibility rule in the main file: before any
  pass, read the plan's Review Log; if it has no gap-analysis entry (an old "Pass 2: Gap Analysis" entry counts),
  run the gap-analysis step first. Applies to plans begun under the old labels; harmless on new plans.
  *Matching (decided by agent; revised 2026-11-12 after the Phase 4 dogfood review):* keyed on labels, not
  dates, because the rule is written before the merge date exists. A `Pass 1: Gap-analysis step` entry, or any
  entry labelled `Pass 2…` or `Pass 1+2…` / `Pass 1 + Pass 2…` other than `Pass 2: Independent review`, counts
  as gap analysis; an execution already started continues under its existing structure; an old "Pass 3: Quality
  Gates" entry satisfies the start gate. A session open at pull time is ended and a new one started; re-invoking
  would leave the old and new loading tables both in context.
- **D16 Close-out records (was GA-W2; user, 2026-11-09).** Records that can only exist after merge (observed
  check, Outcome Summary, `REFINEMENTS.md` Notes line) land in a second, records-only `land:` PR touching only
  this plan and `REFINEMENTS.md`. Nothing is recorded before it happens; nothing is pushed to `main` directly.
- **D17 Size route (was Pass2-W1; user, 2026-11-09).** The Phase 0 (Discovery) template block (48 lines) moves
  from the main file's template into `pass1.md`, the only pass that drafts a Phase 0; the main template keeps a
  one-line pointer. Usage Patterns and Guardrails stay in the main file.
- **D18 Keeping the checks live (was Pass2-W2; user, 2026-11-09).** `/audit` becomes the repo's gate: a
  project-local `.claude/commands/audit.md → ../../commands/audit.md` symlink (the existing `pr.md` pattern); a new
  `/audit` check runs `bash scripts/test-check-phase-plan.sh && bash scripts/check-phase-plan.sh`; `README.md`
  declares the gate (structure check, its test, hook tests). A refusal fixture is watched failing through
  `/audit` itself.
- **D19 Work names in touched TRACKING text (was Pass2-W3; user, 2026-11-09).** Text this plan moves or edits
  beside is made generic, keeping the reasoning: the main file's 2026-04-16 Discovery-exemption block (moved to
  `CHANGELOG.md` in Phase 8a) and `execute.md`'s 2026-10-09 worktree-removal block (beside Phase 9b's edit). No
  repo-wide sweep; earlier public history is unchanged.
- **D20 Commit cadence (was Pass2-W4; user, 2026-11-09).** Standing OK for local commits on `phase-plan-v2`, one
  per phase, after that phase's checks pass. Push, opening either PR, merge and the main-checkout pull each still
  need the user's say-so.

## Verified Assumptions

- **VA-1** The skill is registered through `~/.claude/commands/phase-plan.md`, a symlink to
  `../coding-agents/skills/phase-plan.md`; `~/.claude/coding-agents` is a symlink to
  `~/git/chasemp/coding-agents` (the main checkout); `CLAUDE_CONFIG_DIR` is unset. Per-pass files are named by
  relative path `skills/phase-plan/*.md` and the **model** resolves them: across 2026-10/11 transcripts, 172 reads
  went to `~/.claude/coding-agents/skills/phase-plan/`, 5 to the main checkout, and 16 to
  `~/.claude/skills/phase-plan/`, which does not exist. *Evidence:* `readlink`, transcript grep, 2026-11-09.
  Consequence: edits are inert until merged and pulled **except** in a session whose working directory is this
  worktree, which may read `main`'s main file with the worktree's per-pass files. Phase 4 names the absolute
  base directory in the loading table.
- **VA-2** No other repo's instruction files reference the pass files by name. *Evidence:* Pass 2 found the
  first recorded grep had unbalanced parentheses and could not match; re-run with
  `phase-plan|Pass 2|gap analysis|three passes` over `.claude/`, `CLAUDE.md`, `AGENTS.md` in the personal and work
  trees, 2026-11-09. Consumers of phase-plan *conventions* do exist: a workspace meta-repo's `CLAUDE.md` and
  `.claude/TRACKING.md` require a Status line and Review Log (unchanged by this plan); two auto-memory files in
  other projects describe the old pass order and the "Pass 2 disjointness check" (updated at close-out, Phase 11). The two org-layer
  `coding-agents` repos named in `agents.md` were searched in full (all files): 0 references to phase-plan or its
  pass files; their only "Pass 1/2/3" hits are an unrelated command's own passes. *Evidence:* grep, 2026-11-09.
- **VA-3** In-repo references to the pass structure outside the skill: `skills/ask-questions-if-underspecified.md`
  lines 54 and 186 (severity-based walk-through); `skills/plan-doc-reasoning.md` line 108 ("three passes");
  `commands/audit.md` Check 1 exemption and Check 6 TRACKING; `commands/skills.md` line 38 (excludes
  `skills/phase-plan/*.md` from the skill listing); `skills/skill-hygiene.md` line 98 (phase-plan split example).
  README and agents.md do not describe phase-plan. *Evidence:* repo grep, 2026-11-09.
- **VA-4** Size budgets (`commands/audit.md` Check 1, from `skill-hygiene.md`): top-level skills under 500
  lines; `CLAUDE.md` under 200. Current: `skills/phase-plan.md` 673 (already over), `CLAUDE.md` 291 (already
  over). Per-pass files are exempt individually. *Evidence:* `wc -l`, 2026-11-09.
- **VA-5** The repo has no CI and no review bot; PRs #1 and #2 merged with zero reviews. Tests exist only for
  hooks (`hooks/test-*.sh`). *Evidence:* `ls -a`, `gh pr list`, 2026-11-09. Consequence: there is no declared
  single gate command (see D12).
- **VA-6** The Agent tool accepts an explicit `model` (`sonnet`, `opus`, `haiku`, `fable`), which takes
  precedence over agent-definition pins; `~/.claude/CLAUDE.md` requires passing it to match the session.
  *Evidence:* tool schema and CLAUDE.md § Subagent Model Selection, read 2026-11-09.
- **VA-7** Today no plan exists in `plans/` for 2026-11-09, so this plan takes ordinal 1. *Evidence:* `ls plans`.
- **VA-8** The repo is public (`gh repo view` → `PUBLIC`). The usage-review evidence (session excerpts, plan
  citations from employer repos) is kept in a local folder outside any git repo
  (`phase-plan-review-2026-11-09/`) and is not committed here.
- **VA-9** Baseline gates at base `8e6fc33`: `hooks/test-destructive-git-guard.sh` PASS 34/34;
  `hooks/test-install.sh` ALL PASS, 9 checks (both sandbox `HOME` via `mktemp`). `/audit` flags at base (the
  baseline "no new flags" is measured against): Check 1 `skills/phase-plan.md` 673 and
  `skills/testing-anti-patterns.md` 506 (500 budget); agents `adr` 898, `docs-guardian` 799, `pr-reviewer` 750,
  `py-enforcer` 662, `refactor-scan` 558, `tdd-guardian` 486 (400 budget); `CLAUDE.md` 291 (200 budget). Checks 2
  and 7 clean. *Evidence:* run 2026-11-09 (two independent runs agree).
- **VA-10** `REFINEMENTS.md` Status domain is `proposed | accepted | rejected | parked` (header line 27; 15
  accepted, 1 parked, 1 proposed). "Applied" is recorded in an entry's **Notes**, not its Status.
  Counts at base: 14 accepted, 1 parked, 0 proposed (the "proposed" hit is the template line); this plan adds
  1 accepted. Notes wording varies ("Applied", "Implemented"). *Evidence:* read + count, 2026-11-09.
- **VA-11** Applied changes already living in the files this plan rewrites, which the rewrite must keep. Phase 1
  asserts each by literal anchor, scoped to its section, ignoring `<!-- -->` comments:
  - `pass1.md` step 1 cross-reference to `ask-questions-if-underspecified` (2026-04-16).
  - Documentation Impact: the template section, the `pass1.md` inventory step, `pass3.md`
    `**7. Documentation impact coverage**`, the `execute.md` completion-checklist item (2026-04-17).
  - `## One plan, three passes` and the "not a plan template" banner in `pass1.md`, `pass2.md`, `pass3.md` (no
    banner in `execute.md`; 2026-04-17).
  - The batch-approved trigger in the description and `### A batch approved in conversation` (`d7cd0d7`).
  - "A new entry point invalidates every prior 'wired' claim" and the reachability gate (`aa6c43f`).
  - The `**Plan file:**` line in every pass close-out (`e048db3`).
  - "Plan matches reality" in `execute.md` § The execution reminder (`557bbad`).
  - Load-bearing repeated guardrails: `execute.md` § Execution guardrails, each pass file's § Reminders, and the
    main file's `TRACKING: File split (2026-04-16)` block (2026-04-16; `commands/audit.md` Check 6 and
    `skills/skill-hygiene.md` lines 96-100 name it).
  - `execute.md` § Step 4 Consolidate locally (2026-05-04).
  - Close-out narrative and worktree removal in `execute.md` § When the plan closes (2026-04-17, 2026-10-09).
  *Evidence:* `REFINEMENTS.md` Notes, `git log -- skills/phase-plan*`, 2026-11-09 (Pass 2 found six missing from
  the first version of this list).
- **VA-12** Neighbours at 2026-11-09: `origin/main` is `8e6fc33` (`git ls-remote`); no open PRs; worktrees are
  the main checkout and this one. `plans/xml-tag-enhancement.md` targets `skills/phase-plan.md` but is dormant (no
  Status line, written against the pre-split 794-line file); recorded as superseded for the files this plan
  touches. Delivery pattern: work commits on a branch, merged through a PR whose merge commit is titled
  `land: …` (#1, #2). This branch tracks `origin/main` with commits only local; PR 1 needs
  `git push -u origin phase-plan-v2`. `main` is unprotected. *Evidence:* `git`, `gh`, 2026-11-09.

## Documentation Impact

- `skills/ask-questions-if-underspecified.md` (lines 54, 186): describes phase-plan's walk-through as
  severity-based. Update to the decision-first format. Phase 6b.
- `skills/plan-doc-reasoning.md` (line 108): "three passes" stays true; re-read wording against the new pass
  names. Phase 10a.
- `commands/audit.md` Check 1 (exemption names the per-pass files; `walk-through.md` and `CHANGELOG.md` now
  land in `skills/phase-plan/`) and Check 6 (its `grep -l 'TRACKING:'` covers `skills/phase-plan/*.md`, so once
  history moves to `CHANGELOG.md` the check stays green even if the main file loses its marker; name the main
  file explicitly): Phase 10a. (Pass 2: line 141 already names the main file, and line 143 already requires its
  split marker; the remaining gap is that the check is read by eye, so Phase 10a adds a line that prints MISSING
  when the main file has no split marker.)
- `commands/skills.md` line 38: excludes `skills/phase-plan/*.md`; confirmed still correct for
  `walk-through.md` and `CHANGELOG.md`, and `scripts/` is not a skill directory. No change.
- `agents.md` § File reference (line 225 lists `skills/` as one row): add a `scripts/` row only. Phase 1.
- `CLAUDE.md` § Explaining Design and Protocol Work: one line (D8). Phase 6a.
- `REFINEMENTS.md`: new entry for this plan (written with the plan); Status stays `accepted`; an "Applied
  <date> in <PR>" line is added to its Notes at close-out (VA-10).
- `skills/skill-hygiene.md` lines 96-100: names the split TRACKING marker; the marker stays (VA-11), so no change.
- `commands/audit.md` Check 7 (line 156) depends on the template headings `## Problem Statement` and
  `## Reasoning`; Phase 7 asserts both stay.
- `README.md` § What's here (lines 43-51): add a `scripts/` row. Phase 10b.
- `EXTERNAL-LEARNINGS.md` line 117: parked question on a walk-through "defaults" fast-path, answered by D8
  ("accept all as recommended" kept). Phase 10b.
- Auto-memory outside this repo (two files, VA-2): refresh to the new pass order at close-out. Phase 11.
- `plans/xml-tag-enhancement.md`: dormant, superseded for phase-plan files (VA-12); no edit.
- Grep terms used: `phase-plan`, `three-pass`, `pass ?[123]`, `pass[123].md`, `execute.md`, across `*.md` and
  `*.sh`.

## Delivery shape

- **PRs:** two. PR 1 carries all skill and repo changes (`phase-plan-v2` → `main`), opened at the end of
  Phase 10b. PR 2 is records only (this plan, `REFINEMENTS.md`), opened after the observed check (D16).
- **Gates:** `/audit` (D18), which runs the structural check and its test, with no flags beyond VA-9; hook tests; user review and merge
  (no review bot in this repo).
- **Going live:** after merge, update the main checkout, which the `~/.claude` symlinks read. Before the pull,
  `git -C ~/git/chasemp/coding-agents status --porcelain` and `git -C ~/git/chasemp/coding-agents log
  origin/main..HEAD` must both print nothing (the checkout has `pull.rebase=true`); pull when no session is
  mid-pass. After it, record that the checkout's HEAD equals the merge commit. Then the observed check in Phase 11.
- **Rollback:** trigger: a session loads the wrong pass file or uses the old loading table (see Phase 11 for
  other observed-check failures). On a new branch, reverse only PR 1's own changes, so work that landed on `main`
  after PR 1 in the same shared files (`CLAUDE.md` above all) survives:
  `git diff <PR1 merge>^1 <PR1 merge> -- <paths> | git apply -R`, resolving any conflict by hand, for every path
  PR 1 touched except this plan (skill files, `CLAUDE.md`, `skills/ask-questions-if-underspecified.md`,
  `commands/audit.md`, `skills/plan-doc-reasoning.md`, `agents.md`, `README.md`, `EXTERNAL-LEARNINGS.md`). That
  also deletes the files PR 1 added (`scripts/check-phase-plan.sh`, `scripts/test-check-phase-plan.sh`,
  `skills/phase-plan/walk-through.md`, `skills/phase-plan/CHANGELOG.md`, the `.claude/commands/audit.md`
  symlink); confirm with `git status`. Land it as a PR; pull per Going live. Keep this plan and add a Discovery
  entry. Do not `git revert -m1` PR 1 whole: that also deletes this plan.
- **Status on `main` between PRs:** PR 1 sets this plan's Status to "merged; awaiting observed check and PR 2", so
  `main` reads correctly if PR 2 is delayed.
- **Commits:** local, one per phase after its checks pass, under D20's standing OK; push, PRs, merge and pull
  need the user's say-so each time.
- **Manual steps:** the pull (with its checks); end any session open at pull time and start a new one (D15).
- **Calendar or unattended jobs:** none.

## Concurrency Map

All phases sequential: most phases edit `skills/phase-plan.md` or the structural check, and later pass files
reference earlier ones.

## Phases

Every phase follows the same verification loop: add the phase's assertions to the structural check (RED), edit
the skill text (GREEN), run `bash scripts/test-check-phase-plan.sh && bash scripts/check-phase-plan.sh` and the
hook tests (`for t in hooks/test-*.sh; do bash "$t" || exit 1; done`; baseline VA-9), then commit (D20).

Rules for every assertion a phase adds (Pass 3):
- **Literals first.** Before editing text, the phase writes the exact strings it will require (headings,
  sentences) into the check's anchor or absence table, runs the check, and records the RED ids in its commit
  message. "Contains the gap-analysis step heading" is not an assertion until the heading text is named.
- **Every assertion has a refusal fixture.** Anchors and absences get theirs generated from the check's own
  tables (`--list-anchors`, `--list-absent`), so a phase that adds an entry gets its fixture for free. Other
  assertions name their fixture in the phase.
- **No expected-red.** The loop must be green at every commit. An assertion that only a later phase can satisfy
  belongs to that later phase.
- The real tree is the independent oracle: a typo in a table literal fails the pass fixture, so generating
  refusal fixtures from the same table does not make them circular.
- **Literals sit on one line** in the target file. A literal that wraps makes an anchor fail and an absence
  pass without testing anything (both seen in Phases 2 and 4); watching each absence fail first is what
  catches the second.
- **Record before validating.** When a phase's commit lands, its Outcome Summary row says "built `<sha>`,
  validation pending" before any long validation step, so an abort leaves the next session at the right phase.
- **Which assertions stay.** Every assertion is permanent except `CHK-LINES` (Phase 6a), whose job ends when no
  later phase edits `CLAUDE.md`; Phase 10b removes it. A red check after close means a real break: a reference,
  route or applied change was lost, and the edit that caused it is fixed or the table is updated with a reason.

### Phase 1: Structural check for the skill — ✅ SHIPPED (`3d39dd1`, `07bd294`)

**Goal:** a test-first harness for skill text, so each later phase has a RED → GREEN check.
**Changes:**
- [ ] `scripts/check-phase-plan.sh [ROOT]`: takes the tree root as an argument so fixtures run against a mutated
  copy; the default is the script's own parent directory (`$(cd "$(dirname "$0")/.." && pwd)`), not `git`,
  because fixture copies have no `.git`. Written for bash 3.2 and BSD tools (no associative arrays, `mapfile`,
  `grep -P`, or suffix-less `sed -i`). Output: one line per failure, `FAIL <id>: <file>:<line> <detail>`, then
  `check-phase-plan: <n> assertions, <m> failed`; exit 1 when m > 0. Ids and assertions at this phase:
  - `CHK-TABLE`: the main file's loading table has at least 5 parseable rows, and every file a row names exists.
    Cells are resolved by basename under `ROOT/skills/phase-plan/` (rows use both `skills/phase-plan/pass1.md`
    and bare `pass1.md`). The Phase 4 base-directory line names the installed checkout, not ROOT, and is not
    resolved.
  - `CHK-PATH`: every `skills/phase-plan/<name>.md` path in a live file exists, brace forms expanded
    (`pass{1,2,3}.md`). Glob and directory forms (`skills/phase-plan/*.md`, `skills/phase-plan/.`) are skipped.
  - `CHK-SECTION`: every `` `<file>.md` § <words> `` reference in a live file resolves, and at least 10 are
    extracted (22 today; Phases 4–5 remove two). The file is found by basename across the live scope; zero or
    two or more matches fail. References run on into prose (`` `execute.md` § Step 4 for the consolidation
    procedure ``, heading `### Step 4 — Consolidate locally`), so the rule is word-wise: drop markdown
    punctuation and dashes from both, and the reference resolves when its leading words match a heading's
    leading words for at least min(2, words in heading, words in reference).
  - `CHK-SECTION-ALLOW`: an allowlist of illustrative references that are not meant to resolve, each with a
    reason. Today it holds one: `external-learn.md` cites `skills/testing-anti-patterns.md` § Mock misuse twice
    (lines 322 and 375) as an example of a specific overlap claim, and no such heading exists. A listed
    reference that starts to resolve also fails, so the list can only shrink.
  - live scope: `skills/` (excluding `skills/phase-plan/CHANGELOG.md`), `commands/`, root agent `.md` files,
    `CLAUDE.md`, `agents.md`, `README.md`. Ledgers (`REFINEMENTS.md`, `EXTERNAL-LEARNINGS.md`), `plans/` and
    `.claude/` are excluded because they hold history or symlinks.
  - `CHK-MARKER`: `skills/phase-plan.md` itself contains `TRACKING: File split (2026-04-16)`.
  - `CHK-ANCHOR:<name>`: each VA-11 anchor present in its own section (from its heading line to the next
    heading of the same or higher level), outside `<!-- -->` comments. The table is printed by `--list-anchors`
    as `name|file|section|literal`.
  - prints line counts against the VA-4 budgets (made a failing assertion in Phase 8b).
- [ ] `scripts/test-check-phase-plan.sh`: copies the live scope into a `mktemp -d` per fixture, mutates it, runs
  the check, and passes a fixture only when the check exits non-zero **and** prints a line matching
  `^FAIL <expected id>:` (exact id, so `CHK-ANCHOR:plan-file` does not match `CHK-ANCHOR:plan-file-x`). Prints
  `PASS|FAIL <fixture> (expected <id>, got <ids>)` per fixture. Edits use fixed-string matching (`grep -vF`, awk
  `index()`), because the literals hold `**`, `§` and backticks. Refusal fixtures:
  - a loading-table cell renamed to a missing file → `CHK-TABLE`;
  - the loading table's rows deleted → `CHK-TABLE`;
  - the description's brace form changed to `pass{1,2,4}.md` → `CHK-PATH`;
  - a line `` `execute.md` § No such heading `` appended to `pass3.md` → `CHK-SECTION` (injected rather than a
    renamed heading, so it does not depend on references that later phases remove);
  - every `§` stripped from the live scope → `CHK-SECTION` (fewer than 10 extracted);
  - the allowlisted Mock misuse reference made to resolve (a `## Mock misuse` heading added) →
    `CHK-SECTION-ALLOW`;
  - the split marker removed from the main file only (`execute.md` keeps its own `TRACKING:` blocks) →
    `CHK-MARKER`;
  - per anchor from `--list-anchors`: every line holding the literal deleted → `CHK-ANCHOR:<name>`;
  - one anchor left only inside a `<!-- -->` comment → `CHK-ANCHOR:<name>`;
  - one anchor moved under a different heading → `CHK-ANCHOR:<name>`.
  Pass fixture: the current tree, exit 0, zero `FAIL` lines, assertion count above zero.
- [ ] `agents.md` § File reference: a `scripts/` row.
**Call chain:** maintainer or agent → `scripts/test-check-phase-plan.sh` → `scripts/check-phase-plan.sh ROOT` →
skill files.
**Wiring test:** `scripts/test-check-phase-plan.sh` exits 0 with every fixture exercised; each refusal is watched
failing first (the assertion written before the check exists).
**Depends on:** D12.
**Write-set:** `scripts/check-phase-plan.sh`, `scripts/test-check-phase-plan.sh`, `agents.md`.
**Risks:** false greens from grading an empty or wrong set, or counting a crash as a refusal; the id match and
the minimum counts cover these. Today's tree has one reference that does not resolve (the Mock misuse example);
without the allowlist the pass fixture fails on day one.
**Done when:** every refusal fixture is refused with its id and the current tree passes. Verified by
`bash scripts/test-check-phase-plan.sh`.
**Validation:** moderate (the check is the logic every later phase relies on):
- run the test once under `/bin/bash` (3.2) as well as the `PATH` bash (5.3);
- **mutation exit step (D6), by hand, since no mutation tool covers bash.** Commit the green state first. Then,
  one at a time: drop the comment stripping; drop the section scoping; loosen the § rule to one word; set the
  minimum counts to 0; force exit 0; misspell one id. Each must turn at least one fixture red. Before each
  restore, `git status --porcelain scripts/check-phase-plan.sh` must show only that mutation; restore with
  `git checkout HEAD -- scripts/check-phase-plan.sh`, then re-run the full test. Record each survivor as
  equivalent or a real gap (and close real gaps with a fixture) in the phase's execution note.

**Delivered (2026-11-12):**
- RED: an always-pass stub failed all 10 hand-written refusal fixtures; the real check then failed only
  `CHK-ANCHOR:agents-scripts-row` until the `agents.md` row landed. Green under bash 5.3 and `/bin/bash` 3.2 (the
  test runs the check with `"$BASH"`, so the check runs under the same shell as the test).
- Differences from the spec: (a) references are read from live files only, but may *point at* the ledgers too.
  The first run found two in `external-learn.md` (`REFINEMENTS.md` § Entry format, `EXTERNAL-LEARNINGS.md` §
  Entry format) that the Pass 3 grep missed because of a double space; 24 references extracted, not 22. (b) An
  anchor's section runs to the next heading of *any* level, not "same or higher" (stricter; every anchor fits).
  Headings are lines starting `#` at column 0 outside comments, so the template's headings count as headings.
  (c) 25 anchors: the 24 VA-11 literals plus the new `agents.md` `scripts/` row. (d) The `--list-absent` table
  comes with the first absence assertion (Phase 3), not as an empty mechanism now.
- Mutation round: M1 no comment stripping, M2 no section scoping, M4a/M4b minimum counts 0, M5 exit 0, M6 id
  typo, M7 table file check always passes: each killed. Two real gaps survived and were closed with fixtures
  (`07bd294`): M3 one-word match rule (fixture: a reference matching only a heading's first word) and M8 stale
  allowlist entry ignored (fixture: the allowlisted reference removed). Re-run: both killed. No equivalent
  mutants.
- A full test run takes about 40 seconds (38 fixtures, each a fresh copy).

### Phase 2: Canonical walk-through file — ✅ SHIPPED (`c3660fd`)

**Goal:** one decision-first walk-through procedure (D8) that every pass and execution reference.
**Changes:**
- [ ] `skills/phase-plan/walk-through.md`: the procedure from D8, with one worked example item.
- [ ] `walk-through.md` states the mapping: a BLOCKER finding that needs a user decision becomes a BLOCKING question.
- [ ] Check assertions: the file exists; it contains the mapping line. The severity-gate wording is asserted
  absent file by file in the phase that rewrites each file (Phases 3, 5, 6b, 7), not here: an assertion that
  stays red until Phase 7 would block every commit from Phase 2 to 6 under the verification loop, and the
  original patterns matched only `pass1.md:192` (`pass3.md:76` reads "confirmed the severity", the template
  line 498 "confirms or overrides the severity").
**Call chain:** pass file close-out → `walk-through.md`.
**Wiring test:** check asserts `walk-through.md` is referenced by the main file's loading table or guardrails
(made GREEN here by one reference line in the main file).
**Depends on:** Phase 1.
**Write-set:** `skills/phase-plan/walk-through.md`, `skills/phase-plan.md` (one reference line),
`scripts/check-phase-plan.sh`.
**Done when:** the walk-through exists and is referenced; check passes.
**Validation:** moderate; read `walk-through.md` cold against one walk-through this plan recorded (Pass2-W1 → D17)
and confirm each step of the procedure appears in it. Live use comes from the execution decisions that follow.
**Delivered (2026-11-12):** wired from the main file's § Guardrails (one bullet; main file 674 lines). Anchors
`walkthrough-procedure`, `walkthrough-mapping`, `walkthrough-wired`; the mapping anchor first failed on a
line-wrapped literal, so the mapping sentence sits on its own line. Cold read against the Pass2-W1 → D17 walk:
every step present. The worked example is generic (a size-budget item).

### Phase 3: Pass 1 = plan + gap analysis — ✅ SHIPPED (`23d0bc7`)

**Goal:** `pass1.md` covers drafting, the probe rules (D4), the explicit gap-analysis checklist with the outward
sweep (D3), Delivery shape filling (D7), traced write-sets and the reworded size rule (D10), and the Next pass
close-out (D9). Old `pass2.md` content folds in here.
**Changes:**
- [ ] `skills/phase-plan/pass1.md`: rewritten per the above; walk-through references `walk-through.md`; § Output
  keeps a one-line pointer to `walk-through.md` so `pass3.md`'s existing reference still resolves until Phase 5;
  VA-11 anchors kept.
- [ ] Check assertions: `pass1.md` contains the gap-analysis step heading, reverse search, sibling table,
  neighbour check, probe rules, and the Next pass close-out (literals named first).
- [ ] Check assertion (absence, `pass1.md`): no `Confirm as [SEVERITY]`, no `to confirm severity` (lines 178,
  192 today).
**Call chain:** "pass 1" / "let's plan" → main loading table → `pass1.md`.
**Wiring test:** check asserts the loading table maps "pass 1" to `pass1.md` and that `pass1.md` has the
required headings.
**Depends on:** Phase 2.
**Write-set:** `skills/phase-plan/pass1.md`, `scripts/check-phase-plan.sh`.
**Risks:** `pass1.md` grows large; keep per-step text tight and move examples to the end.
**Done when:** check passes; `pass1.md` reads end to end as one pass.
**Validation:** moderate; read through once as a cold reader.
**Delivered (2026-11-12):**
- New sections `## Probe rules`, `## Gap-analysis step`, `## Next pass handoff`; `## Steps`, `## Output` and
  `## Reminders` kept. 13 `p1-*` anchors; two absences (`Confirm as [SEVERITY]`, `to confirm severity`).
- The wiring assertion became a new check type, `CHK-TABLE-MAP` (a loading-table row holds both the trigger
  phrase and the file), because an anchor literal cannot contain the table's `|`. Phase 4 adds its rows there.
  Absences live in an `ABSENT` table with `--list-absent`; both get generated fixtures.
- Cold read: one forward pointer. The gap-analysis step's first paragraph names "main file § compatibility rule",
  which Phase 8a writes (see its Changes). No formal mutation round: the two new check types are small and each
  generated fixture was watched refusing.

### Phase 4: Pass 2 = independent review

**Goal:** new `pass2.md` defining the three-lens review (D1), the reviewer brief template, the vetting step, and
the D5 trigger for re-running it on late changes.
**Changes:**
- [ ] `skills/phase-plan/pass2.md`: replaced (old gap-analysis content now lives in `pass1.md`); banner kept
  (VA-11).
- [ ] `skills/phase-plan.md` § Loading the Per-Pass Files: table rows and one base-directory line naming
  `~/.claude/coding-agents/skills/phase-plan/` (VA-1). Rows: "pass 1" / "let's plan" → `pass1.md`; "gap analysis"
  → `pass1.md` § the gap-analysis step ("plan exists: start here"); "pass 2" / "independent review" /
  "review the plan" / "plan review" → `pass2.md`; "pass 3" / "quality gates" / "final review" → `pass3.md`; the
  "pass 1+2" row removed (D2). Quick plan loads `pass1.md` + `pass3.md` (D1 skips Pass 2).
- [ ] Check assertions: three lens headings, the brief template, the vetting step, explicit `model` instruction,
  the D9 Next pass close-out; loading-table rows as above; quick plan does not name `pass2.md`; the base-directory
  line present.
**Call chain:** "pass 2" / "independent review" → loading table → `pass2.md` → Agent tool ×3.
**Wiring test:** check asserts the loading table maps "pass 2" to the independent review.
**Depends on:** Phase 3.
**Write-set:** `skills/phase-plan/pass2.md`, `skills/phase-plan.md` (loading table rows), `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate; dogfood (D12): run the new Pass 2 on this plan by reading the worktree's
`skills/phase-plan/pass2.md` by absolute path (the Skill tool still loads `main`'s files, VA-1), with the briefs
naming absolute worktree paths. Record in Phase 4's execution note that the file read has the "Independent
review" H1, that three Agent calls each set `model`, and the findings. Findings are handled as a late change (D5):
walk-through, then a scoped re-check before Phase 5.
**Delivered (2026-11-12):**
- `pass2.md` 122 lines; main file 675. RED: 10 anchors (`p2-*`, `main-base-dir`), 4 table routes (gap analysis,
  independent review, plan review, decisions), 3 absences. The quick-plan absence first passed vacuously, because
  its literal wrapped a line, until the literal was narrowed. Not in the spec: a loading-table row routing "any
  list of decisions" to `walk-through.md`.
- Dogfood: three `general-purpose` reviewers, `model: opus` passed on each call, briefs with absolute worktree
  paths. Each first reported the loaded file's H1, `# Phase Plan — Pass 2: Independent Review`. Totals: Lens A 1
  BLOCKER / 7 REVISE, Lens B 0 / 10, Lens C 0 / 8, with overlaps. The main session re-checked the BLOCKER and each
  new fact (rollback text, `REFINEMENTS.md` lines, `pass1.md`/`pass2.md` lines, one check run 1.64 s, 0 hits
  for `confirm the severity`); all held. See the Review Log entry for what changed.

### Phase 5: Pass 3 = quality gates — ✅ SHIPPED (`1c52532`)

**Goal:** `pass3.md` keeps today's gates and adds test validity (D6), hedge resolution and the "ready" gate (D5),
the bounded spot-check and deliverable anchor (from the review's Pass 3 drift finding), and slimmed concurrency
checks (D10).
**Changes:**
- [ ] `skills/phase-plan/pass3.md`: extended; spot-check step bounded; severity-confirmation bullets in Check 4
  (lines 73-77) and the § Output severity flow (lines 183-232) replaced by the D8 walk-through; walk-through
  references repointed to `walk-through.md`; "Pass 2" references with the gap-analysis meaning (lines 102,
  145-153, 242) reworded, including the "apply fixes additively … recognizable from Pass 2" wording (step 4 and
  § Reminders), which now says to replace superseded planning text in place (D5); D9 Next pass close-out; D5 "start by reviewing the previous pass's additions"; Check 7
  and § Reminders kept (VA-11).
- [ ] Check assertions: test-validity check present; "ready" requires the walk-through answers to be integrated;
  no live file contains `` `pass1.md` § Output ``; Next pass close-out present.
- [ ] Check assertion (absence, `pass3.md`): no `confirmed the severity`, no `confirmed every open question's
  severity`, no `Apply the confirmed severities` (lines 76, 187, 226 today).
**Call chain:** "pass 3" / "quality gates" → loading table → `pass3.md`.
**Wiring test:** check asserts `pass3.md` names `walk-through.md` (RED before this phase; the "pass 3" row is
already true at base, so it cannot serve as the RED step).
**Depends on:** Phase 4.
**Write-set:** `skills/phase-plan/pass3.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate.

**Delivered (2026-11-12):** RED: 8 `p3-*` anchors and 6 absences (the severity flow, `**Apply fixes
additively.**`, "take Pass 2's word", and `` `pass1.md` § Output `` across every live file), each watched failing.
Main file unchanged at 675. Check 1b holds D6; the ready gate's sentence sits on its own line. Literals with an
apostrophe need the shell's `'"'"'` escape in the check's tables (first attempt broke the table). The fixture test
now takes 195 s (98 fixtures); Phase 10a's speed-up stays where it is.

### Phase 6a: `CLAUDE.md` walk-through default and the line-limit table — ✅ SHIPPED (`96781c5`)

**Goal:** the D8 format is the default in `CLAUDE.md`, held at net zero lines (D13). (Phase 6 was split after
the Phase 4 review: the generated line-limit fixture needs the test script, a fourth file.)
**Changes:**
- [ ] `CLAUDE.md` § Explaining Design and Protocol Work: fold the D8 default into the existing "Lead with the
  decision and its options" bullet; net line count unchanged.
- [ ] Check assertion `CHK-LINES`: `CLAUDE.md` line count does not exceed its count at base `8e6fc33` (291).
  Built as an entry in a `LINE_LIMITS` table (`name|file|max lines`, `--list-line-limits`) with a fixture
  generated in `scripts/test-check-phase-plan.sh` (the file padded past its limit), so Phase 10b removes it by
  deleting one table line. Plan-scoped (see the loop rules). Phase 8b's `CHK-SIZE` is a second entry in the same
  table. RED step: the table entry with a limit of 290, watched failing, then set to 291.
- [ ] Anchor: the folded bullet's new phrase, on one line.
**Depends on:** Phase 2.
**Write-set:** `CLAUDE.md`, `scripts/check-phase-plan.sh`, `scripts/test-check-phase-plan.sh`.
**Risks:** `CLAUDE.md` is already over its 200-line budget (VA-4); D13 holds it at net zero.
**Done when:** check and test pass.
**Validation:** narrow.

**Delivered (2026-11-12):** the bullet now reads "Lead with the decision and its options, one per message for
any list of decisions; save each answer at once. Mechanics after; full detail in the repo, not the reply." Table
format is `id|file|max`, so Phase 8b adds `CHK-SIZE|skills/phase-plan.md|499` as one line. 135 assertions, 100
fixtures; main file 675.

### Phase 6b: `ask-questions-if-underspecified` walk-through references — ✅ SHIPPED (`0be79c4`)

**Goal:** the skill that hands off to phase-plan describes the decision-first walk-through.
**Changes:**
- [ ] `skills/ask-questions-if-underspecified.md` lines 54-56 and 186-189: describe the decision-first walk-through.
- [ ] Check assertion (absence, `skills/ask-questions-if-underspecified.md`): no `severity-based` (lines 56, 186,
  189 today). Scoped to that file because `py-enforcer.md:645` uses "severity-based recommendations" for its own
  reports, which is unrelated.
**Depends on:** Phase 6a.
**Write-set:** `skills/ask-questions-if-underspecified.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** narrow.

**Delivered (2026-11-12):** the anchor's section is § Relationship to phase-plan (lines 186-190 sit there, not
in § Quality gates as first written). The new text names `skills/phase-plan/walk-through.md`, so `CHK-PATH` now
checks it too.

### Phase 7: Main file, plan template — ✅ SHIPPED (`fb3c764`)

**Goal:** the template reflects D7, D9, D10 and D11: Delivery shape, Next pass, one-line Concurrency Map,
optional Read-set and Shared-state contract, traced Write-set, Verified Assumptions probe format (with "not
observed live"), close-out as a numbered final phase with "which pass should have caught this?", Review Log
hygiene.
**Changes:**
- [ ] `skills/phase-plan.md` § The Plan Doc, including § Open Questions (lines 491-498: severity stays a proposed
  tag; the "user confirms or overrides the severity" line replaced by the D8 walk-through).
- [ ] Check assertions: required template headings present, including `## Problem Statement` and `## Reasoning`
  (audit Check 7); the optional fields read `**Read-set (optional):**` and `**Shared-state contract
  (optional for sequential phases):**`.
- [ ] Check assertion (absence, `skills/phase-plan.md`): no `confirms or overrides the severity` (line 498 today).
  Then widen the earlier per-file absences (`Confirm as [SEVERITY]`, `confirmed the severity`, `confirms or
  overrides the severity`) to every live file. Only the template line goes red here; the widened ones are
  regression guards, recorded as such. `confirm the severity` is dropped: it has no live hit at base, so it could
  never fail. No allowlist: `walk-through.md` uses none of these strings. The new field labels sit on a line of
  their own in the template (they are long enough to wrap).
**Depends on:** Phase 5.
**Write-set:** `skills/phase-plan.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate.

**Delivered (2026-11-12):** main file 675 → 628 (−47; the plan expected about −6, because the Concurrency Map
and Shared-state text shrank more and the new sections came in shorter). Added an `## Execution Log` section to
the template (D10's "execution log in its own section"). The close-out line and the long field labels each sit
on their own line. Revised size estimate for Phase 8b: 628 − TRACKING 106 − Combined Pass 1+2 18 − Phase 0
template 48 ≈ 456, so the fallback is unlikely to be needed.

### Phase 8a: Main file, frame, triggers and history — ✅ SHIPPED (`e1dd358`)

**Goal:** description and triggers (D11), "one plan, three passes" text (D2; loading table done in Phase 4), the
in-flight compatibility rule (D15), usage patterns (quick plan skips Pass 2; Combined Pass 1+2 pattern removed),
guardrails ("extend structure; replace superseded planning text", D5 with its scope note), and TRACKING history
moved to `skills/phase-plan/CHANGELOG.md`.
**Changes:**
- [ ] The D15 rule lives under a heading starting `Compatibility rule`, which `pass1.md` § Gap-analysis step
  already names (Phase 3); assert it as an anchor.
- [ ] `skills/phase-plan.md`: frame, usage patterns and guardrails; stale "Pass 2 fills gaps" (line 517-518) and
  Read-set text (line 428) reworded.
- [ ] `skills/phase-plan/CHANGELOG.md`: TRACKING blocks moved except `TRACKING: File split (2026-04-16)`, which
  stays in the main file (VA-11) with one added line pointing to the changelog. Project names in the moved
  2026-04-16 Discovery-exemption block made generic (D19).
- [ ] Verification (not a committed assertion, because a deny-list in a public repo would publish the names):
  grep the touched files locally for the names Pass 2 found, using a list kept outside the repo; record "0 hits"
  and the date in the Review Log.
- [ ] The intro paragraph "Passes are additive, not destructive" (main file, after the H1) reworded to D5:
  extend structure, replace superseded planning text in place, history in the Review Log.
- [ ] § One plan, three passes names `walk-through.md` and `CHANGELOG.md` among the files in
  `skills/phase-plan/`; the pointer to `skills/phase-plan/CHANGELOG.md` sits outside any comment, so `CHK-PATH`
  proves the file exists (a pointer inside the split TRACKING comment would be invisible to the check).
- [ ] Check assertions: the D15 rule present; the split marker present in the main file. Absences (each on one
  line today): "Pass 2 reviews for gaps", "extends the base with gap analysis", "Pass 2 fills gaps",
  "### Combined Pass 1+2", "Load pass1.md + pass2.md". Front-matter (`^`) anchors for the trigger phrases
  "phase plan", "three-pass plan", "plan review" and for the D11 bulk-external-write trigger; an anchor for the D5
  guardrail's literal.
**Depends on:** Phase 7.
**Write-set:** `skills/phase-plan.md`, `skills/phase-plan/CHANGELOG.md`, `scripts/check-phase-plan.sh`.
**Risks:** the description is what triggers the skill; keep the existing trigger phrases ("phase plan",
"three-pass plan", "plan review") and the batch-approved trigger (VA-11).
**Done when:** check passes.
**Validation:** moderate; confirm the skill still lists and triggers after merge (Phase 11).

**Delivered (2026-11-12):** main file 628 → 524. D19 name check (local list, not committed): 0 hits in
`skills/phase-plan.md` and `skills/phase-plan/CHANGELOG.md`, 2026-11-12; the one project name in the moved
2026-04-16 block was made generic. `CHANGELOG.md` holds the six moved blocks as headed sections (oldest first);
the split block keeps a pointer line, and the frame names the file outside any comment, so `CHK-PATH` checks it.
The changelog anchor's section is § Per-pass skill files (the subsection that lists the files). The commit
message says 525; the count is 524.

### Phase 8b: Main file under 500 lines — ✅ SHIPPED (`bf6760d`)

**Goal:** the D13 size assertion turns GREEN. Re-measured 2026-11-12 at 675 lines: TRACKING −106 net, Concurrency
Map −41, optional-field text −29 (unmeasured), Combined Pass 1+2 −18, new sections ≈ +64, Phase 0 template −48,
giving ≈ 497: about two lines of margin. Every Delivered note from Phase 7 on records the main file's `wc -l`.
If the count is still 500 or more after the move, the walk-through offers the next candidate: § Relationship to
Other Tools (lines 216-236 today) into `execute.md`, where its agents act.
**Changes:**
- [ ] `skills/phase-plan.md`: the Phase 0 (Discovery) template block replaced by a one-line pointer to `pass1.md`.
- [ ] `skills/phase-plan/pass1.md`: receives the Phase 0 template in its own `## Phase 0 template` section
  after § Steps (inside § Steps its `###` heading would end the section and break the `Steps` anchors); step 5
  points to it. The gap-analysis step's "main file § compatibility rule" becomes a checked reference,
  `` `phase-plan.md` § Compatibility rule ``.
- [ ] Check assertion: `pass1.md` contains the Phase 0 template heading; the main file's pointer resolves (Phase 1
  section-reference check).
- [ ] Check assertion `CHK-SIZE`: `skills/phase-plan.md` under 500 lines (failing, not printed); the Discovery
  Exemption summary stays in the main file (load-bearing repetition, VA-11). Fixture: the main file padded to
  exactly 500 lines is refused; the real tree must be at 499 or fewer.
**Depends on:** Phase 8a.
**Write-set:** `skills/phase-plan.md`, `skills/phase-plan/pass1.md`, `scripts/check-phase-plan.sh`.
**Risks:** if the count is still ≥500 after the move, stop and walk the user through it rather than trimming
load-bearing text to pass the assertion.
**Done when:** check passes, including the size assertion.
**Validation:** moderate.

**Delivered (2026-11-12):** main file 524 → 478, 21 lines under budget; the fallback move was not needed. The
template sits in `pass1.md` as plain text under `## Phase 0 template` (no inner `###` heading, which would end the
section), placed after § Steps; step 5 points to it. `pass1.md` 313 lines.

### Phase 9a: Execution rules, gates and states — ✅ SHIPPED (`5020a8f`)

**Goal:** `execute.md` start-of-run and per-phase gates: refuse to start without the Pass 3 Review Log entry
(D11), re-measure gating figures at start (D4), phase states built → merged → deployed → observed and the
external-write tier (D7), parallel protocol reached only when declared (D10).
**Changes:**
- [ ] `skills/phase-plan/execute.md` § The execution reminder, § Phase completion checklist (including D6:
  mutation testing as an exit step for logic-heavy phases), § Executing Parallel Phases (entry condition; and
  line 252's "Pass 2 disjointness check" reworded to the gap-analysis step). "Plan matches reality" kept.
- [ ] Check assertions: start-of-execution Pass 3 gate present; phase-state vocabulary present; external-write tier
  steps present.
**Depends on:** Phase 8b.
**Write-set:** `skills/phase-plan/execute.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate.

**Delivered (2026-11-12):** the gate lives in a new `## Before starting` section ahead of the execution
reminder, rather than inside it, so the reminder stays the short printable block. `execute.md` 731 lines. Literals
that must sit on one line are broken onto their own lines in the bullets.

### Phase 9b: Execution rules, change handling and close-out

**Goal:** `execute.md` handling of change during execution and the close: late-change re-check (D5), walk-through
for execution decisions (D8), close-out as a numbered final phase with "which pass should have caught this?" and
probe fixtures in the repo (D11). Close-out narrative and worktree removal kept (VA-11).
**Changes:**
- [ ] `skills/phase-plan/execute.md` § Keep the plan doc in sync with reality, including its § When the plan
  closes subsection; "Delivered:" and skip records stay append-only (D5 scope); D9 "a compacted context is not
  fresh: say so and hand off"; the 2026-10-09 TRACKING block's three repo names made generic (D19).
- [ ] Check assertions: late-change re-check present; "which pass should have caught this?" present, on a line
  of its own (here and in the Phase 7 template); VA-11
  close-out anchors present.
**Depends on:** Phase 9a.
**Write-set:** `skills/phase-plan/execute.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate.

### Phase 10a: Audit and plan-doc references

**Goal:** `/audit` and `plan-doc-reasoning` match the new shape; `/audit` is runnable and is the gate (D18).
**Changes:**
- [ ] `commands/audit.md`: Check 1 exemption wording ("per-pass content files" → "files under
  `skills/phase-plan/`"); Check 6 prints MISSING when `skills/phase-plan.md` lacks the split marker; plus the
  new check (D18) that runs `bash scripts/test-check-phase-plan.sh && bash scripts/check-phase-plan.sh` and prints
  its output.
- [ ] `.claude/commands/audit.md`: symlink to `../../commands/audit.md` (D18).
- [ ] `skills/plan-doc-reasoning.md` line 108 wording.
**Depends on:** Phase 9b.
**Write-set:** `commands/audit.md`, `skills/plan-doc-reasoning.md`, `.claude/commands/audit.md`.
**Wiring test (user checkpoint):** project commands are read at session start, so after Phase 10a's commit the
user opens a new Claude Code session with this worktree as its working directory and types `/audit`; it prints
the structure-check output. Refusal through the same session: remove the split marker from
`skills/phase-plan.md` (uncommitted), re-run `/audit`, and see the new check report `CHK-MARKER` and Check 6 print
MISSING. Restore only after `git status --porcelain skills/phase-plan.md` shows that one edit and nothing else:
`git checkout HEAD -- skills/phase-plan.md`, then re-run the check.
**Done when:** `/audit` shows no flags beyond the VA-9 baseline (and `phase-plan.md` 673 cleared); the structural
check passes through `/audit`.
**Risk:** the test took 128-144 s at Phase 4 (81 fixtures; each check run about 1.6 s, mostly forked `awk`
processes), and grows with each anchor. Time it through `/audit` and record the time. If it is near a timeout,
make the check cheaper first: strip comments once per file and resolve all references in one `awk` pass.
**Validation:** narrow.

### Phase 10b: Repo docs

**Goal:** README and the external-learn ledger are current.
**Changes:**
- [ ] `README.md` § What's here: a `scripts/` row and one line declaring the gate (D18). The row lands here, not
  in Phase 1 (which would be a fourth file there); one PR means `main` never sees the gap. Asserted as anchors
  (`README.md` names `scripts/` and `/audit` in § What's here); `agents.md`'s Phase 1 row is asserted the same way.
- [ ] `EXTERNAL-LEARNINGS.md` line 117: close the parked walk-through question with a pointer to D8.
**Depends on:** Phase 10a.
**Write-set:** `README.md`, `EXTERNAL-LEARNINGS.md`, `scripts/check-phase-plan.sh`.
- [ ] `scripts/check-phase-plan.sh`: remove the `CHK-LINES` table line (its fixture is generated, so it goes
  too; `CLAUDE.md` still at 291 is confirmed first).
- [ ] The README gate line says when to run `/audit`: before each PR, and after merge (agents.md Post-Merge).
**Done when:** structural check passes; README § What's here has the `scripts/` row and the gate line.
**Validation:** narrow.

### Phase 11: Close-out

**Goal:** the plan closes in the v2 shape it introduces.
**Changes:**
- [ ] Open PR 1; after merge, update the main checkout.
- [ ] **Observed check (user checkpoint: the user opens the session):** in a fresh session whose working
  directory is a repo outside coding-agents, run the
  skill on a real plan and record what was seen: the pass file read from `~/.claude/coding-agents/skills/phase-plan/`,
  three Agent calls each with `model` set, one question per message, D15 behaviour on a plan with old labels,
  and one handoff paste that starts with `/phase-plan`. Record the session date and the checkout's HEAD.
  If it fails: the wrong pass file or the old loading table means rollback (Delivery shape); behaviour drift
  (two questions in one message, a missing `model`) means fix forward in a new PR plus a Discovery entry. PR 2
  records whichever happened.
- [ ] Refresh the two auto-memory files outside this repo that describe the old pass order (VA-2), and this
  project's own memory notes about the plan.
- [ ] Record the `CLAUDE.md` overage (291 vs 200) as a `REFINEMENTS.md` follow-up entry (D13).
- [ ] Outcome Summary, status line, Discoveries with "which pass should have caught this?".
- [ ] `REFINEMENTS.md` entry: Status stays `accepted` with "implementation pending" dropped; add "Applied <date>
  in <PR>" to Notes (VA-10).
- [ ] Open PR 2 (records only: this plan, `REFINEMENTS.md`; D16); after merge, update the main checkout.
- [ ] Remove the `phase-plan-v2` worktree and branch after both PRs have landed.
**Write-set:** this plan, `REFINEMENTS.md` (plus the two auto-memory files outside the repo).
**Done when:** the skill is observed live in the new shape and the worktree is removed.
**Validation:** broad; live session observation.

## Open Questions

- [RESOLVED → D12] **OQ-1 What counts as the test for skill text?** Option A chosen 2026-11-09: structural
  check + `/audit` + dogfooding.
- [RESOLVED → D13] **OQ-2 Size budgets.** Option A chosen 2026-11-09: skill under 500 as a hard check;
  `CLAUDE.md` net zero; its existing overage is a separate follow-up.
- [RESOLVED → D14] **OQ-3 Evidence location.** Option A chosen 2026-11-09: local only, generic summaries in
  public text.
- [RESOLVED → D15] **GA-W1 Plans already in flight under the old pass labels.** Option A chosen 2026-11-09.
- [RESOLVED → D16] **GA-W2 Where close-out records land after merge.** Option A chosen 2026-11-09.
- [RESOLVED → D17] **Pass2-W1 Size route.** Option A chosen 2026-11-09.
- [RESOLVED → D18] **Pass2-W2 Keeping the checks live.** Option A chosen 2026-11-09.
- [RESOLVED → D19] **Pass2-W3 Work names in moved TRACKING text.** Option A chosen 2026-11-09.
- [RESOLVED → D20] **Pass2-W4 Commit cadence during execution.** Option A chosen 2026-11-09.
- **Decided by agent (override if wanted): review grades vs question tags.** D1's finding grades
  (BLOCKER / REVISE / CONFIRMED) sit next to the question tags (BLOCKING / PHASE-GATED / ADVISORY). Keep both,
  because they label different things (a reviewer's finding vs a decision the user owns); `walk-through.md` states
  the mapping: a BLOCKER finding that needs a user decision becomes a BLOCKING question.
- **Decided by agent after the Phase 4 dogfood review (override if wanted):**
  - *D15 matching keyed on labels, not the merge date;* sessions open at pull time are restarted, not re-invoked.
  - *Rollback reverses PR 1's own diff* rather than restoring files from the base.
  - *`CHK-LINES` is plan-scoped* and removed in Phase 10b; every other assertion is permanent.
  - *Phase 10b's done-when narrowed* to the `scripts/` row and gate line rather than adding `plans/` and
    `.claude/` rows (not in scope).
  - *A pre-named size fallback* (§ Relationship to Other Tools into `execute.md`), offered by walk-through only if
    the main file is still 500 or more after Phase 8b.
- **Decided by agent in Pass 3 (override if wanted):**
  - *Severity wording asserted per file, not by one expected-red assertion.* Each phase that rewrites a file
    asserts the old wording gone from that file; Phase 7 adds the live-scope sweep. Keeps every commit green.
  - *An allowlist for illustrative § references* instead of editing `external-learn.md` (a file no phase
    touches). It fails if a listed reference starts to resolve, so it cannot grow quietly.
  - *Word-wise § matching* (at least two leading words) instead of exact headings, because references run on into
    prose. Exact matching would refuse today's tree; one-word matching would let most renames pass.
  - *README `scripts/` row stays in Phase 10b* (Phase 1 is at its 3-file limit); asserted, and never stale on
    `main` because PR 1 carries both.
  - *Two user checkpoints made explicit:* opening a session in the worktree for `/audit` (Phase 10a) and in
    another repo for the observed check (Phase 11).

## Review Log

### Pass 1 (draft) — 2026-11-09
- Built from the 2026-11-09 usage review and the user's one-at-a-time walk-through of its recommendations
  (D1–D11, all user-confirmed; D12–D14 from OQ-1–OQ-3).
- Grounded against the repo: install path (VA-1), consumer references (VA-2, VA-3), budgets (VA-4), gates
  (VA-5), visibility (VA-8).
- Not yet run: the explicit gap-analysis checklist step (D3), Pass 2, Pass 3.

### Pass 1: Gap-analysis step — 2026-11-09
Run with the current `skills/phase-plan/pass2.md` checklist plus the D3 outward sweep (the new pass files do
not exist yet). Reverse search terms: `pass[123].md`, `phase-plan/`, `execute.md`, `three-pass`, `Pass [123]`,
`Combined Pass`, `Concurrency Map`, `Read-set`, `Shared-state contract`, `Write-set`, `Re-entry verification`,
`4-file`, `Confirm as`, `TRACKING`; all file types, this repo (≈150 hits, most inside the skill itself), the two
org-layer repos (0 relevant), `plans/` (2 files: this plan and one historical review).
**Found:**
- Phases 3–5 asserted loading-table mappings that only Phase 8 would write (the table lives in the main file).
- The rewrite could silently drop five refinements already applied in the target files (VA-11).
- Phase 1's "referenced anywhere" would have graded ledgers and old plans that hold historical paths, and missed
  the `pass{1,2,3}.md` brace form in the description.
- Value domain: `REFINEMENTS.md` has no `Applied` status (VA-10); Phase 11 and Documentation Impact said
  "→ Applied".
- `pass3.md` points to "the walk-through procedure from `pass1.md` § Output"; Phase 3 would have removed the
  target two phases before Phase 5 repoints it.
- `/audit` Check 6 greps every file in `skills/phase-plan/`, so after history moves to `CHANGELOG.md` it stays
  green even if the main file loses its marker (false-green shape: check grading the wrong set).
- Phase 9 bundled six decisions across eight sections of a 705-line file behind a "may need splitting" hedge.
- The verification loop named "the hook tests" without a command or baseline.
- Outward: plans in flight in other repos will read the new labels (GA-W1); post-merge records have no PR (GA-W2).
- Main file size after Phase 7 additions estimated at ≈516, so the D13 route needs one more move.
**Concurrency:**
- No changes; map confirmed. Every phase writes `scripts/check-phase-plan.sh`, so no two phases are disjoint.
**Changed:**
- Phase 4 now edits the loading-table rows (write-set 3); Phase 8 no longer owns the table.
- Phase 1 check: scope limited to live instruction files, brace forms expanded, VA-11 anchors asserted, three
  refusal fixtures (missing file, dropped anchor, empty directory) built in `mktemp -d`.
- Phases 3, 4, 5, 9b keep their VA-11 anchors; Phase 3 leaves a pointer in `pass1.md` § Output; Phase 5 repoints
  `pass3.md` and asserts no live file points to `pass1.md § Output`.
- Phase 9 split into 9a (gates and states) and 9b (change handling and close-out); Phase 10 depends on 9b.
- Phase 10 and Documentation Impact: Check 1 exemption covers the new files; Check 6 names the main file.
- Phase 11 and Documentation Impact: Notes line instead of a Status change.
- Verification loop names the commands; VA-9 records the green baseline; Phase 8 risk carries the size estimate.
- Added VA-9 to VA-12; VA-2 broadened to the org-layer repos; `commands/skills.md` confirmed, no change.
- Walk-through: GA-W1 → D15 (A), GA-W2 → D16 (A). Decided by agent: keep finding grades and question tags separate, mapping in `walk-through.md`.
**Confirmed:**
- Every phase is at 3 files or fewer after tracing; no phase touches hooks; no hook references the pass files.
- Sibling and org-layer repos carry no references; `origin/main` unchanged since the base; no competing PRs or
  worktrees.
- D1–D14 still hold against the full plan; no rejected alternative looks better given the traced write-sets.

### Pass 2: Independent review — 2026-11-09
Run from D1's text (the new `pass2.md` does not exist yet). Three `general-purpose` subagents on the session
model (`model: opus` passed explicitly), one per lens, each briefed refute-first with the plan path and the
files its lens needs, read-only. Raw totals: outcome + failure walk 4 BLOCKER / 5 REVISE / 3 CONFIRMED; outward
consistency 2 / 10 / 6; facts vs code 0 / 13 / 8. The main session re-checked each BLOCKER and each new fact
against the files before folding it in (all held); duplicates across lenses merged.
**Found (merged):**
- The old severity-confirmation gate survives where no phase rewrote it (`pass3.md` Check 4 and § Output; the
  template's § Open Questions), and Phase 2's assertion string never existed, so it could not go red.
- Phase 1's check could not see the references that break (`` `X.md` § Heading `` form, 13 in live files); its
  empty-set fixture already failed for another reason; a marker check written like audit Check 6 passes with
  the main file's marker removed (`execute.md` has 3); refusals were judged by exit code only.
- Moving all TRACKING history breaks `/audit` Check 6 and `skill-hygiene.md`, which name the split marker; the
  size estimate was unmeasured (measured ≈534-545), and Phase 8 had no file to receive the overflow.
- `/audit` is not registered where any session reads it; nothing runs the structural check after close.
- D5's "replace in place" contradicted `execute.md`'s append-only "Delivered:" rule; D11's start gate would
  refuse batch-approved plans; D15's matching did not fit real Review Log headings (157 "Pass 2: Gap Analysis",
  19 bare "Pass 2", 7 "Pass 1 + Pass 2"), and sessions open at pull time keep the old table.
- No rollback; `git revert -m1` of PR 1 would delete this plan.
- Loading table: "review the plan" / "plan review" unmapped; quick plan would load the new `pass2.md`; stale
  gap-analysis meanings of "Pass 2" in five places; Phase 5's wiring test was already true at base.
- VA corrections: per-pass paths are resolved by the model (16 reads to a nonexistent path); VA-2's grep could
  not match; VA-11 missed six applied changes; VA-12 missed a dormant plan targeting the main file; `/audit` had
  no recorded baseline; REFINEMENTS counts and the entry's "D1–D11" were stale.
- Unassigned decision parts: D6 mutation exit step, D9 Next pass in every pass, D5 "review the previous pass's
  additions", D13 overage follow-up.
- Docs: README § What's here lacks `scripts/`; `EXTERNAL-LEARNINGS.md` has a parked question D8 answers; two
  auto-memory files outside the repo describe the old pass order.
**Concurrency:**
- No changes; map confirmed. Every phase still writes `scripts/check-phase-plan.sh`.
**Changed:**
- Phase 1 rewritten: root argument, assertion ids, section-reference resolution, minimum counts, split-marker
  assertion on the main file, per-anchor section-scoped checks, seven refusal fixtures matched by id.
- Phase 2/5/6/7: literal severity patterns over live files; `pass3.md` severity flow and template § Open
  Questions added to the write; stale "Pass 2" meanings reworded; Phase 5 wiring test replaced.
- Phase 4: base-directory line and a row for every trigger phrase; quick plan skips `pass2.md`.
- Phase 8 split into 8a (frame, D15, history move keeping the split block) and 8b (size, route per Pass2-W1).
- Phase 9a/9b: D6, D9, D5 scope assigned. Phase 10 split into 10a (audit, plan-doc-reasoning; Pass2-W2) and 10b
  (README, EXTERNAL-LEARNINGS). Phase 11: observed check from outside the repo with recorded behaviour; memory
  refresh; overage follow-up.
- Delivery shape: rollback procedure, status on `main` between PRs, re-invoke in open sessions.
- VA-1, VA-2, VA-9, VA-10, VA-11, VA-12 corrected; Documentation Impact extended.
- Decided by agent (override if wanted): D5 scope (planning text replaced, execution records append-only); D11
  gate scope (batch-approved plans exempt); D15 matching (date-keyed; executions already started continue).
- `REFINEMENTS.md` entry: Target and decision range corrected in place.
- Walk-through: Pass2-W1 → D17, W2 → D18, W3 → D19, W4 → D20 (all option A).
**Confirmed:**
- VA-4, VA-5, VA-6 (the `opus` alias resolving to the exact session model is unverified), VA-7, VA-8, VA-9 hold.
- The `CLAUDE.md` net-zero assertion can go red (291 at base and HEAD; target bullet at `CLAUDE.md:221`).
- The going-live pull fast-forwards: main checkout clean at `8e6fc33`, `pull.rebase=true`.
- TDD hooks cannot interfere (they classify only code under `src|lib|app|pkg|cmd|internal`).
- The 4-file rule has one home (`pass1.md:129-133`); audit Check 1 and Check 2 already handle the new files.

### Pass 3: Quality gates — 2026-11-12
Run with the current `skills/phase-plan/pass3.md` plus D6 and D5, starting from Pass 2's additions (the Phase 1
rewrite and the severity assertions). Spot-checks: `origin/main` still `8e6fc33` (`git ls-remote`); tree clean;
hook tests PASS 34/34 and ALL PASS (VA-9 holds); every live § reference and severity sentence listed by grep and
compared against the plan.
**TDD ordering:**
- Phase 2's severity assertion could not work: the verification loop must pass before each commit, so a
  deliberately red assertion blocks Phases 2–6, and its patterns matched only `pass1.md:192` (`pass3.md:76`
  says "confirmed the severity", template line 498 "confirms or overrides the severity"). Replaced by per-file
  absence assertions in Phases 3, 5, 6 and 7 (each red at its phase start, using the strings found today) and a
  live-scope sweep in Phase 7. Phase 6's pattern missed two of three `ask-questions` hits; now scoped to that
  file (`py-enforcer.md` uses "severity-based" for something else).
- New loop rules: literals named before text is edited, a refusal fixture for every assertion (generated for
  anchors and absences), no expected-red.
- Phase 7's "Read-set not listed as required" given literal field labels.
**Phase 1 fixtures (refused by their own id?):**
- `CHK-SECTION` was never defined and the path check had no id; ids now map one to one to assertions, with a
  fixed output line and exact-id matching.
- The § check as written would have refused today's tree twice over: references run on into prose (`§ Step 4 for
  the …` vs `### Step 4 — Consolidate locally`), and `external-learn.md` cites a heading that does not exist
  (§ Mock misuse, an illustrative example). Word-wise matching rule and a both-ways allowlist added.
- The renamed-`## Output` fixture would stop being refused after Phase 5 removes the only references to it, and a
  rename that kept the prefix would still pass; replaced by an injected broken reference.
- No fixture exercised the comment-stripping or section-scoping claims; two added. Brace-form path fixture
  added. Glob and directory path forms skipped; bare table cells resolved under `skills/phase-plan/`.
- Default ROOT from the script's directory (fixture copies have no `.git`); bash 3.2 and BSD tools.
- Phase 1 now ends with a hand-run mutation round on the check (D6), with the commit-first restore rule.
**Observability:**
- The check's output format is its observability: `FAIL <id>: <file>:<line> <detail>` plus a summary line; the
  test prints expected and actual ids per fixture. No runtime logging applies (skill text and shell checks).
**Debugging readiness:**
- Each failure names its assertion id and location; one commit per phase with the RED ids in the message.
- User checkpoints made explicit: Phase 10a (`/audit` in a session opened in the worktree, refusal shown, restore
  after `git status --porcelain`) and Phase 11 (observed check in a session the user opens elsewhere).
**Validation calibration:**
- Phase 1 raised to moderate (every later phase relies on it). Phase 2 dogfood made concrete (cold read against
  the recorded Pass2-W1 walk-through). Phase 4 dogfood reads the worktree's `pass2.md` by absolute path and
  records the result in Phase 4, not Phase 11; its findings follow D5. Size and `CLAUDE.md` line assertions get
  boundary fixtures (500 lines refused; one appended line refused).
**Concurrency honesty:**
- Map confirmed; sequential plan. Phase 10b now also writes the check (anchors), so every phase but 10a and 11
  writes `scripts/check-phase-plan.sh`.
**Discovery:**
- No Phase 0; every assumption has firsthand evidence in Verified Assumptions.
**Coherence:**
- The plan still solves the stated problem; no scope added beyond test rigour. D1–D20 unchanged. Pass 3's own
  engineering choices are listed under Open Questions as decided by agent.
**Documentation impact:**
- `plan-doc-reasoning.md` pointed at Phase 10a (was "Phase 10"). README's `scripts/` row stays in Phase 10b by
  choice and is now asserted, as is `agents.md`'s Phase 1 row. Every other entry has its phase.
**Confirmed ready:** yes. No open questions; five decided-by-agent items listed for override.

### Execution: Phase 4 dogfood review — 2026-11-12
The new `pass2.md` run on this plan (D12), three lenses, `model: opus` on each call. Every BLOCKER and new fact
re-checked by the main session before folding in; all held. No finding needed the user: each had one correct
fix or revised an agent decision (listed under Open Questions).
**Found (merged):**
- BLOCKER (A): rollback restored shared files wholesale from the base, discarding any later work in them.
- Plan records lagged the branch: Phase 4 unrecorded, Next pass stale (A, B, C).
- Skill text shipped in Phases 3-4: `pass1.md` always handed off to Pass 2, even for a quick plan (B); the
  handoff paste did not load the main file (A); `pass2.md` re-checked "every BLOCKER and every new fact", not
  every claim (B).
- D15 matching keyed on a merge date that does not exist when the rule is written (A); open sessions and the pull
  had no check (A); a failed observed check had no response (A); `CHK-LINES` would freeze `CLAUDE.md` after
  close (A).
- Size margin about two lines, not 45 (B, C); Phase 8b's template move would break three `Steps` anchors because
  headings in code fences count (C); test runtime 128-144 s, not 40 (A, C).
- Assertions that could pass vacuously: Phase 7's `confirm the severity` (0 hits at base), a CHANGELOG pointer
  inside a comment, an unbacked "compatibility rule" pointer, long literals that may wrap (C). Phase 8a asserted
  none of its own rewrites (C).
- Docs: Phase 10b done-when unmeetable (README omits `plans/` and `.claude/`), `REFINEMENTS.md` entry stale
  (D1–D16, Target, "implementation pending"), rollback list missing the new symlink, frame not naming the new
  files, additive wording left in the intro and `pass3.md`, a third memory note (B).
**Changed:**
- Skill text (next commit): `pass1.md` close-out names Pass 3 for a quick plan; the handoff paste starts with
  `/phase-plan <pass> <absolute plan path>`; `pass2.md` re-checks every claim. Anchors `p1-quick-close`,
  `p1-paste-loads-main`, absence `p2-blocker-only`, each watched RED.
- Plan: Delivery shape rollback reverses only PR 1's diff; going-live pull checks; D15 matching by label and new
  sessions instead of re-invoke; loop rules (one-line literals, record before validating, which assertions stay);
  Phases 5, 6, 7, 8a, 8b, 9b, 10a, 10b, 11 extended as each finding names; `REFINEMENTS.md` entry corrected.
**Dropped:** none.
**Confirmed:** install path and routing; gates green at HEAD; mixed state cannot reach `main`; Outcome Summary
counts re-run on archived trees; the literals Phases 5-6 will retire each sit on one line; no internal names in
the added text.

## Next pass

Paste: `/phase-plan execute ~/git/chasemp/coding-agents.worktrees/phase-plan-v2/plans/2026-11-09-1-plan-phase-plan-v2.md`
(branch `phase-plan-v2`, base `origin/main` `8e6fc33`; re-check with `git ls-remote`). **Continue execution at
Phase 9b**, loading the worktree's `skills/phase-plan/execute.md`. Phases 1-4 shipped (Outcome Summary); the
Phase 4 dogfood review is folded in (Review Log). Locked: D1–D20 and the decided-by-agent items under Open
Questions. Per phase: literals into the check's tables first (`ANCHORS`, `ABSENT`, `TABLE_MAP` in
`scripts/check-phase-plan.sh`; Phase 6a adds `LINE_LIMITS`), each on one line in the target file, watch RED, edit
text, then `bash scripts/test-check-phase-plan.sh && bash scripts/check-phase-plan.sh` plus the hook tests,
commit (D20), record the phase. A test run takes about 2.5 minutes; run it in the background. Commit locally;
push, PRs, merge and pull need the user's say-so. Stop for the user at the Phase 10a and Phase 11 checkpoints.
Done when Phase 11 is closed.
