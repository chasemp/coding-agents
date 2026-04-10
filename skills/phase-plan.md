---
name: phase-plan
description: >
  Three-pass planning workflow for complex changes. Pass 1 develops the plan
  with full reasoning persisted to the plan doc — including Phase 0 discovery
  when unknowns exist. Pass 2 reviews for gaps, missing changes, and downstream
  effects. Pass 3 applies quality gates (TDD ordering, diagnostic logging,
  debugging readiness, validation calibration). Each pass uses a fresh context
  with the plan doc as the sole handoff artifact. Trigger when the user says
  "phase plan", "three-pass plan", "plan review", or when starting non-trivial
  changes that benefit from structured reasoning before execution.
---

# Phase Plan

<!-- TRACKING: Wiring gap issue (2026-04-07)
     Recurring problem: phases build isolated components with passing unit tests
     but fail to wire them into the entry point. All tests green, feature doesn't
     work. Added: Wiring test field, entry-point verification requirements,
     Isolation Trap anti-pattern section. Monitor whether these changes actually
     prevent the failure mode in practice. If it recurs, the next step is a
     programmatic hook that checks for entry-point test coverage at phase boundary. -->

<!-- TRACKING: Discovery + Validation additions (2026-04-10)
     Two additions: (1) Phase 0 Discovery for validating assumptions before
     committing to implementation — triggered when unknowns exist. (2) Per-phase
     Validation field calibrated to scope — tests are the floor, not the ceiling.
     Also added: Combined Pass 1+2 usage pattern, Phase 0 execution rules,
     validation calibration as Pass 3 quality gate. Monitor whether Phase 0
     catches assumption errors that would have caused mid-execution rework,
     and whether validation strategies are actually calibrated vs defaulting
     to "tests are sufficient" for everything. -->

Three-pass planning for complex changes. Each pass uses a fresh context window.
The plan doc is the single artifact that travels between passes — it must carry
all reasoning, not just the steps.

**Why three passes instead of one:** Complex changes have emergent properties.
Missing dependencies, ordering issues, and downstream effects are hard to see
while you're still building the plan. Fresh eyes on a complete plan catch what
the planning mind missed.

**Passes are additive, not destructive.** Pass 1 builds the base. Passes 2 and
3 *extend* it — adding missing items, inserting steps into existing phases,
strengthening reasoning. They do not reorganize, rewrite, or shuffle what Pass 1
produced unless something is concretely wrong. The goal is to build on a stable
foundation, not re-deal the cards each pass. If a phase needs a new step, add
it. If reasoning has a gap, fill the gap — don't rewrite the surrounding
paragraphs. Wholesale restructuring requires explicit user approval.

---

## Relationship to Other Tools

This skill is the planning layer. Other agents and skills activate at specific
points in the workflow:

- **adr agent:** If Pass 1 identifies an architecture decision, invoke adr to
  record it. The plan references the ADR, not the other way around.
- **tdd-guardian:** Runs during execution to enforce RED-GREEN-REFACTOR on each
  phase. Pass 3 sets up TDD ordering in the plan; tdd-guardian verifies
  compliance as code is written.
- **progress-guardian:** If the project uses WIP/PLAN tracking, the plan doc
  produced here is the input. progress-guardian tracks execution progress
  against it.
- **refactor-scan:** Runs after each phase reaches green during execution to
  assess improvement opportunities.
- **effective-design-overview skill:** If the problem space in Pass 1 involves
  system design or architecture selection, load this skill to inform the
  Reasoning section before committing to an approach.

---

## The Plan Doc

The plan doc is a markdown file the user creates or points to. It lives in the
project (often at the repo root or in a `plans/` directory). Everything goes in
this file — it is the handoff artifact between context windows.

### Required sections

```markdown
# [Title]

## Problem Statement
What we're solving and why. Include issue references, symptoms, constraints.

## Reasoning
Why this approach? What alternatives were considered and rejected?
What assumptions are we making? This section is the "re-reasoning" record —
future readers (including future-us) should be able to reconstruct the
decision process from this section alone.

## Verified Assumptions
What we confirmed about libraries, APIs, CLI tools, and existing code —
and how we confirmed it (docs link, source file:line, probe output).
Anything not listed here is unverified.

## Phases
Ordered phases of work. Each phase should leave the system in a working state.

### Phase 0: Discovery (optional)
Include this phase when the plan has significant unknowns — unverified API
behavior, unfamiliar codebase areas, novel technology, BLOCKING open questions,
or assumptions that could invalidate multiple later phases if wrong. Phase 0
is cheap insurance: a few hours of probes can save days of rework.

**When to include Phase 0:**
- Any BLOCKING open question that can be resolved by running code, reading
  docs, or making a probe request
- Dependencies on libraries/APIs/tools whose behavior you haven't verified
  firsthand
- Unfamiliar areas of the codebase where you're planning based on inference
  rather than reading
- Novel integrations where the happy path isn't certain

**When to skip Phase 0:**
- All assumptions are verified in the Verified Assumptions section
- The codebase and tools are well-known to the team
- The change is a straightforward application of an established pattern

**Goal:** Resolve unknowns. Validate assumptions. Eliminate dead ends before
committing to a multi-phase implementation.
**Discovery tasks:**
- [ ] Each task is a specific probe: "Run `tool --flag` and confirm output
  contains X", "Read `src/engine.py:45-80` and confirm Config accepts Y",
  "POST to `/api/v2/foo` with payload Z and record the response shape"
**Outputs fed back into the plan:**
- Verified Assumptions updated with findings and evidence
- Open Questions resolved (or escalated with what was learned)
- Phases adjusted if discovery invalidates an assumption — document what
  changed and why in the Review Log
**Done when:** All BLOCKING open questions are resolved and the Verified
Assumptions section reflects firsthand evidence, not inference.

**Key property of Phase 0:** It is the only phase that is allowed to change
the structure of later phases. If a probe reveals that an assumption was wrong,
update the plan before proceeding — do not defer the adjustment to execution.

### Phase N: [Name]
**Goal:** What this phase achieves.
**Changes:**
- [ ] File or component change with brief rationale
**Call chain:** Entry point → intermediate → new/changed code. Trace the
path from the user-facing entry point to the code this phase introduces.
If the phase adds a function, name what calls it. If it adds a model,
name what constructs and uses it. This field is what prevents dead code —
if you can't write the chain, the wiring isn't planned.
**Wiring test:** The specific integration test that proves the call chain
is live — not that the component works in isolation, but that the entry
point can reach it. This test is RED at phase start and GREEN at phase
end. Example: `test_audit_output_contains_escalation_notes` exercises
`cli audit --tutoring` end-to-end and asserts the new behavior appears.
If a phase only has unit tests for its components, the wiring is not
tested and will be skipped. **This is the single most important field
for preventing dead code.**
**Depends on:** Prior phases or external factors.
**Risks:** What could go wrong, what to watch for.
**Done when:** Two tiers, both required:
1. **Behavioral:** What the user or system can observably do after this
   phase that it couldn't before. Phrased as an end-to-end statement:
   "Running `cli audit --tutoring` produces output containing escalation
   notes populated from judge candidates." This is the gate.
2. **Verification:** The test command that proves the behavioral criterion.
   **This command must exercise the entry point, not just the isolated
   module.** If the verification is `pytest tests/test_consolidation.py`,
   that's a plan defect — it proves the component works in isolation but
   not that anything calls it. The verification must be something like
   `pytest tests/test_cli.py -k escalation -v` that runs through the
   actual call chain. If the verification passes but the behavioral
   criterion doesn't hold, the phase is not done.
**Validation:** What validation is appropriate for this phase, calibrated
to the scope of the change. Tests alone are necessary but not always
sufficient. Declare the validation strategy upfront so the executor and
reviewer agree on what "verified" means. Examples by scope:
- **Narrow** (single function, internal refactor): Wiring test + unit
  tests. Tests are sufficient.
- **Moderate** (new feature, changed behavior): Wiring test + unit tests
  + run the system and exercise the feature manually. Confirm the
  behavioral criterion holds outside of the test harness.
- **Broad** (integration, external API, multi-component): All of the above
  + verify integration with external systems. Check logs, confirm data
  flow, verify error paths. If the change touches a deployment or config,
  verify it in an environment that resembles production.
The validation strategy should match the risk. A phase that changes a
format string needs less validation than a phase that rewires the
authentication flow.

## Open Questions
Unresolved items that need input. Each must include the agent's recommended
severity and a brief rationale, but the user makes the final call:
- **BLOCKING** (recommended) — must be resolved before execution starts
- **PHASE-GATED** (recommended) — must be resolved before a specific phase (name it)
- **ADVISORY** (recommended) — nice to know, can be resolved during execution
Format: `- [RECOMMENDED: severity] Question text. *Rationale for recommendation.*`
The user confirms or overrides the severity before the plan advances.

## Review Log
Record of each review pass — what was found, what was changed.
```

The user may already have a plan doc in a different format. Adapt to their
format rather than forcing this structure — the key requirement is that
reasoning and review history are persisted, not the exact heading names.

---

## Pass 1: Reasoning and Plan Development

**Goal:** Produce a complete plan with full reasoning persisted.

**Trigger:** User presents an issue, feature request, or problem to plan.

### Steps

1. **Understand the problem space.** Read the issue, relevant code, and any
   existing context. Ask clarifying questions — do not assume.
2. **Ground the plan in the codebase.** Before drafting any phases, explore
   the code that will be affected. Name specific files, functions, and modules.
   Identify existing patterns (how does the project already do logging? testing?
   error handling?). Note the test infrastructure — what framework, what
   conventions, where do tests live. A plan that references "the middleware"
   without knowing which file it's in will produce vague implementations.
   Record what you found in the Reasoning and Verified Assumptions sections.
3. **Validate external assumptions.** If the plan depends on a library, API,
   CLI tool, or any code you didn't write — verify how it actually works
   before building a plan around it. Read the docs, check the source, run a
   probe if needed. Do not plan around assumed behavior. Common traps:
   - Library method signatures, return types, or side effects you haven't
     confirmed by reading the source or docs
   - API endpoints, payload shapes, or error codes inferred from naming
     conventions rather than verified against a spec or actual response
   - CLI tool flags or output formats assumed from memory rather than
     checked against `--help` or a test run
   - Existing project code you haven't read — "I think that function
     does X" is not validation

   Record what you verified and how in the Verified Assumptions section. If you cannot
   verify something during planning (e.g., need credentials for an API),
   capture it as an Open Question with a concrete validation step to run
   before execution begins.
4. **Explore the solution space.** Consider approaches. Document alternatives
   considered and why they were rejected in the Reasoning section.
5. **Assess whether Phase 0 (Discovery) is needed.** Review the Open
   Questions, Verified Assumptions, and your own confidence level. If any
   of the following are true, include Phase 0:
   - There are BLOCKING open questions that can be resolved by probing
     (running code, reading docs, hitting an API)
   - The plan depends on library/API/tool behavior you haven't confirmed
     firsthand — "I think it works like X" is a discovery task, not an
     assumption
   - You're planning changes in a codebase area you haven't read — the
     plan is based on inference rather than evidence
   - Multiple later phases depend on the same assumption — if that
     assumption is wrong, the rework is multiplicative

   Phase 0 is cheap. Skipping it when unknowns exist is expensive. When
   in doubt, include it — a discovery phase that confirms your assumptions
   costs a few probes. A plan built on wrong assumptions costs a rewrite.
6. **Draft phases.** Break the work into ordered phases. Each phase should:
   - Have a clear goal
   - List specific file/component changes (name the files)
   - Leave the system in a working state when complete
   - Note dependencies and risks
   - Name the specific behaviors being tested, not just "write tests"
   - Include two-tier "Done when" criteria: a behavioral statement of what
     the user/system can now do ("running `cli audit --tutoring` produces
     escalation notes from judge candidates") and a verification command
     that proves it (`pytest tests/test_cli.py -k escalation`). "Code
     exists" is not acceptance. A test command alone is not acceptance
     either — tests can pass while the feature is unwired.
   - Declare a **Validation strategy** calibrated to the scope of the
     phase. Tests are the floor, not the ceiling. For phases with broad
     scope or external integration, validation should include running the
     system and confirming behavior outside the test harness.
   - If the plan involves an architecture decision, note it — the adr agent
     should be invoked to record it
7. **Size phases for a single context window.** If you can't describe the
   test-first implementation of every item in a phase and hold it in your
   head, the phase is too big. Split it. This is the primary defense against
   stubbing — phases that fit in one context window get completed fully.
   **Hard rule: if a phase touches 4 or more files, it must be split.**
   Do not proceed with planning until oversized phases are broken down.
   This is not a suggestion — 4+ files in a single phase is a known cause
   of partial completion and should be treated as a plan defect.
8. **Persist everything.** Write the full plan doc. The Reasoning section must
   be detailed enough that someone in a fresh context can understand *why*
   every decision was made — not just *what* will be done.
9. **Surface open questions.** If anything is unresolved, capture it in Open
   Questions rather than guessing. For each question, recommend a severity
   (**BLOCKING**, **PHASE-GATED**, **ADVISORY**) with a brief rationale for
   why you chose that level — but the user makes the final call. Do not
   silently classify questions as ADVISORY and move on. Every open question
   is context the user needs to see.

### What to ask the user

- What constraints exist (timeline, backwards compat, affected teams)?
- Are there related changes in flight?
- What's the blast radius if something goes wrong?
- Which parts of the codebase are they most/least familiar with?

### Output

A complete plan doc. If there are any open questions — regardless of
recommended severity — list them all and ask the user to confirm or override
each severity classification before proceeding. Do not say "no blocking items"
and move on while questions remain unreviewed. The user may decide an ADVISORY
question is actually BLOCKING. Format:

> "Pass 1 complete. Before clearing context for Pass 2, please review these
> open questions and confirm whether you agree with the recommended severity:"
>
> 1. [RECOMMENDED: ADVISORY] Question text. *Rationale.*
> 2. [RECOMMENDED: PHASE-GATED (Phase 3)] Question text. *Rationale.*
>
> "Override any that should be BLOCKING. Once confirmed, clear context and
> come back for Pass 2 (gap analysis)."

If there are no open questions, say: "Pass 1 complete. No open questions.
Clear context and come back for Pass 2 (gap analysis) when ready."

---

## Pass 2: Gap Analysis

**Goal:** Review the plan for missing changes, downstream effects, and
incomplete reasoning.

**Trigger:** User returns with the plan doc and asks for gap analysis,
or says "pass 2" / "review the plan".

### Steps

1. **Read the plan doc end to end.** Internalize the reasoning, not just
   the steps.
2. **Verify claims against the codebase.** The plan names specific files,
   functions, and call sites. Read them. Confirm they exist, confirm they
   work the way the plan assumes. If the plan says "modify engine.py to
   call build_prescan_briefing," open engine.py and find the call site.
   If the plan says "the Config class accepts a prescan flag," check. Gap
   analysis against a plan alone catches logical gaps; gap analysis against
   the code catches factual ones.
3. **For each phase, ask:**
   - **Preconditions:** What must exist before this phase starts? Does a
     prior phase actually create it? If Phase 3 assumes something Phase 2
     introduces, verify Phase 2 explicitly lists it.
   - What files or components are touched? What *else* touches those same
     files or depends on them?
   - If this change ships alone (phases after it fail), is the system still
     coherent?
   - Are there associated changes that are implied but not listed?
     (e.g., updating types after changing a schema, updating tests after
     changing an interface, updating docs after changing behavior)
   - Are there ordering dependencies between changes within the phase?
4. **Check cross-phase dependencies.**
   - Does Phase N depend on something Phase M introduces? Is M before N?
   - Are there circular dependencies that need restructuring?
   - Could any phase be parallelized or reordered for safer delivery?
   - **Verify every "Depends on" field** — after the gap analysis, are the
     stated dependencies still accurate? Add any that were discovered, remove
     any that no longer apply.
5. **Check the reasoning.**
   - Do the stated reasons still hold given the full plan?
   - Are any assumptions contradicted by later phases?
   - Are rejected alternatives actually better given what the full plan
     reveals?
   - **Re-validate external assumptions.** The gap analysis may have added
     new dependencies or changed how existing ones are used. For anything
     the plan depends on (libraries, APIs, CLI tools, existing code): is
     the assumed behavior verified in the Verified Assumptions section? If
     a gap-fill introduced a new library call or API interaction, verify it
     now — don't defer to execution.
6. **Extend, don't rewrite.** Insert missing steps into existing phases,
   add new phases if needed, fill gaps in reasoning. Preserve the existing
   structure and language — do not reorganize or rephrase what already works.
   If something is concretely wrong (not just "I'd phrase it differently"),
   fix the specific issue and note it in the Review Log. Reordering phases
   requires a concrete dependency justification, not a preference for a
   different flow.

### Review Log entry format

```markdown
### Pass 2: Gap Analysis — [date]
**Found:**
- [description of gap or missing change]
**Changed:**
- [what was added, reordered, or revised in the plan]
**Confirmed:**
- [aspects of the plan that held up under review]
```

### Output

Updated plan doc with gaps filled. If any open questions remain (including
new ones surfaced by the gap analysis), list them all with recommended
severities and ask the user to confirm. Same format as Pass 1 output.

If there are no open questions, say: "Pass 2 complete. No open questions.
Clear context and come back for Pass 3 (quality gates) when ready."

---

## Pass 3: Quality Gates

**Goal:** Ensure the plan is ready for execution — TDD-first, observable,
debuggable, and coherent.

**Trigger:** User returns with the plan doc and asks for quality gate review,
or says "pass 3" / "final review".

### Checks

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
- Could any Phase 0 discovery task be resolved right now during planning
  instead of deferred to execution? If so, resolve it now.

**6. Project conventions**
- Does the plan align with existing patterns in the codebase?
- Are naming conventions, file organization, and code style consistent
  with the project?

### Steps

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

### Review Log entry format

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
- [discovery tasks reviewed for concreteness and completeness]
**Coherence:**
- [any reasoning gaps filled, scope adjustments]
**Confirmed ready:** [yes/no — if no, what remains]
```

### Output

Final plan doc ready for execution. Before declaring readiness, surface ALL
remaining open questions — not just blocking ones. The user must have seen
and confirmed every open question's severity before execution starts.

**If any open questions remain (any severity):**

> "Pass 3 complete. The following open questions remain. Please confirm
> their severity before we start execution:"
>
> 1. [CONFIRMED: BLOCKING] Question text. *Needs resolution before starting.*
> 2. [RECOMMENDED: PHASE-GATED (Phase 2)] Question text. *Rationale.*
> 3. [RECOMMENDED: ADVISORY] Question text. *Rationale.*
>
> "Any of these you'd like to upgrade to BLOCKING before we proceed?"

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

---

## Usage Patterns

### Full three-pass (recommended for complex changes)

```
User: "Let's plan [feature/fix]. Here's the issue: ..."
→ Pass 1 produces plan doc (may include Phase 0)
User: [clears context] "Here's our plan doc. Run pass 2."
→ Pass 2 fills gaps
User: [clears context] "Here's our plan doc. Run pass 3."
→ Pass 3 applies quality gates
User: [clears context] "Here's our plan doc. Let's execute."
→ Execute Phase 0 first (if present), update plan, then phases 1-N
```

### Combined Pass 1+2, then Pass 3 (recommended for moderate changes)

Run Pass 1 and Pass 2 in the same context window, then clear context before
Pass 3. This works well when the plan is moderate in scope and the gap
analysis benefits from still having the original exploration context fresh.
The user can say "pass 1+2" or "plan and review together". Pass 3 still
gets a fresh context — the quality gate review benefits from clean eyes.

```
User: "Let's plan [feature/fix]. Here's the issue: ..."
→ Pass 1 produces plan doc, then Pass 2 reviews in same context
User: [clears context] "Here's our plan doc. Run pass 3."
→ Pass 3 applies quality gates with fresh eyes
User: [clears context] "Here's our plan doc. Let's execute."
→ Execution follows the plan phase by phase
```

### Abbreviated (for simple changes)

Combine all three passes into a single context if the change is small and
well-understood. The user can say "plan and finalize" or "quick plan".

### With Phase 0 Discovery

When the plan includes Phase 0, execution has a natural checkpoint:

```
User: [clears context] "Here's our plan doc. Let's execute."
→ Execute Phase 0 discovery tasks
→ Report findings, update plan doc
→ User reviews updated plan: "Looks good, continue." or "Hold on, let's adjust."
→ Execute phases 1-N
```

Phase 0 completion is a decision point. If discovery changes the plan
materially, the user should review before committing to implementation.

### Resuming after execution starts

If execution reveals something the plan missed, return to the plan doc. Add
a Review Log entry documenting what was found, update the remaining phases,
and continue. The plan doc is a living document during execution.

---

## Execution Rules

When the user says "let's execute" after planning is complete, these rules
govern how you work through the plan.

Print the full execution reminder at the start of execution. At the start of
each subsequent phase, print the short mantra only:

> **TDD first. Full phases. No stubs. No dead code. Commit when green.**

### The execution reminder (print in full at execution start)

> **TDD first. Full phases. No stubs. No dead code. Commit at stable points.**
>
> - Write tests before implementation — every phase, every change.
> - Execute each phase of the plan completely and in order. Do not skip
>   ahead, do not leave a phase partially done.
> - **No stubbing, no placeholders, no "we'll come back to this."** Every
>   piece of work in a phase is finished before moving to the next phase.
>   If a function is in the plan, it gets a real implementation — not a
>   stub that returns a hardcoded value or raises NotImplementedError.
> - **Everything built must be wired.** A function that exists but is never
>   called from where the plan says it should be called is dead code, not
>   progress. After implementing an item, trace the call path from the
>   entry point to verify it's reachable — not just that it passes its
>   own test in isolation.
> - Run tests after completing each phase to confirm regression safety
>   before proceeding.
> - **Commit after each phase.** When the phase checklist passes, commit.
>   This creates a rollback point and makes "done" concrete. If it's not
>   committed, it's not done.

### Executing Phase 0 (Discovery)

If the plan includes Phase 0, execute it before any implementation phase.
Phase 0 is different from other phases:

- **No TDD cycle.** Phase 0 produces knowledge, not code. Probes, spikes, and
  experiments are throwaway — they don't need tests.
- **Update the plan doc as you go.** Move findings into Verified Assumptions.
  Resolve Open Questions. If a discovery invalidates an assumption that later
  phases depend on, update those phases now — flag the changes in the Review Log.
- **Report findings before proceeding.** At the end of Phase 0, summarize what
  was confirmed, what changed, and whether any phases need restructuring. Get
  user approval before starting Phase 1 if the plan changed materially.
- **Phase 0 is not open-ended.** Each discovery task has a concrete question
  and a concrete way to answer it. If a task's answer leads to more questions,
  scope those as new discovery tasks — don't let Phase 0 expand indefinitely.

### Phase completion checklist

Before moving from Phase N to Phase N+1, confirm:

- [ ] **Re-read the phase spec.** Open the plan doc and re-read Phase N's
      goal, changes list, call chain, wiring test, and done-when criteria.
      Diff what was specified against what was implemented. This is the
      single most effective check against partial completion — items missed
      during implementation become obvious when you re-read the spec after
      the work is done.
- [ ] All changes listed in Phase N are implemented (not stubbed)
- [ ] **Wiring test is GREEN.** Run the phase's wiring test and confirm it
      passes. This test exercises the entry point, not just the isolated
      module. If the phase has no wiring test, that's a plan defect — stop
      and add one before claiming the phase is done. **This is the gate.**
      Unit tests passing is necessary but not sufficient.
- [ ] The call chain specified in the phase is wired end-to-end — trace
      from the entry point to the new code and confirm reachability
- [ ] The behavioral done-when criterion holds (not just the test command)
- [ ] **Validation strategy executed.** Run the validation declared in the
      phase spec. If the phase says "run the system and exercise the feature
      manually," do that — don't substitute with "tests pass." If the phase
      says "tests are sufficient," tests are sufficient. The validation
      strategy was calibrated during planning for a reason. Report what you
      validated and what you observed.
- [ ] Tests for Phase N's changes were written first and are passing
- [ ] Existing tests still pass (regression check)
- [ ] The system is in a working state
- [ ] Phase N changes are committed

Report this checklist to the user at each phase boundary. Do not silently
move on.

**The wiring test is the checklist item most likely to expose incomplete
phases.** Unit tests for isolated components will pass even when nothing
calls the component from the entry point. The wiring test is the only
thing that catches this. If you find yourself wanting to skip it because
"the unit tests already cover the logic" — that is exactly the situation
where dead code accumulates.

### Mid-phase check

If implementation of a single item in a phase takes more than a few
test/implement iterations without converging, stop. Do not keep pushing.
Report to the user:

- What item you're stuck on
- What you've tried
- Whether the plan's assumptions about this item were wrong

This catches problems before they compound. The instinct to "just get it
working" mid-phase is where stubs and hacks creep in.

### Why this matters

There are two forms of phantom progress, and both break the contract:

1. **Stubs and placeholders** — code that exists but doesn't do anything real.
   The plan looks done but the system doesn't work.
2. **Dead code** — real implementations that are never wired into the system.
   A function defined but never called, an event type created but never
   emitted, a config file specified but never seeded. These pass their own
   tests in isolation but the feature doesn't work end-to-end.

Both create the same outcome: a "complete" implementation with gaps that
surface later. Committing after each verified phase creates concrete
checkpoints — you can't claim a phase is done without the commit to prove it,
and the wiring check catches dead code before it compounds across phases.

---

<!-- TRACKING: This section added 2026-04-07 to address recurring wiring gap.
     If phases still complete without wiring after these changes, escalate to
     a programmatic hook (e.g., hooks/phase-wiring-check.sh). -->
## Known Anti-Pattern: The Isolation Trap

The most common phase-plan execution failure is what looks like a complete
implementation but isn't wired to anything. The pattern:

1. Phase builds a component (model, agent, function)
2. Phase writes unit tests for the component
3. Unit tests pass
4. Phase feels "done" — commit, move on
5. The entry point (cli.py, main.py, the router) still runs the old code
6. All tests green. Feature doesn't work. Nobody notices until end-of-plan review.

**Why this happens:** Unit tests passing creates false confidence. The phase
completion checklist says "trace the call chain" but that's a mental exercise
easily skipped when tests are green. The Verification command runs isolated
module tests, which pass regardless of whether anything calls the module.

**How to prevent it:** Each phase needs a **wiring test** — an integration
test that starts at the entry point and asserts the new behavior is reachable.
This test is RED at phase start (proving the feature doesn't exist yet) and
GREEN at phase end (proving the wiring is live). The Verification command
must run this wiring test, not just the unit tests.

**How to detect it during execution:** If you finish a phase and the only
tests you ran are in `tests/test_<component>.py`, ask: "What test proves
that the entry point can reach this code?" If the answer is "none yet" or
"that's in a later phase," the phase is not done.

---

## Guardrails

- **Never skip reasoning.** A plan without reasoning is a todo list. The
  reasoning is what makes the plan re-entrant across context windows.
- **Build on the base, don't rebuild it.** Passes 2 and 3 extend Pass 1.
  If you find yourself rewriting more than you're adding, stop and ask
  whether the base plan is fundamentally wrong — if it is, say so explicitly
  and get user approval before restructuring. Otherwise, insert and augment.
- **Never add to the plan without adding to the Review Log.** Every change
  after Pass 1 must be traceable.
- **Do not execute during planning passes.** Passes 1-3 are analysis only.
  Code changes happen after Pass 3.
- **Respect the user's format.** If they have an existing plan doc style,
  adapt. The principles matter, not the headings.
- **Fresh context between passes is a feature.** It forces the plan to be
  self-contained. If a pass requires conversation context to make sense,
  the plan doc is incomplete.
- **No stubs, ever.** During execution, every item in a phase gets a real
  implementation. If you catch yourself writing a placeholder, stop — either
  implement it fully or flag that the phase needs to be broken down further.
- **Built means wired, and wired means tested.** Code that exists but isn't
  reachable from the entry point is dead code, not progress. After building
  something, trace the call path. If nothing calls it yet, that's part of
  the same item — not a separate task for later. The wiring test is what
  makes this enforceable: if the wiring test is still RED, the wiring isn't
  done regardless of how many unit tests pass.
- **Commit at every stable point.** After each phase passes its checklist,
  commit. No batching phases into a single commit. Each commit is a verified,
  working checkpoint that can be rolled back to independently.
- **No assumed behavior.** Do not plan around how you think a library, API,
  or existing code works. Read the docs, read the source, run a probe.
  "I believe this method returns X" is not validation. This applies during
  planning (Passes 1-3) and during execution — if you discover mid-phase
  that something doesn't work as the plan assumed, stop and update the plan
  before continuing.
