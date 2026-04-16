---
name: phase-plan
description: >
  Three-pass planning workflow for complex changes. Pass 1 develops the plan
  with full reasoning persisted to the plan doc — including Phase 0 discovery
  when unknowns exist. Pass 2 reviews for gaps, missing changes, and downstream
  effects. Pass 3 applies quality gates (TDD ordering, diagnostic logging,
  debugging readiness, validation calibration). Each pass uses a fresh context
  with the plan doc as the sole handoff artifact. Per-pass details live in
  skills/phase-plan/pass{1,2,3}.md and skills/phase-plan/execute.md — this
  main file is the entry point and canonical source for the plan doc
  template and cross-cutting guardrails. Trigger when the user says
  "phase plan", "three-pass plan", "plan review", or when starting
  non-trivial changes that benefit from structured reasoning before execution.
---

# Phase Plan

<!-- TRACKING: Wiring gap issue (2026-04-07)
     Recurring problem: phases build isolated components with passing unit tests
     but fail to wire them into the entry point. All tests green, feature doesn't
     work. Added: Wiring test field, entry-point verification requirements,
     Isolation Trap anti-pattern section (now in phase-plan/execute.md). Monitor
     whether these changes actually prevent the failure mode in practice. If it
     recurs, the next step is a programmatic hook that checks for entry-point
     test coverage at phase boundary. -->

<!-- TRACKING: Discovery + Validation additions (2026-04-10)
     Two additions: (1) Phase 0 Discovery for validating assumptions before
     committing to implementation — triggered when unknowns exist. (2) Per-phase
     Validation field calibrated to scope — tests are the floor, not the ceiling.
     Also added: Combined Pass 1+2 usage pattern, Phase 0 execution rules,
     validation calibration as Pass 3 quality gate. Monitor whether Phase 0
     catches assumption errors that would have caused mid-execution rework,
     and whether validation strategies are actually calibrated vs defaulting
     to "tests are sufficient" for everything. -->

<!-- TRACKING: Discovery exemption + plans dir + walk-through (2026-04-16)
     Three additions: (1) Promoted the Phase 0 "no TDD" rule to a named
     Discovery Exemption with explicit scope, bounded to discovery work only.
     Added per-task Disposition field (throwaway / keep-as-fixture / promote)
     to resolve the hybrid case where spike code becomes production code.
     Context: observed in clauditor golden-dataset-eval plan where the D1
     spike produced disposable code alongside reflexive TDD tests — the
     skill's "no TDD in Phase 0" signal was too weak to override the TDD
     instinct. (2) Prescribed plans/ as the default location for plan docs,
     with directory auto-creation; fall back to existing project convention
     (e.g., docs/) if one is established. (3) Made one-at-a-time walk-through
     the default for confirming open-question severities at the end of each
     pass (previously a bulk listing). Brief listing first, then each
     question presented individually with a confirm/override prompt. User
     can opt out with "accept all as recommended" — default changed because
     bulk listings let the user skim past questions that deserve a real
     decision. Monitor: (a) whether the Discovery Exemption neutralizes the
     TDD-instinct override during Phase 0 execution, or whether spikes
     continue to accumulate tests by reflex; (b) whether the walk-through
     surfaces severity overrides that would have been missed by the bulk
     listing, or whether users reflexively opt out. If the exemption isn't
     holding, escalate to a programmatic check. -->

<!-- TRACKING: Plan filename convention (2026-04-16)
     Changed the default plan doc filename from `plans/<kebab-name>.md` to
     `plans/YYYY-MM-DD-N-plan-<slug>.md`. Rationale: chronological sort by
     name (dates ascending, ordinals ascending within a day), an
     unambiguous "plan" marker so files read as plans out of context, and
     collision-free naming when multiple plans land on the same day. The
     ordinal is always present (not just on collisions) so sort order
     stays stable retroactively when a second plan lands that day.
     Triggered by a rename pass over an existing `plans/` tree where
     ~50 files had mixed conventions (`plan-X.md`, `X-plan.md`, no
     marker) and no temporal ordering — the new convention solves both.
     Monitor: (a) whether agents remember the ordinal on day-1 plans
     (likely failure mode: they drop it when there's no collision yet),
     (b) whether the convention survives contact with projects that
     already have a plan directory with a different scheme, (c) whether
     days ever exceed 9 plans and force the zero-padding fallback. If
     the ordinal rule is forgotten, escalate to a Write-tool guard that
     validates the filename pattern before creating the file. -->

<!-- TRACKING: File split (2026-04-16)
     Split the skill into a slim main file (this) plus per-pass files in
     skills/phase-plan/. Main file holds the plan doc template, usage
     patterns, and cross-cutting guardrails (always loaded). Per-pass files
     (pass1.md, pass2.md, pass3.md, execute.md) contain detailed procedures
     and are Read on demand when the user invokes a specific pass. Rationale:
     the file had grown to 953 lines, and the common usage pattern is
     "Pass 1+2 together, then clear, then Pass 3" — splitting matches that
     cadence and keeps the load surface small per context window. Critical
     rules (no stubs, wiring tests, commit per phase, Discovery Exemption
     summary) are intentionally repeated across files; redundancy is
     load-bearing here because forgetting these is the primary failure mode.
     Monitor whether the split actually reduces cognitive load or creates
     navigation friction. -->

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

## Loading the Per-Pass Files

This main file is the entry point. Detailed procedures for each pass live
in sibling files. Load the relevant file(s) when the user invokes a pass:

| User says | Read |
|-----------|------|
| "pass 1" / "let's plan" | `skills/phase-plan/pass1.md` |
| "pass 2" / "gap analysis" / "review the plan" | `skills/phase-plan/pass2.md` |
| "pass 1+2" / "plan and review together" | `pass1.md` + `pass2.md` |
| "pass 3" / "quality gates" / "final review" | `skills/phase-plan/pass3.md` |
| "let's execute" / "start execution" | `skills/phase-plan/execute.md` |

When the user is running the Combined Pass 1+2 pattern, both files can be
loaded in the same context — the gap analysis benefits from the Pass 1
exploration still being fresh. Pass 3 always uses a fresh context for
clean eyes on the final plan.

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

The plan doc is a markdown file. Its default location is
`plans/YYYY-MM-DD-N-plan-<kebab-slug>.md` at the repo root — create the
`plans/` directory if it does not exist. Name components:

- `YYYY-MM-DD` — today's date. Run `date +%Y-%m-%d` if uncertain.
- `N` — ordinal within the day, starting at `1`. Check existing entries in
  `plans/` for today and pick the next unused number. Always include the
  ordinal, even on the day's first plan, so sort order stays chronological
  once a second plan lands that day. Use single digits by default; switch
  to zero-padded (`01`, `02`, ...) and rename that day's earlier entries if
  a day ever exceeds 9 plans, so `10` doesn't sort between `1` and `2`.
- `plan-` — literal prefix so the file reads as a plan even out of context.
- `<kebab-slug>` — short kebab-case description of the topic.

Example: `plans/2026-04-16-1-plan-adaptive-thinking.md`.

If the project already keeps plans under a different convention (e.g., an
existing `designs/` tree with its own scheme), match the existing convention
rather than forcing this one. Everything goes in this file — it is the
handoff artifact between context windows.

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
**Discovery tasks:** Each task declares a question, a probe, success criteria,
and a disposition for any code the probe produces. Format:
- [ ] **D1: [Question being answered]**
  - **Probe:** Specific investigation — "Run `tool --flag` and confirm output
    contains X", "Read `src/engine.py:45-80` and confirm Config accepts Y",
    "POST to `/api/v2/foo` with payload Z and record the response shape"
  - **Success criteria:** What answer resolves the question (a concrete
    value, shape, or observed behavior — not "it seems to work")
  - **Disposition:** What happens to code written during the probe. One of:
    - `throwaway` — delete or archive the spike after findings are recorded
    - `keep-as-fixture` — the spike's output becomes test data or reference
      material; consumers get TDD, the fixture itself does not
    - `promote` — the spike code will become production code in a named
      follow-up phase; TDD applies to the promoted code in that phase,
      not to the spike
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

## Usage Patterns

### Full three-pass (recommended for complex changes)

```
User: "Let's plan [feature/fix]. Here's the issue: ..."
→ Load pass1.md. Pass 1 produces plan doc (may include Phase 0)
User: [clears context] "Here's our plan doc. Run pass 2."
→ Load pass2.md. Pass 2 fills gaps
User: [clears context] "Here's our plan doc. Run pass 3."
→ Load pass3.md. Pass 3 applies quality gates
User: [clears context] "Here's our plan doc. Let's execute."
→ Load execute.md. Execute Phase 0 first (if present), then phases 1-N
```

### Combined Pass 1+2, then Pass 3 (recommended for moderate changes)

Run Pass 1 and Pass 2 in the same context window, then clear context before
Pass 3. This works well when the plan is moderate in scope and the gap
analysis benefits from still having the original exploration context fresh.
The user can say "pass 1+2" or "plan and review together". Pass 3 still
gets a fresh context — the quality gate review benefits from clean eyes.

```
User: "Let's plan [feature/fix]. Here's the issue: ..."
→ Load pass1.md + pass2.md. Pass 1 produces plan doc, Pass 2 reviews in same context
User: [clears context] "Here's our plan doc. Run pass 3."
→ Load pass3.md. Pass 3 applies quality gates with fresh eyes
User: [clears context] "Here's our plan doc. Let's execute."
→ Load execute.md. Execution follows the plan phase by phase
```

### Abbreviated (for simple changes)

Combine all three passes into a single context if the change is small and
well-understood. The user can say "plan and finalize" or "quick plan". Load
`pass1.md`, `pass2.md`, and `pass3.md` together.

### With Phase 0 Discovery

When the plan includes Phase 0, execution has a natural checkpoint:

```
User: [clears context] "Here's our plan doc. Let's execute."
→ Load execute.md. Execute Phase 0 discovery tasks (Discovery Exemption applies)
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

## Discovery Exemption (summary)

Phase 0 discovery tasks are exempt from implementation rules (TDD cycle,
wiring tests, commit-per-item, no-stubs). They produce knowledge, not
production code. Each discovery task declares a **Disposition**
(`throwaway`, `keep-as-fixture`, or `promote`) for any code it generates.

**Full details in `skills/phase-plan/execute.md` § Discovery Exemption.**
Load that file before executing Phase 0.

What still applies during discovery: Verified Assumptions must be updated
with concrete evidence, findings must be recorded in the plan doc, and
each task must honor its declared Disposition.

---

## Guardrails

**Scope note:** The execution-related guardrails below ("No stubs, ever",
"Built means wired", "Commit at every stable point") govern implementation
phases. Phase 0 discovery operates under the Discovery Exemption — read
`execute.md` § Discovery Exemption before executing Phase 0.

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
