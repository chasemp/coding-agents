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

**Goal:** Ensure the plan is ready for execution — TDD-first, observable,
debuggable, and coherent.

**Trigger:** User returns with the plan doc and asks for quality gate review,
or says "pass 3" / "final review".

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
- Are all open questions tagged with a recommended severity and rationale?
  Untagged open questions are not acceptable.
- Has the user confirmed the severity of every open question? If any
  question's severity was set by the agent but never reviewed by the user,
  flag it — the user must see and confirm before execution starts.

**5. Validation calibration**
- Does every phase declare a validation strategy?
- Is the validation calibrated to the scope? A phase that introduces a new
  external integration should not have "tests are sufficient" as its
  validation. A phase that renames an internal variable should not require
  manual end-to-end verification.
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

1. Read the plan doc end to end with fresh eyes.
2. **Spot-check the codebase.** You don't need to re-read everything Pass 2
   verified, but check the key touch points: do the files still exist? Has
   anything changed since Pass 2? Are the "Done when" criteria actually
   testable given the current test infrastructure?
3. Run each check above. For each violation, note it and propose a specific fix.
4. **Apply fixes additively.** Insert test-first steps into existing phases,
   add logging steps where missing, add checkpoint notes. Do not restructure
   phases or rewrite reasoning that already holds up. The plan's shape should
   be recognizable from Pass 2 — Pass 3 layers quality on top.
5. Add a Review Log entry for Pass 3.

## Review Log entry format

```markdown
### Pass 3: Quality Gates — [date]
**TDD ordering:**
- [adjustments made to ensure test-first in every phase]
**Observability:**
- [logging/monitoring additions]
**Debugging readiness:**
- [checkpoints, verification steps added]
**Validation calibration:**
- [validation strategies reviewed, adjustments to match scope]
**Discovery (if Phase 0 exists):**
- [discovery tasks reviewed for concreteness, completeness, and disposition]
**Coherence:**
- [any reasoning gaps filled, scope adjustments]
**Documentation impact:**
- [doc updates verified present in the right phase, or flagged as missing]
**Confirmed ready:** [yes/no — if no, what remains]
```

## Output

Final plan doc ready for execution. Before declaring readiness, surface ALL
remaining open questions — not just blocking ones. The user must have seen
and confirmed every open question's severity before execution starts.

**If any open questions remain (any severity):**

Use the **walk-through procedure from `pass1.md` § Output**, with one
adjustment: split the brief listing into confirmed-from-prior-passes
(read-only) and new-or-unreviewed (need the user's call). Walk through
only the unreviewed set.

> "Pass 3 complete. Open question status:"
>
> **Confirmed from prior passes (read-only):**
> 1. [CONFIRMED: BLOCKING] Question text. *Needs resolution before starting.*
>
> **New or unreviewed (need your call):**
> 2. [RECOMMENDED: PHASE-GATED (Phase 2)] Question text. *One-line rationale.*
> 3. [RECOMMENDED: ADVISORY] Question text. *One-line rationale.*
>
> "Let's walk through the unreviewed ones (#2, #3). Starting with #2 unless
> you'd rather accept all as recommended, or revisit a previously confirmed
> item."

Then walk through each RECOMMENDED item one at a time per the Pass 1
procedure. Close out with a readiness statement:

> "All open questions confirmed. [Tally.] The plan is ready for execution
> (pending any BLOCKING items — see below)."

Do NOT say "the plan is ready" while unreviewed questions exist. The agent
recommends, the user decides. A question the agent thinks is ADVISORY might
be blocking context the user needs to make a decision.

**If all open questions have been previously confirmed by the user:**

Apply the confirmed severities:
- **BLOCKING** items: the plan is not ready. List what's needed to resolve each.
- **PHASE-GATED** items: the plan is ready to start, but flag which phases
  are blocked and what must be resolved before reaching them.
- **ADVISORY** items: note them but don't gate execution.

**If there are no open questions:**

Tell the user: "Pass 3 complete. No open questions. The plan is ready for
execution."

## Reminders (critical, repeated for forefront)

- **Apply fixes additively.** Pass 3 layers quality on top of the Pass 2
  plan. Do not rewrite reasoning that holds up.
- **Every phase must have a wiring test.** If a phase only has unit
  tests for isolated components, that is a plan defect.
- **Do not execute during planning.** Pass 3 is analysis only.
  Implementation starts only after Pass 3 is complete and all BLOCKING
  questions are resolved.
