# Phase Plan — Pass 1: Plan and Gap Analysis

> Loaded on demand by the `phase-plan` skill when the user invokes Pass 1, or asks for a gap analysis of a
> plan that already exists (start at § Gap-analysis step). Assumes the main `phase-plan.md` skill is already
> loaded (plan doc structure, usage patterns, guardrails).
>
> **Not a plan template.** This file is the `phase-plan` skill's
> instructions for Pass 1. The plan doc itself is a single file (see
> `phase-plan.md` § One plan, three passes). All three passes refine
> that same file — do not create per-pass plan files like
> `plans/foo-pass1.md`.

**Goal:** Produce a complete plan with full reasoning persisted, then run the gap-analysis step on it as an
explicit, separately logged step. Pass 2 (independent review) and Pass 3 (quality gates) follow in fresh
contexts.

**Trigger:** User presents an issue, feature request, or problem to plan; or says "gap analysis" about a plan
that exists.

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
3. **Validate external assumptions with probes.** If the plan depends on a library, API, CLI tool, data
   source, or any code you didn't write, verify how it actually works before building a plan around it,
   following § Probe rules. Common traps:
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
     system and confirming behavior outside the test harness. A phase that writes to an external system uses
     the external-write tier (dry run, then a small supervised run with read-back, then the full run).
   - **Write-set** for every phase, traced from the gap-analysis reverse search: tests, fixtures and docs
     count, not only code. Read-set is optional. Shared-state contract is optional for sequential phases;
     production and ops state belongs in the Delivery shape section.
   - If the plan involves an architecture decision, note it — the adr agent
     should be invoked to record it
7. **Fill the Delivery shape section.** PR count (default one per plan), merge order, the repo's gates, manual
   deploy steps, calendar dependencies, and where unattended jobs run. Start from saved preferences (memory,
   project instructions) and say which ones you used; ask only for what they do not answer.
8. **Write the Concurrency Map line.** Ask once: could any phases run in parallel? Default to sequential and
   write one line with the reason ("All phases sequential: each phase reads what the prior wrote"). Declare a
   parallel set only when write-sets are disjoint, shared-state contracts cannot collide, and you can name the
   re-entry check that would catch a leak; then write the full block (main file § Concurrency Map). "Both
   phases run in worktrees" is not enough: worktrees share a parent repo, and `git checkout`, `git stash` or
   `git rebase` from a child worktree can move the parent's HEAD.
9. **Inventory documentation impact.** For every file the plan adds,
   renames, moves, or removes, grep the repo for references and capture
   them in the plan's **Documentation Impact** section (see main
   `phase-plan.md` § The Plan Doc). For each referenced doc, name
   which phase will update it — the phase that makes the reference
   stale, not a later cleanup phase.

   If the impact is large (many references, multiple cross-cutting
   files, or a rename that touches the registry in `agents.md`),
   escalate to a Phase 0 discovery task (D-item) so the grep is done
   firsthand before phases are sized.

   A plan that adds, renames, or removes a file with an empty
   Documentation Impact section is a plan defect. At minimum list
   "grepped — no references found" with the search terms used.
10. **Size phases for a single context window.** If you can't describe the test-first implementation of every
    item in a phase and hold it in your head, the phase is too big. This is the primary defense against
    stubbing. **Hard rule: 3 files maximum; 4 or more must split.** An atomic unit counts as one file: a
    version-bump pair, test-enforced parity twins, a guard and its allowlist entry. *Example:* a phase that
    edits a parser, its test, the CLI that calls it, and the README is four files, so split it: parser + test
    + CLI wiring, then the README in the phase after, or move the README line into the phase that already
    edits docs.
11. **Persist everything.** Write the full plan doc at
   `plans/YYYY-MM-DD-N-plan-<kebab-slug>.md` (create `plans/` if missing).
   Use today's date (run `date +%Y-%m-%d` if uncertain), pick `N` as the
   next unused ordinal for today by scanning existing `plans/` entries
   (always include the ordinal — even on the day's first plan), keep the
   literal `plan-` prefix, and pick a short kebab-case slug. See the main
   `phase-plan.md` § The Plan Doc for the full naming rules. If the project
   already keeps plans under a different convention, match that instead.
   The Reasoning section must be detailed enough that someone in a fresh
   context can understand *why* every decision was made — not just *what*
   will be done. Add a short current-state line at the top (Status).
12. **Surface open questions.** If anything is unresolved, capture it in Open Questions rather than guessing,
    with a proposed tag (**BLOCKING**, **PHASE-GATED**, **ADVISORY**) and a one-line rationale. Decide
    engineering-internal choices yourself and record them as `Decided by agent: X, because Y`. Every question
    the user owns is walked per `walk-through.md` before the pass closes.
13. **Run § Gap-analysis step** on the drafted plan, then close per § Output.

## Probe rules

A probe gathers facts: what data exists, how much, its shape, how it changes, and how the destination is
configured (fields, screens, permissions, limits, retention). Proving behaviour belongs in tests.

- **Read-only by definition.** Anything that writes is a validation step, not a probe: it runs in a sandbox
  or with the user's approval.
- **For behaviour-driving facts, a probe beats reading.** Record the command, the full count (not a sample;
  flag samples as samples) and the date in Verified Assumptions.
- **Probe as the execution identity:** the account, token or role the change will run under, not yours.
- **Read the destination's config** before planning writes to it.
- **Learn a record's lifecycle** by looking at records already in later states.
- **Confirm data sources and domain terms with the user** after checking memory and project notes.
- **Re-measure gating figures at execution start**; a count from planning day is a forecast.
- **Failure behaviour:** learn it from source, docs or logs. If unknown, it is an open question and the test
  fakes cover both outcomes. Never provoke a failure live. Failure behaviour that was not observed live is
  marked "not observed live" in Verified Assumptions and carried as a risk; a harmless read-only failure call
  (for example a read with a bad token) closes the gap when clearly safe and approved by the user.
- A probe result kept as a fixture goes into the repo when captured, never only a session scratchpad.

## Gap-analysis step

An explicit step with its own Review Log entry, run after drafting, on a plan that comes from an older pass
structure (main file § compatibility rule), and as the scoped re-check after any late change. It looks
**outward**: the plan's own text is not evidence.

1. **Read the plan end to end**, then **start from the previous pass's additions**: what was added last is
   the least reviewed text in the plan.
2. **Reverse search.** Every name and literal value the plan adds, renames or removes: search all file types
   in this repo, sibling repos, and sibling plans (other `plans/` files, open worktrees). Record the terms and
   the hit count in the Review Log entry. Each hit is either handled by a phase or recorded as harmless.
3. **Value domains, not existence.** Where the plan uses a field, status or enum, read the set of values it
   can take and check every value the plan writes or matches is in it. "The field exists" is not enough.
4. **Sibling comparison table** (only when a sibling system does the same job): one row per behaviour, one
   column per system; each difference is fixed or recorded as deliberate.
5. **Neighbour check.** Open PRs and branches; other sessions' plans and worktrees; reserved version numbers;
   the `origin/<default>` SHA you verified against (record it); other writers to, and automation reacting to,
   the same records.
6. **Verify claims against the codebase.** Open every file, function and call site the plan names; confirm it
   exists and works as the plan assumes.
7. **For each phase:** what must exist before it starts, and does a prior phase create it? What else touches
   the same files or depends on them? If it ships alone, is the system still coherent? Which associated changes
   are implied but not listed (types after a schema change, tests after an interface change, docs after a
   behaviour change)? Are there ordering dependencies within the phase?
8. **Cross-phase.** Every "Depends on" still accurate; no circular dependencies; each phase within the size
   rule after tracing its write-set.
9. **Concurrency.** For a declared parallel set: write-sets disjoint, contracts written as invariants, re-entry
   checks concrete. For a sequential plan: is the one-line reason still true?
10. **Reasoning.** Do the stated reasons still hold given the full plan? Is a rejected alternative now better?
    Is every new dependency the step added verified?
11. **Hedges.** Run every "consider", "grep to confirm" or "may need" now, or turn it into an open question.
12. **Extend, don't rewrite.** Insert missing steps, add phases if needed, and replace superseded planning text
    in place so the plan reads as current. History lives in the Review Log.

Review Log entry (last in this step):

```markdown
### Pass 1: Gap-analysis step — [date]
Reverse search terms: [terms], [where], [hit count]. Base: `origin/<default>` [sha].
**Found:**
- [gap or missing change]
**Concurrency:**
- [adjustments, or "no changes — map confirmed"]
**Changed:**
- [what was added or revised, and where]
**Confirmed:**
- [what held up]
```

## What to ask the user

- What constraints exist (timeline, backwards compat, affected teams)?
- Are there related changes in flight?
- What's the blast radius if something goes wrong?
- Which parts of the codebase are they most/least familiar with?

## Output

A complete plan doc with the gap-analysis entry in its Review Log. If any question needs the user, walk it per
`walk-through.md` (one per message, decision first, answers written into the plan immediately), and re-run the
gap-analysis step on any part an answer changed. Then write § Next pass handoff and close:

> "Pass 1 complete. [Decisions recorded; decided-by-agent items for override.] Next: Pass 2 (independent
> review) in a fresh session; the paste is in the plan's Next pass section.
>
> **Plan file:** `plans/YYYY-MM-DD-N-plan-<slug>.md`"

Always include the plan file path in the close-out — the user should never
have to scroll back through session history to find where the plan lives.

**If there are no open questions**, say so in the same close-out:

> "Pass 1 complete. No open questions. Next: Pass 2 (independent review) in a fresh session.
>
> **Plan file:** `plans/YYYY-MM-DD-N-plan-<slug>.md`"

## Next pass handoff

Every pass, and an execution stopping before the end, ends by replacing the plan's last section, `## Next
pass`, so the user's paste to resume is one line. It names: the plan path; the base commit and how to re-check
it; branch and worktree; the pass file to load; locked decisions; open items; named risk targets for the next
pass to attack first; and the next pass's deliverable and done-when. Pass 2 builds its reviewer briefs from
the same facts.

A compacted context is not fresh: if this session has been compacted, say so and hand off rather than running
the next pass here.

## Reminders (critical, repeated for forefront)

- **Do not execute during planning.** Pass 1 is analysis only. Code
  changes happen after Pass 3.
- **Never skip reasoning.** A plan without reasoning is a todo list.
- **No assumed behavior.** If a library/API/tool/code behavior is
  unverified, capture it as an Open Question or a Phase 0 discovery task
  — don't plan around "I think it works like X."
- **The gap-analysis step is not optional** and gets its own Review Log entry, even when drafted in the same
  session.
