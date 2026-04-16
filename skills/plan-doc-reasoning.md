---
name: plan-doc-reasoning
description: >
  Universal floor for any plan document at `plans/*.md`. Trigger when
  Claude is about to create a new plan, extend an existing one, or
  draft a review report that will be saved to `plans/`. Enforces that
  every plan carries Problem Statement, Approach, and Reasoning — the
  WHY, not just the WHAT. Format-flexible: accepts phase-plan's
  template, external-learn's review format, or any format that puts
  the three elements on the page. Complements `phase-plan` (which
  prescribes a specific format for complex changes); this skill
  enforces the minimum every plan doc must meet.
---

# Plan Doc Reasoning

The most expensive thing about a plan is rediscovering why a decision
was made after someone forgot. This skill's job: every plan in `plans/`
carries a reasoning trail, not just a change list.

## When to trigger

- About to create or edit a file at `plans/*.md`
- About to save an external-learn review report
- About to save a plan sketched during conversation
- About to commit a plan file that skipped this check earlier

## When NOT to trigger

- Editing `plans/*.md` content that is not a plan (fixtures, assets)
- The project uses a different location (e.g., `docs/plan-*.md`) —
  in that case the rule still applies, just point at the project's
  convention; the three elements are still required

## The three required elements

Every plan doc must include these, in any heading or prose form:

1. **Problem Statement** — what we are solving and why it matters now.
   Reference the issue, symptoms, constraints, or the user pain that
   triggered the work. Not a future-work list — a present-day problem.
2. **Approach** — what we propose to do. The shape of the change, not
   every implementation detail. A reader should be able to see the
   plan's outline without reading the whole thing.
3. **Reasoning** — why this approach rather than alternatives. Rejected
   options and the reason they were rejected. Future readers should be
   able to reconstruct the decision process from this section alone.

**Format is flexible.** All three can live under explicit headers
(`## Problem Statement`, `## Reasoning`), or be woven into an analysis
narrative. The test is semantic presence, not heading names.

## Formats that already satisfy the floor

Several established formats hit all three by construction — use them
and the skill's work is done.

- **phase-plan template** — Problem Statement + Reasoning are explicit
  top-level sections. Phases carry the Approach.
- **external-learn review report** — Source Summary names the problem
  the external content targets; Our Current Coverage + the per-candidate
  Rationale carry the reasoning; Proposals carry the approach.
- **ADR record** — Context (problem), Decision (approach), Rationale
  (reasoning). Three-for-three.

When using one of these, do the template work and trust it.

## When you are writing freeform

If the plan is not using a known template (ad-hoc sketch, quick
triage note, interim draft), explicitly include the three elements.
A minimal shape that works:

```markdown
# <Title>

## Problem Statement
What we are solving, and why now.

## Approach
What we propose to do — the shape of the change, not every detail.

## Reasoning
Why this approach. Alternatives considered and rejected, with reasons.
Constraints that shaped the choice.

## <rest of the doc>
Change list, phases, open questions, whatever fits.
```

## Quality check before saving

Before writing the plan file to disk, verify:

- [ ] A future reader can answer "what problem did this address?"
      from the doc alone — not from chat, not from the commit message.
- [ ] A future reader can answer "why this approach and not
      alternatives?" from the doc alone.
- [ ] The doc makes its case — it is not just a list of actions.

If any check fails, add the missing element before writing. Do not
defer to the commit message or a later edit. The reasoning is the
most fragile piece of any plan — write it while the context is fresh,
not after.

## Relationship to phase-plan

phase-plan prescribes the full ceremony (three passes, specific
template, execution rules). This skill prescribes only the floor.
When phase-plan is active, its template already exceeds the floor —
both can fire together without conflict. That is the "load-bearing
repetition" exception in `skill-hygiene.md`: the overlap is
intentional, not wasted.

When phase-plan is not active (lightweight plan, review report,
ad-hoc sketch), this skill is the only guardrail keeping plan docs
from collapsing into pure change lists.
