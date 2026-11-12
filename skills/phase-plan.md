---
name: phase-plan
description: >
  Three-pass planning workflow for complex changes. Pass 1 develops the plan
  with full reasoning persisted to the plan doc — including Phase 0 discovery
  when unknowns exist — then runs an explicit, outward-looking gap analysis.
  Pass 2 is an independent review: three subagents, one per lens, try to
  refute the plan. Pass 3 applies quality gates (TDD ordering, tests that can
  fail, debugging readiness, validation calibration). Each pass uses a fresh
  context with the plan doc as the sole handoff artifact. Per-pass details live
  in skills/phase-plan/pass{1,2,3}.md, skills/phase-plan/execute.md and
  skills/phase-plan/walk-through.md — this main file is the entry point and
  canonical source for the plan doc template and cross-cutting guardrails.
  Trigger when the user says
  "phase plan", "three-pass plan", "plan review", or when starting
  non-trivial changes that benefit from structured reasoning before execution.
  ALSO trigger when a batch of work approved in CONVERSATION — a "yes, do all
  that" — would create files, change a data contract (schema, event vocabulary,
  published lexicon, stored format, public API), or span several files: persist
  the proposal to plans/ BEFORE executing, even if the plan is short. The
  session-level accumulation is what crosses the threshold, not any single turn,
  so this fires on the batch even when each increment felt small. ALSO
  trigger before bulk writes to an external system (many records created,
  updated or closed), even when no code changes.
---

# Phase Plan

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
     navigation friction. The other TRACKING history moved to
     skills/phase-plan/CHANGELOG.md (2026-11-12). -->

Three-pass planning for complex changes. Each pass uses a fresh context window.
The plan doc is the single artifact that travels between passes — it must carry
all reasoning, not just the steps.

**Why three passes instead of one:** Complex changes have emergent properties.
Missing dependencies, ordering issues, and downstream effects are hard to see
while you're still building the plan. Fresh eyes on a complete plan catch what
the planning mind missed, and a reviewer who did not write the plan catches
more than a re-run of the author's own checklist.

**Later passes extend the structure and replace superseded text.** Pass 1
builds the base; later passes add missing items, insert steps into existing
phases and strengthen reasoning. Where a later decision makes earlier planning
text wrong, replace that text in place so the plan reads as current; the
history lives in the Review Log. Restructuring phases needs the user's approval.

---

## One plan, three passes

**Critical clarification:** The plan is a **single file** — for example
`plans/2026-04-17-1-plan-foo.md`. All three passes refine that same file
at different depths and along different dimensions:

- **Pass 1** builds the base (problem, reasoning, phases, open questions),
  then runs the gap-analysis step: an outward sweep for what the plan missed.
- **Pass 2** is an independent review: three subagents, one per lens, try to
  refute the plan, and the main session re-checks every claim.
- **Pass 3** layers quality gates on top: TDD ordering, tests that can fail,
  observability, validation calibration, documentation impact coverage.

Each pass is a pass *over* the same document, not the production of a
separate document. The passes differ in **what they look for**, not
**what they produce**.

### Per-pass skill files are instructions, not plan templates

The files in `skills/phase-plan/` (`pass1.md`, `pass2.md`, `pass3.md`,
`execute.md`, `walk-through.md`) are this skill's own instruction content — they tell
Claude what to do in each pass. They are **not** templates for plan
output and they do **not** correspond to per-pass plan artifacts. The
skill's change history is in
`skills/phase-plan/CHANGELOG.md`.

If you find yourself creating `plans/foo-pass1.md`, `plans/foo-pass2.md`,
`plans/foo-pass3.md`, or any other per-pass plan files, stop. You
should be editing the single plan file.

## Compatibility rule

Before any pass, read the plan's Review Log. If it has no gap-analysis entry,
run `pass1.md` § Gap-analysis step first. A `Pass 1: Gap-analysis step` entry,
or any entry labelled `Pass 2…`, `Pass 1+2…` or `Pass 1 + Pass 2…`
other than `Pass 2: Independent review`, counts as gap analysis (plans begun
under the older pass order). An old `Pass 3: Quality Gates` entry satisfies
execution's start gate; an execution already started continues under its
existing structure. A session that was open when the skill changed is ended
and a new one started; re-invoking would leave both loading tables in context.

---

## Loading the Per-Pass Files

This main file is the entry point. Detailed procedures for each pass live
in sibling files. Load the relevant file(s) when the user invokes a pass:

Read them from the installed checkout, `~/.claude/coding-agents/skills/phase-plan/`, not from a path
relative to the current repo.

| User says | Read |
|-----------|------|
| "pass 1" / "let's plan" | `skills/phase-plan/pass1.md` |
| "gap analysis" (plan exists: start at its § Gap-analysis step) | `skills/phase-plan/pass1.md` |
| "pass 2" / "independent review" / "review the plan" / "plan review" | `skills/phase-plan/pass2.md` |
| "pass 3" / "quality gates" / "final review" | `skills/phase-plan/pass3.md` |
| "let's execute" / "start execution" | `skills/phase-plan/execute.md` |
| any list of decisions, in any pass | `skills/phase-plan/walk-through.md` |

Pass 1 drafts the plan and runs its gap-analysis step in one context. Pass 2 and Pass 3 each start fresh.

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
**Status:** one line of current state (pass done, phase shipped, next step).

## Problem Statement
What we're solving and why. Include issue references, symptoms, constraints.

## Reasoning
Why this approach? What alternatives were considered and rejected?
What assumptions are we making? This section is the "re-reasoning" record —
future readers (including future-us) should be able to reconstruct the
decision process from this section alone.

## Verified Assumptions
What we confirmed about libraries, APIs, CLI tools, data and existing code —
and how (docs link, source file:line, probe command + full count + date;
samples flagged as samples). Failure behaviour not seen is marked
"not observed live" and carried as a risk. Anything not listed is unverified.

## Documentation Impact
Every doc file that will be added, renamed, moved, removed, or
referenced differently by this plan. Captured at plan time so doc
updates become first-class phase items, not a deferred cleanup.

Format:
- `path/to/doc.md` — what changes there, which phase handles it

Typical candidates to check:
- `README.md` — command/skill/agent additions, renames, removals
- `agents.md` — agent registry, file reference, orchestration sequences,
  memory lists, recommended sequences
- `CLAUDE.md` — core principle changes (rare)
- Other skills/agents that cross-reference a file being changed
- `REFINEMENTS.md` / `EXTERNAL-LEARNINGS.md` — status transitions if
  the plan resolves or promotes a proposal

**Schedule each doc update in the phase that makes its reference
stale**, not a later "docs phase" at the end. Docs phases at the end
are the most-skipped part of any plan.

If the plan adds, renames, or removes a file, this section cannot be
empty. At minimum, record "grepped — no references found" with the
search terms used.

## Delivery shape
PR count (default one per plan), merge order, the repo's gates, manual deploy
steps, calendar dependencies, where unattended jobs run, rollback. Filled in
Pass 1 from saved preferences. Production and ops state lives here.

## Concurrency Map
One line by default: `All phases sequential: <reason>`. Ask once whether any
phases could run in parallel. Only for a declared parallel set, write the
block: disjoint write-sets, a shared-state contract written as invariants
(git HEAD, working directory, env, ports, daemons, lock files, external
services), and re-entry checks mapping one to one to it. Parallel work merges
back into the feature branch locally (`execute.md` § Step 4), never as PRs.
**Hard rule:** any shared write-set entry or shared-state mutation means
sequential.

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
**Read-set (optional):** Files this phase reads, when coupling matters.
**Write-set:** Every file this phase creates, edits or deletes, traced from
the gap-analysis reverse search: tests, fixtures and docs count. Name files,
not directories. Three files maximum; an atomic unit counts as one.
**Shared-state contract (optional for sequential phases):**
Mutable state outside the write-set (git HEAD and branches, processes and
ports, working directory and tmp paths, env and secrets, external systems),
written as invariants ("does not invoke `git checkout` in the parent
worktree"), not mechanisms ("runs in a worktree").
**Re-entry verification:** (Only for a phase in a parallel set.) One concrete
check per contract item: "main-repo HEAD == <pre-dispatch sha>".
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
- **External write:** dry run showing exactly what would be written, then a
  small supervised live run with every write read back, then the full run.
  Phase states: built → merged → deployed → observed; ✅ only at observed.
The validation strategy should match the risk.

### Phase N+1: Close-out (always the last numbered phase)
Outcome Summary, Status, deferred work, worktree removal, and Discoveries,
each answering:
"which pass should have caught this?"

## Open Questions
Each with a proposed tag and a one-line rationale: **BLOCKING** (before
execution), **PHASE-GATED** (before a named phase), **ADVISORY**. The user
decides, through `walk-through.md`; answers move into the plan as decisions.
Agent-decided items are listed as `Decided by agent: X, because Y`.

## Review Log
One entry per pass, oldest first, with fixed names (`Pass 1: Gap-analysis
step`, `Pass 2: Independent review`, `Pass 3: Quality Gates`).

## Execution Log
Phase records and decisions made during execution (kept apart from reviews).

## Next pass
Rewritten at the end of every pass: the one-line paste, plan path, base
commit, branch/worktree, pass file, locked decisions, open items, risk
targets, the next deliverable and done-when (`pass1.md` § Next pass handoff).
```

The user may already have a plan doc in a different format. Adapt to their
format rather than forcing this structure — the key requirement is that
reasoning and review history are persisted, not the exact heading names.

---

## Usage Patterns

### Full three-pass (recommended for complex changes)

```
User: "Let's plan [feature/fix]. Here's the issue: ..."
→ Load pass1.md. Pass 1 produces plan doc (may include Phase 0), then runs its gap-analysis step
User: [clears context] "Here's our plan doc. Run pass 2."
→ Load pass2.md. Three reviewers try to refute it; findings re-checked and folded in
User: [clears context] "Here's our plan doc. Run pass 3."
→ Load pass3.md. Pass 3 applies quality gates
User: [clears context] "Here's our plan doc. Let's execute."
→ Load execute.md. Execute Phase 0 first (if present), then phases 1-N
```

### Abbreviated (for simple changes)

Combine all three passes into a single context if the change is small and
well-understood. The user can say "plan and finalize" or "quick plan". Load
`pass1.md` and `pass3.md` together; a quick plan skips the independent review.

### A batch approved in conversation

The commonest way a plan fails to get written is not refusal — it is that nobody
noticed one was due. Work gets proposed in chat, approved with "yes, do all
that", and executed well: good commits, sound reasoning, nothing lost *today*.
What is lost is the one place that says why, so in three months the answer has
to be reconstructed from a dozen commit messages.

**Write the plan doc first when an approved batch would create files, change a
data contract, or span several files** — even a short one. A single paragraph of
Problem Statement / Approach / Reasoning is enough; the point is that it exists
and is one artifact. Walk-through answers that add work count toward this trigger.

*Why this trigger exists (two strikes, four months apart):* 2026-04-17, an
18-commit session built a new agent, three skills, three commands and two
ledgers with no plan doc, because each turn's increment felt small — it was the
accumulation that crossed the threshold. 2026-08-26, a rename touched 49 files,
changed an event vocabulary and a published lexicon, and deliberately broke
stored data, approved in one exchange, with no plan doc. In the second case the
plan doc would have paid immediately: it would have forced "what happens to logs
already written?" *before* the rename, rather than mid-flight when the reducer's
missing default branch turned a legacy log into a silently empty world.

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

If execution reveals something the plan missed, return to the plan doc: run
the gap-analysis step and Pass 3 on the changed part (and Pass 2 when the
change adds a phase, an external-system interaction or a write path), log it,
update the remaining phases, and continue.

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

- **Every list of decisions uses `skills/phase-plan/walk-through.md`**: one item per message, decision first.
- **Never skip reasoning.** A plan without reasoning is a todo list. The
  reasoning is what makes the plan re-entrant across context windows.
- **Extend the structure; replace superseded planning text.** Text a later
  decision made wrong is replaced in place, with the change in the Review Log;
  execution records stay append-only ("Delivered:" notes, skip records). If you
  are rewriting more than adding, stop and ask whether the base plan is wrong;
  restructuring needs the user's approval.
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
- **A new entry point invalidates every prior "wired" claim.** The rule above
  is applied *per phase, forward only* — and that is where it leaks. When a
  project grows a boundary it did not have (an HTTP surface, a CLI, a daemon),
  every capability built *before* it was correctly wired to an entry point
  **that no longer matters**, and nothing re-checks them. Observed: a service
  where five modules — one 414 lines with five inline tests and two dedicated
  suites — had **zero callers**, while the README listed them as features and
  the docs called the layer "proven." It was proven *as a library*; the
  implicit next clause, that the boundary exposed it, was false. **When you add
  a boundary, re-run the wiring question over everything that predates it.**
- **Coverage measures execution, not reachability — no coverage tool tells them
  apart.** A thoroughly-tested orphan has excellent coverage. The check that
  catches this is a **reachability gate**: enumerate modules, count callers
  outside themselves, compare against an *explicit allowlist of
  known-unreachable ones with reasons*. Make it fail in **both** directions —
  an unlisted module with no callers fails (new drift caught the day it
  appears, without blocking on a cleanup that is its own project), and a listed
  module that gains callers *also* fails, demanding removal. The second
  direction is what stops the allowlist rotting into a permanent excuse: it can
  only shrink or be argued with. Pin its size so the debt cannot quietly grow.
- **Watch for a test suite in two halves that never meet** — library tests that
  import modules directly and construct no entry point, plus boundary tests
  that drive the entry point, with nothing asserting a path between them. Both
  halves stay green while the middle is missing.
- **Commit at every stable point.** After each phase passes its checklist,
  commit. No batching phases into a single commit. Each commit is a verified,
  working checkpoint that can be rolled back to independently.
- **No assumed behavior.** Do not plan around how you think a library, API,
  or existing code works. Read the docs, read the source, run a probe.
  "I believe this method returns X" is not validation. This applies during
  planning (Passes 1-3) and during execution — if you discover mid-phase
  that something doesn't work as the plan assumed, stop and update the plan
  before continuing.
