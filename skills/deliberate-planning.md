---
name: deliberate-planning
description: >
  Three-pass planning workflow for complex changes. Pass 1 develops the plan
  with full reasoning persisted to the plan doc. Pass 2 reviews for gaps,
  missing changes, and downstream effects. Pass 3 applies quality gates
  (TDD ordering, diagnostic logging, debugging readiness). Each pass uses
  a fresh context with the plan doc as the sole handoff artifact. Trigger
  when the user says "deliberate plan", "three-pass plan", "plan review",
  or when starting non-trivial changes that benefit from structured reasoning
  before execution.
---

# Deliberate Planning

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

### Phase N: [Name]
**Goal:** What this phase achieves.
**Changes:**
- [ ] File or component change with brief rationale
**Depends on:** Prior phases or external factors.
**Risks:** What could go wrong, what to watch for.
**Done when:** Observable acceptance criteria — not "code exists" but
"running X produces Y" or "test Z passes with this assertion." Each
criterion should be verifiable by running a command or reading output.

## Open Questions
Unresolved items that need input. Each must be tagged:
- **BLOCKING** — must be resolved before execution starts
- **PHASE-GATED** — must be resolved before a specific phase (name it)
- **ADVISORY** — nice to know, can be resolved during execution

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
5. **Draft phases.** Break the work into ordered phases. Each phase should:
   - Have a clear goal
   - List specific file/component changes (name the files)
   - Leave the system in a working state when complete
   - Note dependencies and risks
   - Name the specific behaviors being tested, not just "write tests"
   - Include observable "Done when" acceptance criteria — what command to
     run, what output to expect. "Code exists" is not acceptance. "Running
     `pytest tests/test_prescan.py -k emit` shows prescan_start in log
     output" is acceptance.
   - If the plan involves an architecture decision, note it — the adr agent
     should be invoked to record it
6. **Size phases for a single context window.** If you can't describe the
   test-first implementation of every item in a phase and hold it in your
   head, the phase is too big. Split it. This is the primary defense against
   stubbing — phases that fit in one context window get completed fully.
7. **Persist everything.** Write the full plan doc. The Reasoning section must
   be detailed enough that someone in a fresh context can understand *why*
   every decision was made — not just *what* will be done.
8. **Surface open questions.** If anything is unresolved, capture it in Open
   Questions rather than guessing. Tag each with severity: **BLOCKING** (must
   resolve before execution), **PHASE-GATED** (must resolve before a specific
   phase), or **ADVISORY** (can resolve during execution).

### What to ask the user

- What constraints exist (timeline, backwards compat, affected teams)?
- Are there related changes in flight?
- What's the blast radius if something goes wrong?
- Which parts of the codebase are they most/least familiar with?

### Output

A complete plan doc. Tell the user: "Pass 1 complete. Clear context and come
back for Pass 2 (gap analysis) when ready."

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

Updated plan doc with gaps filled. Tell the user: "Pass 2 complete. Clear
context and come back for Pass 3 (quality gates) when ready."

---

## Pass 3: Quality Gates

**Goal:** Ensure the plan is ready for execution — TDD-first, observable,
debuggable, and coherent.

**Trigger:** User returns with the plan doc and asks for quality gate review,
or says "pass 3" / "final review".

### Checks

**1. TDD ordering and specificity**
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
- Are the open questions resolved or tagged with severity (BLOCKING,
  PHASE-GATED, ADVISORY)? Untagged open questions are not acceptable.

**5. Project conventions**
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
**Coherence:**
- [any reasoning gaps filled, scope adjustments]
**Confirmed ready:** [yes/no — if no, what remains]
```

### Output

Final plan doc ready for execution. Before declaring readiness, check Open
Questions:

- If any **BLOCKING** items remain: the plan is not ready. List them and say
  what's needed to resolve each one.
- If any **PHASE-GATED** items remain: the plan is ready to start, but flag
  which phases are blocked and what must be resolved before reaching them.
- If only **ADVISORY** items remain: the plan is ready.

Tell the user: "Pass 3 complete. The plan is ready for execution." or
"Pass 3 complete. N blocking items remain before execution can start: ..."

---

## Usage Patterns

### Full three-pass (recommended for complex changes)

```
User: "Let's plan [feature/fix]. Here's the issue: ..."
→ Pass 1 produces plan doc
User: [clears context] "Here's our plan doc. Run pass 2."
→ Pass 2 fills gaps
User: [clears context] "Here's our plan doc. Run pass 3."
→ Pass 3 applies quality gates
User: [clears context] "Here's our plan doc. Let's execute."
→ Execution follows the plan phase by phase
```

### Abbreviated (for moderate changes)

Combine Pass 2 and Pass 3 into a single review if the change is moderate in
scope. The user can say "pass 2+3" or "review and finalize".

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

### Phase completion checklist

Before moving from Phase N to Phase N+1, confirm:

- [ ] All changes listed in Phase N are implemented (not stubbed)
- [ ] Every function/component built in this phase is called from where
      the plan says it should be called — trace from the entry point
- [ ] Tests for Phase N's changes were written first and are passing
- [ ] Existing tests still pass (regression check)
- [ ] The system is in a working state
- [ ] Phase N changes are committed

Report this checklist to the user at each phase boundary. Do not silently
move on. The wiring check is the one most likely to be skipped — a function
with passing unit tests feels done, but if nothing calls it, it's dead code.

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
- **Built means wired.** Code that exists but isn't reachable from the entry
  point is dead code, not progress. After building something, trace the call
  path. If nothing calls it yet, that's part of the same item — not a
  separate task for later.
- **Commit at every stable point.** After each phase passes its checklist,
  commit. No batching phases into a single commit. Each commit is a verified,
  working checkpoint that can be rolled back to independently.
- **No assumed behavior.** Do not plan around how you think a library, API,
  or existing code works. Read the docs, read the source, run a probe.
  "I believe this method returns X" is not validation. This applies during
  planning (Passes 1-3) and during execution — if you discover mid-phase
  that something doesn't work as the plan assumed, stop and update the plan
  before continuing.
