# Phase Plan — Pass 3: Quality Gates

> Loaded on demand by the `phase-plan` skill when the user invokes Pass 3.
> Assumes the main `phase-plan.md` skill is already loaded. Pass 3 is
> designed for a fresh context — clean eyes on the final plan.
>
> **Not a plan template.** This file is the `phase-plan` skill's
> instructions for Pass 3. The plan doc itself is a single file (see
> `phase-plan.md` § One plan, three passes) — Pass 3 layers quality
> gates on top of that same file. Do not create `plans/foo-pass3.md`
> or any other per-pass plan file.

**Goal:** Ensure the plan is ready for execution — TDD-first, observable, debuggable, coherent, and tested by
tests that can fail. Pass 3 runs last among the planning passes so it also gates the independent review's
fixes, which nothing else reviews.

**Trigger:** User returns with the plan doc and asks for quality gate review, or says "pass 3" / "quality
gates" / "final review". Its Review Log entry is what execution checks for before starting.

## Checks

**1. TDD ordering, specificity, and wiring tests**
- Does each phase start with writing or updating tests?
- Is every behavioral change covered by a test written *before* the
  implementation?
- Are test changes in the same phase as the code they test (not deferred
  to a later phase)?
- Would someone following this plan phase-by-phase naturally write tests
  first?
- **Specificity check:** Does each phase name the specific behaviors being
  tested? "Write tests for the parser" is too vague — "Test that malformed
  input raises ValidationError with field name" is actionable. Vague test
  descriptions lead to vague implementations which lead to stubs.
- **Wiring test check:** Does every phase have a wiring test that exercises
  the entry point? If a phase's only tests are unit tests for isolated
  components, flag it as a plan defect. The wiring test is what prevents
  the most common failure mode: building components that pass their own
  tests but are never called from the entry point.
- **Verification command check:** Does every phase's Verification command
  run through the entry point? If it only runs isolated module tests
  (e.g., `pytest tests/test_consolidation.py`), flag it — the verification
  must prove the call chain is live, not just that the component works
  alone.
- **Mutation resistance check:** For each phase whose tests assert on
  branching, threshold, or boundary behavior, does the test plan name
  the *edges* — not just a single happy-path point? "Asserts
  `discount_for(150) == 15`" is implementation-mirrored; "asserts no
  discount at amount ≤ 100 and 10% discount at amount > 100, with
  boundary cases at 99/100/101" is mutation-resistant. The Mental
  Mutation Pass (see `tdd-guardian.md` § Sacred Cycle and
  `testing-anti-patterns.md` § Anti-Pattern 6) runs at execution time;
  Pass 3 catches the planning-side version: assertions that, by
  construction, would survive a one-line mutation to production. Flag
  any phase whose test specifications read as single-point assertions
  on branching code, and ask the planner to name the boundary cases
  before the phase ships.

**1b. Tests that can fail**
- Each named test says what it shows if the feature is missing or wrong. A test that would pass against a stub
  proves nothing.
- Fakes refuse what the real service refuses (bad input, missing permission, rate limit), as probed or
  documented. A fake that accepts everything hides the failure path.
- Fixtures match real states that were probed, with timestamps relative to now rather than fixed dates that age
  into a different branch.
- The expected value comes from somewhere independent of the code being changed, not from running it.
- Where identity matters, compare sets, not counts.
- Tests target states the system can actually reach.
- Read-only validation commands named in the plan are dry-run now, during the pass.
- Logic-heavy phases (rules, parsers, encoders, state machines, search) end with a mutation-testing step
  before the phase is called done.

**2. Diagnostic logging and observability**
- For changes that affect runtime behavior: is appropriate logging planned?
- Can someone debugging a failure after deployment trace the issue using
  the logging this plan introduces?
- Are log levels appropriate (not everything is INFO)?
- If the project uses structured logging, does the plan follow that pattern?

**3. Debugging readiness**
- If something goes wrong mid-execution, can we identify which phase broke?
- Are there natural checkpoints where we can verify the system is healthy?
- If applicable, does the plan include state file or progress tracking?

**4. Coherence check**
- Can you explain the full plan from memory after reading it? If not,
  the reasoning section needs strengthening.
- Does the plan still solve the original problem stated at the top?
- Has scope crept beyond what was originally needed?
- Every open question has a proposed tag and rationale, and every question the user owns has been walked per
  `walk-through.md` with the answer written into the plan.
- **Hedges.** Every "consider", "grep to confirm", "may need" or "TBD" is run now or becomes an open question.
  A hedge left in a ready plan is a decision nobody made.
- Is superseded text gone? Where a later decision replaced an earlier one, the plan reads as current, with the
  history only in the Review Log.

**5. Validation calibration**
- Does every phase declare a validation strategy?
- Is the validation calibrated to the scope? A phase that introduces a new
  external integration should not have "tests are sufficient" as its
  validation. A phase that renames an internal variable should not require
  manual end-to-end verification.
- A phase that writes to an external system uses the external-write tier: a dry run showing exactly what would
  be written, then a small supervised live run with every write read back, then the schedule or full run. Reruns
  are safe; rollback covers data already written; bulk writes state batch size, rate, and the automation they
  trigger.
- Scheduled jobs, deploys and live-data changes are done only when observed (built → merged → deployed →
  observed, with a run id), not when merged.
- If Phase 0 exists: are the discovery tasks concrete and answerable? Does
  each task have a clear question and a clear way to answer it? Are the
  outputs wired to the Verified Assumptions and Open Questions sections?
- **Disposition check:** Does every Phase 0 task declare a disposition
  (`throwaway`, `keep-as-fixture`, or `promote`)? If a task is marked
  `promote`, is there a named follow-up phase that applies TDD to the
  promoted code? An undeclared disposition is a plan defect — it is the
  exact ambiguity the Discovery Exemption exists to prevent.
- Could any Phase 0 discovery task be resolved right now during planning
  instead of deferred to execution? If so, resolve it now.

**5b. Concurrency honesty**
- The Concurrency Map line exists with its reason, even when it is "All phases sequential". A missing line is a
  plan defect.
- For a declared parallel set only: write-sets *actually* disjoint (open the per-phase entries; Pass 3's own
  adjustments may have moved files); the Shared-state contract written as invariants ("does not invoke `git
  checkout` in the parent worktree") rather than mechanisms ("runs in a worktree"); and Re-entry verification
  mapping one to one to the contract with concrete checks (HEAD SHA, `git worktree list`, ports).
- Could parallelism be added that the plan misses? Flag candidates to the user; don't restructure.

**6. Project conventions**
- Does the plan align with existing patterns in the codebase?
- Are naming conventions, file organization, and code style consistent
  with the project?

**7. Documentation impact coverage**
- Does the plan have a `Documentation Impact` section (see main
  `phase-plan.md` § The Plan Doc)? If the plan adds, renames, moves,
  or removes any file, that section cannot be empty — even a "grepped
  — no references found" record is acceptable, silence is not.
- Every file listed in Documentation Impact has a corresponding phase
  item that updates it.
- Every phase that adds/renames/removes a file has a same-phase doc
  update. A "docs phase" at the end is an anti-pattern; flag it and
  redistribute the doc updates into the phases that trigger them.
- For renames: has the plan acknowledged potential stale references
  (see `/audit` Check 2)? The grep should be proactive, not a post-hoc
  audit run.

## Steps

1. Use a fresh context; a compacted one is not fresh, so say so and hand off. The Review Log needs a gap-analysis
   entry (else run `pass1.md` § Gap-analysis step first) and, unless this is a quick plan, a Pass 2 entry.
2. Read the plan doc end to end and start from the previous pass's additions: the independent review's fixes are
   the least reviewed text in the plan.
3. **Deliverable anchor.** Write one line: what the plan delivers and how its done-when is observed. Judge every
   check against it, and flag work that does not serve it.
4. **Spot-check the codebase, bounded.** The key touch points and whatever changed since the previous pass
   (`git log` since its commit): do the files still exist, do cited lines still say what the plan says, are the
   "Done when" criteria testable with the current test infrastructure? Do not redo the independent review.
5. Run each check above. For each violation, note it and propose a specific fix.
6. **Apply fixes.** Insert test-first steps, logging steps and checkpoints into existing phases; keep the plan's
   structure. Where a fix supersedes planning text, replace that text in place so the plan reads as current; the
   history goes in the Review Log. Restructuring phases needs the user's approval.
7. Add a Review Log entry for Pass 3.

## Review Log entry format

```markdown
### Pass 3: Quality Gates — [date]
Deliverable: [one line]. Spot-check: [what was checked, base SHA].
**TDD ordering:**
- [adjustments made to ensure test-first in every phase]
**Tests that can fail:**
- [tests, fakes and fixtures sharpened; validation commands dry-run]
**Observability:**
- [logging/monitoring additions]
**Debugging readiness:**
- [checkpoints, verification steps added]
**Validation calibration:**
- [validation strategies reviewed, adjustments to match scope]
**Concurrency honesty:**
- [Map line confirmed; for a parallel set, disjointness, invariants and
  re-entry checks. Write "Map confirmed; sequential plan." if no changes.]
**Discovery (if Phase 0 exists):**
- [discovery tasks reviewed for concreteness, completeness, and disposition]
**Coherence:**
- [reasoning gaps filled, hedges resolved, superseded text replaced]
**Documentation impact:**
- [doc updates verified present in the right phase, or flagged as missing]
**Confirmed ready:** [yes/no — if no, what remains]
```

## Output

The final plan, ready for execution. Before declaring readiness, walk every decision the user owns per
`walk-through.md`: one item per message, decision first, each answer written into the plan before the next.
Decisions already made in earlier passes are listed, not re-walked, unless something in this pass changed
them. Answers that add work get the gap-analysis step and Pass 3 on the changed part.

Do not say the plan is ready until
every walk-through answer is written into the plan and re-checked.
The agent recommends, the user decides.

Then apply the tags:
- **BLOCKING** items: the plan is not ready. List what's needed to resolve each.
- **PHASE-GATED** items: the plan is ready to start, but flag which phases
  are blocked and what must be resolved before reaching them.
- **ADVISORY** items: note them but don't gate execution.

Write the plan's Next pass section per `pass1.md` § Next pass handoff (pointing at execution), and close:

> "Pass 3 complete. [Decisions, decided-by-agent items for override, any BLOCKING or PHASE-GATED items.]
> The plan is ready for execution; the paste is in the plan's Next pass section.
>
> **Plan file:** `plans/YYYY-MM-DD-N-plan-<slug>.md`"

Always include the plan file path in the close-out — the user should never
have to scroll back through session history to find where the plan lives.

**If there are no open questions:**

> "Pass 3 complete. No open questions. The plan is ready for execution.
>
> **Plan file:** `plans/YYYY-MM-DD-N-plan-<slug>.md`"

## Reminders (critical, repeated for forefront)

- **Extend the structure; replace superseded text.** Pass 3 keeps the plan's phases and replaces only planning
  text a later decision made wrong, logging each change.
- **Every phase must have a wiring test.** If a phase only has unit
  tests for isolated components, that is a plan defect.
- **Do not execute during planning.** Pass 3 is analysis only.
  Implementation starts only after Pass 3 is complete and all BLOCKING
  questions are resolved.
