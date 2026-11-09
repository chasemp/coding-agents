# phase-plan v2: outward-looking passes, an independent review, and a leaner template

**Status:** Pass 1 draft (plan + walk-through decisions). Gap-analysis step, Pass 2 (independent review) and
Pass 3 (quality gates) not yet run. No skill files changed yet.
**Branch / worktree:** `phase-plan-v2` at `~/git/chasemp/coding-agents.worktrees/phase-plan-v2`, off
`origin/main` `8e6fc33`.

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
  open questions before ready.
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
  batch-approved-in-conversation trigger.
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

## Verified Assumptions

- **VA-1** The skill is registered through `~/.claude/commands/phase-plan.md`, a symlink to
  `../coding-agents/skills/phase-plan.md`; `~/.claude/coding-agents` is a symlink to
  `~/git/chasemp/coding-agents` (the main checkout). Per-pass files are read by relative path
  `skills/phase-plan/*.md`. *Evidence:* `ls -la`/`readlink` on 2026-11-09. Consequence: worktree edits are inert
  until merged to `main` and the main checkout is updated.
- **VA-2** No other repo's instruction files reference the pass files or pass numbers. *Evidence:* grep of
  the user's personal and work repo trees for `pass[123].md|phase-plan/pass|Pass 2 (gap|Pass 3 (quality|three-pass`
  restricted to `.claude/`, `CLAUDE.md`, `AGENTS.md`: 0 hits outside this repo, 2026-11-09.
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

## Documentation Impact

- `skills/ask-questions-if-underspecified.md` (lines 54, 186): describes phase-plan's walk-through as
  severity-based. Update to the decision-first format. Phase 6.
- `skills/plan-doc-reasoning.md` (line 108): "three passes" stays true; re-read wording against the new pass
  names. Phase 10.
- `commands/audit.md` Check 1 (exemption names the per-pass files) and Check 6 (TRACKING marker location, if
  TRACKING history moves to a changelog): Phase 10.
- `commands/skills.md` line 38: excludes `skills/phase-plan/*.md`; still correct if new files land there and
  `scripts/` is not a skill directory. Confirm in Phase 1.
- `agents.md` § File reference: add the new `scripts/` check and the new per-pass files. Phases 1 and 10.
- `CLAUDE.md` § Explaining Design and Protocol Work: one line (D8). Phase 6.
- `REFINEMENTS.md`: new entry for this plan (written with the plan); status → Applied at close-out.
- `skills/skill-hygiene.md` line 98: historical example; no change expected. Confirm in Phase 10.
- Grep terms used: `phase-plan`, `three-pass`, `pass ?[123]`, `pass[123].md`, `execute.md`, across `*.md` and
  `*.sh`.

## Delivery shape

- **PRs:** one PR for the whole plan (`phase-plan-v2` → `main`), opened at the end of execution.
- **Gates:** the structural check from Phase 1 passes; `/audit` run with no new flags; user review and merge
  (no review bot in this repo).
- **Going live:** after merge, update the main checkout (`git -C ~/git/chasemp/coding-agents pull`), which the
  `~/.claude` symlinks read. Then the observed check in Phase 11.
- **Manual steps:** none beyond the pull.
- **Calendar or unattended jobs:** none.

## Concurrency Map

All phases sequential: most phases edit `skills/phase-plan.md` or the structural check, and later pass files
reference earlier ones.

## Phases

Every phase follows the same verification loop: add the phase's assertions to the structural check (RED), edit
the skill text (GREEN), run the check and the hook tests, then commit.

### Phase 1: Structural check for the skill

**Goal:** a test-first harness for skill text, so each later phase has a RED → GREEN check.
**Changes:**
- [ ] `scripts/check-phase-plan.sh`: asserts invariants that must survive the rewrite: every file named in the
  main file's loading table exists; every `skills/phase-plan/*.md` path referenced anywhere resolves; main file
  keeps a TRACKING marker; prints line counts against the budgets in VA-4.
- [ ] `scripts/test-check-phase-plan.sh`: two fixtures, mirroring `hooks/test-*.sh`. A broken copy (a loading
  table naming a missing file) must be refused; the current tree must pass.
- [ ] `agents.md` § File reference: list `scripts/`.
**Call chain:** maintainer or agent → `scripts/test-check-phase-plan.sh` → `scripts/check-phase-plan.sh` →
skill files.
**Wiring test:** `scripts/test-check-phase-plan.sh` exits 0 with both fixtures exercised; the refusal fixture
is watched failing first.
**Depends on:** D12.
**Write-set:** `scripts/check-phase-plan.sh`, `scripts/test-check-phase-plan.sh`, `agents.md`.
**Risks:** a check that passes on an empty set (no files found) is the classic false green; the refusal fixture
covers it.
**Done when:** the check refuses the broken fixture and passes the current tree. Verified by
`bash scripts/test-check-phase-plan.sh`.
**Validation:** narrow; tests sufficient.

### Phase 2: Canonical walk-through file

**Goal:** one decision-first walk-through procedure (D8) that every pass and execution reference.
**Changes:**
- [ ] `skills/phase-plan/walk-through.md`: the procedure from D8, with one worked example item.
- [ ] Check assertions: the file exists; it contains no "Confirm as BLOCKING" severity-confirmation prompt.
**Call chain:** pass file close-out → `walk-through.md`.
**Wiring test:** check asserts `walk-through.md` is referenced by the main file's loading table or guardrails
(made GREEN here by one reference line in the main file).
**Depends on:** Phase 1.
**Write-set:** `skills/phase-plan/walk-through.md`, `skills/phase-plan.md` (one reference line),
`scripts/check-phase-plan.sh`.
**Done when:** the walk-through exists and is referenced; check passes.
**Validation:** moderate; also run the procedure on this plan's open questions once (dogfood).

### Phase 3: Pass 1 = plan + gap analysis

**Goal:** `pass1.md` covers drafting, the probe rules (D4), the explicit gap-analysis checklist with the outward
sweep (D3), Delivery shape filling (D7), traced write-sets and the reworded size rule (D10), and the Next pass
close-out (D9). Old `pass2.md` content folds in here.
**Changes:**
- [ ] `skills/phase-plan/pass1.md`: rewritten per the above; walk-through references `walk-through.md`.
- [ ] Check assertions: `pass1.md` contains the gap-analysis step heading, reverse search, sibling table,
  neighbour check, probe rules, and the Next pass close-out.
**Call chain:** "pass 1" / "let's plan" → main loading table → `pass1.md`.
**Wiring test:** check asserts the loading table maps "pass 1" to `pass1.md` and that `pass1.md` has the
required headings.
**Depends on:** Phase 2.
**Write-set:** `skills/phase-plan/pass1.md`, `scripts/check-phase-plan.sh`.
**Risks:** `pass1.md` grows large; keep per-step text tight and move examples to the end.
**Done when:** check passes; `pass1.md` reads end to end as one pass.
**Validation:** moderate; read through once as a cold reader.

### Phase 4: Pass 2 = independent review

**Goal:** new `pass2.md` defining the three-lens review (D1), the reviewer brief template, the vetting step, and
the D5 trigger for re-running it on late changes.
**Changes:**
- [ ] `skills/phase-plan/pass2.md`: replaced (old gap-analysis content now lives in `pass1.md`).
- [ ] Check assertions: three lens headings, the brief template, the vetting step, explicit `model` instruction.
**Call chain:** "pass 2" / "independent review" → loading table → `pass2.md` → Agent tool ×3.
**Wiring test:** check asserts the loading table maps "pass 2" to the independent review.
**Depends on:** Phase 3.
**Write-set:** `skills/phase-plan/pass2.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate; dogfood: run the new Pass 2 on this plan from the worktree files (Phase 11 records it).

### Phase 5: Pass 3 = quality gates

**Goal:** `pass3.md` keeps today's gates and adds test validity (D6), hedge resolution and the "ready" gate (D5),
the bounded spot-check and deliverable anchor (from the review's Pass 3 drift finding), and slimmed concurrency
checks (D10).
**Changes:**
- [ ] `skills/phase-plan/pass3.md`: extended; spot-check step bounded.
- [ ] Check assertions: test-validity check present; "ready" requires the walk-through answers to be integrated.
**Call chain:** "pass 3" / "quality gates" → loading table → `pass3.md`.
**Wiring test:** check asserts the loading table maps "pass 3" to the quality gates.
**Depends on:** Phase 4.
**Write-set:** `skills/phase-plan/pass3.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate.

### Phase 6: Walk-through references outside the skill

**Goal:** the D8 format is the default everywhere it is described.
**Changes:**
- [ ] `skills/ask-questions-if-underspecified.md` lines 54 and 186: describe the decision-first walk-through.
- [ ] `CLAUDE.md` § Explaining Design and Protocol Work: fold the D8 default into the existing "Lead with the
  decision and its options" bullet; net line count unchanged (D13).
- [ ] Check assertion: `CLAUDE.md` line count does not exceed its count at base `8e6fc33` (291).
- [ ] Check assertion: no file in the repo describes phase-plan's walk-through as severity-based.
**Depends on:** Phase 2.
**Write-set:** `skills/ask-questions-if-underspecified.md`, `CLAUDE.md`, `scripts/check-phase-plan.sh`.
**Risks:** `CLAUDE.md` is already over its 200-line budget (VA-4); D13 holds it at net zero.
**Done when:** check passes.
**Validation:** narrow.

### Phase 7: Main file, plan template

**Goal:** the template reflects D7, D9, D10 and D11: Delivery shape, Next pass, one-line Concurrency Map,
optional Read-set and Shared-state contract, traced Write-set, Verified Assumptions probe format (with "not
observed live"), close-out as a numbered final phase with "which pass should have caught this?", Review Log
hygiene.
**Changes:**
- [ ] `skills/phase-plan.md` § The Plan Doc.
- [ ] Check assertions: required template headings present; Read-set not listed as required.
**Depends on:** Phase 5.
**Write-set:** `skills/phase-plan.md`, `scripts/check-phase-plan.sh`.
**Done when:** check passes.
**Validation:** moderate.

### Phase 8: Main file, frame, triggers and size

**Goal:** description and triggers (D11), "one plan, three passes" text and loading table (D2), usage patterns
(quick plan skips Pass 2), guardrails ("extend structure; replace superseded text", D5), and the main file under
its 500-line budget (D13) by moving TRACKING history to `skills/phase-plan/CHANGELOG.md`, applying the D10
Concurrency Map cut, and moving Usage Patterns detail into per-pass files if still needed.
**Changes:**
- [ ] `skills/phase-plan.md`: frame and guardrails.
- [ ] `skills/phase-plan/CHANGELOG.md`: TRACKING history moved verbatim, with a pointer left in the main file.
- [ ] Check assertions: main file under 500 lines; a TRACKING marker kept in the main file.
**Depends on:** Phase 7.
**Write-set:** `skills/phase-plan.md`, `skills/phase-plan/CHANGELOG.md`, `scripts/check-phase-plan.sh`.
**Risks:** the description is what triggers the skill; keep the existing trigger phrases ("phase plan",
"three-pass plan", "plan review").
**Done when:** check passes, including the size assertion.
**Validation:** moderate; confirm the skill still lists and triggers after merge (Phase 11).

### Phase 9: Execution rules

**Goal:** `execute.md` carries D4 (re-measure gating figures), D5 (late-change re-check), D7 (phase states,
external-write tier execution), D8 (walk-through for execution decisions), D10 (parallel protocol reached only
when declared) and D11 (refuse to start without the Pass 3 entry; close-out phase; fixtures in the repo).
**Changes:**
- [ ] `skills/phase-plan/execute.md`.
- [ ] Check assertions: phase-state vocabulary present; start-of-execution Pass 3 gate present.
**Depends on:** Phase 8.
**Write-set:** `skills/phase-plan/execute.md`, `scripts/check-phase-plan.sh`.
**Risks:** `execute.md` is 705 lines; this phase may need splitting into 9a/9b at Pass 3 sizing.
**Done when:** check passes.
**Validation:** moderate.

### Phase 10: Repo docs and audit

**Goal:** references outside the skill are current (Documentation Impact).
**Changes:**
- [ ] `commands/audit.md` Check 1 and Check 6.
- [ ] `skills/plan-doc-reasoning.md` line 108 wording.
- [ ] `agents.md` § File reference: new per-pass files and `CHANGELOG.md`.
**Depends on:** Phase 9.
**Write-set:** `commands/audit.md`, `skills/plan-doc-reasoning.md`, `agents.md`.
**Done when:** `/audit` reports no new flags; the structural check passes.
**Validation:** narrow.

### Phase 11: Close-out

**Goal:** the plan closes in the v2 shape it introduces.
**Changes:**
- [ ] Open the single PR; after merge, update the main checkout.
- [ ] **Observed check:** in a fresh session, invoke the skill and confirm it loads `pass2.md` as the
  independent review and `walk-through.md` for questions; record the session date.
- [ ] Outcome Summary, status line, Discoveries with "which pass should have caught this?".
- [ ] `REFINEMENTS.md` entry → Applied.
- [ ] Remove the `phase-plan-v2` worktree and branch after everything has landed.
**Write-set:** this plan, `REFINEMENTS.md`.
**Done when:** the skill is observed live in the new shape and the worktree is removed.
**Validation:** broad; live session observation.

## Open Questions

- [RESOLVED → D12] **OQ-1 What counts as the test for skill text?** Option A chosen 2026-11-09: structural
  check + `/audit` + dogfooding.
- [RESOLVED → D13] **OQ-2 Size budgets.** Option A chosen 2026-11-09: skill under 500 as a hard check;
  `CLAUDE.md` net zero; its existing overage is a separate follow-up.
- [RESOLVED → D14] **OQ-3 Evidence location.** Option A chosen 2026-11-09: local only, generic summaries in
  public text.

## Review Log

### Pass 1 (draft) — 2026-11-09
- Built from the 2026-11-09 usage review and the user's one-at-a-time walk-through of its recommendations
  (D1–D11, all user-confirmed; D12–D14 from OQ-1–OQ-3).
- Grounded against the repo: install path (VA-1), consumer references (VA-2, VA-3), budgets (VA-4), gates
  (VA-5), visibility (VA-8).
- Not yet run: the explicit gap-analysis checklist step (D3), Pass 2, Pass 3.

## Next pass

Read `plans/2026-11-09-1-plan-phase-plan-v2.md` in the worktree
`~/git/chasemp/coding-agents.worktrees/phase-plan-v2` (base `origin/main` `8e6fc33`). Run the **gap-analysis
step of Pass 1** using the current skill's `skills/phase-plan/pass2.md` checklist plus the D3 outward sweep from
this plan (the new pass files do not exist yet). Locked: D1–D14. No open questions.
Attack first: whether 11 sequential phases each stay at 3 files or fewer once the reverse search traces the real
write-set, and whether Phase 9 must split. Deliverable: a Review Log entry for the gap-analysis step and any plan
edits, replacing superseded text in place. Done when the entry is written and this section is rewritten for
Pass 2.
