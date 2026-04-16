# Phase Plan — Pass 1: Reasoning and Plan Development

> Loaded on demand by the `phase-plan` skill when the user invokes Pass 1.
> Assumes the main `phase-plan.md` skill is already loaded (plan doc
> structure, usage patterns, guardrails).

**Goal:** Produce a complete plan with full reasoning persisted.

**Trigger:** User presents an issue, feature request, or problem to plan.

## Steps

1. **Understand the problem space.** Read the issue, relevant code, and any
   existing context. Ask clarifying questions — do not assume. If the
   request itself is ambiguous (multiple plausible interpretations, not
   just missing planning details), use the
   `ask-questions-if-underspecified` skill first — it uses a lighter
   multiple-choice format better suited to resolving interpretation
   before planning engages. Pass 1 handles the planning-detail questions
   that remain after interpretation is settled.
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
8. **Persist everything.** Write the full plan doc at
   `plans/<kebab-name>.md` (create the `plans/` directory if it is missing).
   If the project already keeps plans elsewhere, match the existing
   convention instead of creating a new location. The Reasoning section must
   be detailed enough that someone in a fresh context can understand *why*
   every decision was made — not just *what* will be done.
9. **Surface open questions.** If anything is unresolved, capture it in Open
   Questions rather than guessing. For each question, recommend a severity
   (**BLOCKING**, **PHASE-GATED**, **ADVISORY**) with a brief rationale for
   why you chose that level — but the user makes the final call. Do not
   silently classify questions as ADVISORY and move on. Every open question
   is context the user needs to see.

## What to ask the user

- What constraints exist (timeline, backwards compat, affected teams)?
- Are there related changes in flight?
- What's the blast radius if something goes wrong?
- Which parts of the codebase are they most/least familiar with?

## Output — Walk-Through Procedure (canonical)

A complete plan doc. If there are any open questions — regardless of
recommended severity — the default is to walk the user through them one at
a time before advancing. The user must have seen and confirmed every
question's severity before Pass 2 begins.

This procedure is the canonical walk-through referenced by Pass 2 and Pass 3.

**Step 1: Brief listing.** Present all open questions as a short numbered
summary with the recommended severity and a one-line rationale:

> "Pass 1 complete. [N] open questions. Brief summary:"
>
> 1. [RECOMMENDED: ADVISORY] Question text. *One-line rationale.*
> 2. [RECOMMENDED: PHASE-GATED (Phase 3)] Question text. *One-line rationale.*
> 3. [RECOMMENDED: BLOCKING] Question text. *One-line rationale.*
>
> "Let's walk through these one at a time to confirm severity. Starting
> with #1 unless you'd rather accept all as recommended."

**Step 2: Walk through each question.** Unless the user opts out ("accept
all as recommended" or equivalent), present one question at a time and wait
for a response before advancing:

> "**Question 1 of [N]**
>
> [Question text]
>
> Recommended: [SEVERITY]. [Full rationale — can be longer than the
> one-liner in the brief listing if context helps the user decide.]
>
> Confirm as [SEVERITY], or override to BLOCKING / PHASE-GATED / ADVISORY?"

Record each confirmed severity in the Open Questions section of the plan
doc, prefixed `[CONFIRMED: <severity>]` to distinguish user-confirmed from
agent-recommended. Continue to the next question only after the current
one is confirmed.

**Step 3: Close out.** After the last question (or immediately if the user
opts out):

> "All [N] open questions confirmed. [Tally, e.g., '1 BLOCKING, 1 PHASE-GATED,
> 1 ADVISORY.'] Clear context and come back for Pass 2 (gap analysis) when
> ready."

Do not say "no blocking items" and move on while questions remain
unreviewed. The user may decide an ADVISORY question is actually BLOCKING —
that call can only be made if they see and consider each one. The walk-
through is what makes "the user decides" concrete; the bulk-accept shortcut
exists for experienced users who trust the recommendations.

**If there are no open questions**, say: "Pass 1 complete. No open questions.
Clear context and come back for Pass 2 (gap analysis) when ready."

## Reminders (critical, repeated for forefront)

- **Do not execute during planning.** Pass 1 is analysis only. Code
  changes happen after Pass 3.
- **Never skip reasoning.** A plan without reasoning is a todo list.
- **No assumed behavior.** If a library/API/tool/code behavior is
  unverified, capture it as an Open Question or a Phase 0 discovery task
  — don't plan around "I think it works like X."
