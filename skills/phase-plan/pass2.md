# Phase Plan — Pass 2: Gap Analysis

> Loaded on demand by the `phase-plan` skill when the user invokes Pass 2.
> Assumes the main `phase-plan.md` skill is already loaded, and often
> `pass1.md` has been loaded in the same context (when using the Combined
> Pass 1+2 pattern).
>
> **Not a plan template.** This file is the `phase-plan` skill's
> instructions for Pass 2. The plan doc itself is a single file (see
> `phase-plan.md` § One plan, three passes) — Pass 2 extends that same
> file with gap analysis. Do not create `plans/foo-pass2.md` or any
> other per-pass plan file.

**Goal:** Review the plan for missing changes, downstream effects, and
incomplete reasoning.

**Trigger:** User returns with the plan doc and asks for gap analysis,
or says "pass 2" / "review the plan".

## Steps

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

## Review Log entry format

```markdown
### Pass 2: Gap Analysis — [date]
**Found:**
- [description of gap or missing change]
**Changed:**
- [what was added, reordered, or revised in the plan]
**Confirmed:**
- [aspects of the plan that held up under review]
```

## Output

Updated plan doc with gaps filled. If any open questions remain (including
new ones surfaced by the gap analysis), follow the **walk-through procedure
from `pass1.md` § Output**: brief listing, then one-at-a-time confirmation
unless the user opts out with "accept all as recommended". Questions
already confirmed in Pass 1 that have not changed do not need
re-confirmation — only new or revised ones get walked through.

The close-out message (whether questions were walked through or there were
none) must include the plan file path so the user does not have to scroll
back through session history:

> "Pass 2 complete. [Tally of new/revised questions confirmed, if any.]
> Clear context and come back for Pass 3 (quality gates) when ready.
>
> **Plan file:** `plans/YYYY-MM-DD-N-plan-<slug>.md`"

If there are no open questions, use the same close-out format with "No
open questions." in place of the tally.

## Reminders (critical, repeated for forefront)

- **Extend, don't rewrite.** Passes 2 and 3 build on the Pass 1 base.
  Wholesale restructuring requires explicit user approval.
- **Do not execute during planning.** Pass 2 is analysis only.
- **Never add to the plan without adding to the Review Log.** Every
  change after Pass 1 must be traceable.
