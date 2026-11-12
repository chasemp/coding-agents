# Phase Plan — Pass 2: Independent Review

> Loaded on demand by the `phase-plan` skill when the user invokes Pass 2. Assumes the main `phase-plan.md`
> skill is already loaded.
>
> **Not a plan template.** This file is the `phase-plan` skill's
> instructions for Pass 2. The plan doc itself is a single file (see
> `phase-plan.md` § One plan, three passes) — Pass 2 extends that same
> file with an independent review. Do not create `plans/foo-pass2.md` or any
> other per-pass plan file.

**Goal:** Reviewers who did not write the plan try to refute it, each along one fixed lens. The main session
re-checks every claim before folding it in. Fresh re-runs of the author's own checklist find about half as
much; the gain comes from stance and authorship, so this pass is defined by those.

**Trigger:** "pass 2", "independent review", "review the plan", "plan review". Runs on every full plan;
skipped for a quick plan. The user's own freeform review stays available after it.

## Before starting

- Use a fresh context. A compacted context is not fresh: say so and hand off (`pass1.md` § Next pass handoff).
- The plan's Review Log must have a gap-analysis entry. If it has none, run `pass1.md` § Gap-analysis step
  first.
- Read the plan end to end, starting from the previous pass's additions.

## Lenses

Three fixed lenses, one reviewer each. A fixed set is easier to audit than planner-chosen lenses.

### Lens A: outcome and failure walk

Start from the first real run and trace backward from its observable result: what the user sees, which
records exist afterwards, what runs next and when. Then walk the failures: an abort midway, a partial batch, a
retry, a rerun of the whole job, a record closed because something was not found, and rollback of data
already written. For each, does the plan say what happens and how anyone would notice?

### Lens B: outward consistency

Everything outside the plan that it must agree with: sibling systems that do the same job, in-flight plans,
PRs and worktrees, and numbers, labels or wording already shown on existing surfaces (reports, dashboards,
docs) that the change would contradict.

### Lens C: facts against code and live data

Every factual claim in Verified Assumptions, Reasoning and the phase specs, checked against the files and,
read-only, against live data: cited lines opened, counts re-measured, value domains read, commands run.

## Reviewer brief

Build each brief from the plan's Next pass section, so a reviewer needs nothing from this conversation. Each
brief names:

```
Plan: <absolute path to the plan>        Repo(s): <absolute paths>        Base: <commit, how to re-check>
Lens: <A, B or C> — <the lens text above>
Look at: <files, data sources, sibling systems this lens needs>
Rules: read-only. No edits, no writes, no commits; probes follow pass1.md § Probe rules.
Stance: Refute first. The plan's text is not evidence; a claim holds only if you checked it.
Grade each finding: BLOCKER (the plan fails or does harm as written) / REVISE (a gap or error with a
  fix) / CONFIRMED (you tried to break it and it held). Evidence for each: file:line, or command + output.
Output: findings as a numbered list, most severe first, each with grade, evidence and the fix you would make;
  then what you checked and found sound. Under 800 words.
```

## Running the reviewers

- Three Agent calls in **one message**, one per lens, so they run concurrently. A `general-purpose` agent is
  fine; reviewers do not edit.
- **pass `model` explicitly** on every call, set to the session's own model. An agent definition's pinned
  model would otherwise win.
- Use absolute paths in briefs. A per-pass file path given relative to a repo resolves against whatever the
  reviewer's working directory happens to be.

## Vetting

The main session re-checks every claim against the files before folding it in, starting with BLOCKERs. A
reviewer's finding arrives in the same confident register whether or not it is right.

- Merge duplicates across lenses; keep the strongest evidence.
- A finding that does not hold is dropped and named as dropped in the Review Log.
- One correct fix: apply it and log it. A finding that needs the user: walk it per `walk-through.md` (a
  BLOCKER that needs a decision becomes a BLOCKING question).
- Replace superseded planning text in place; history lives in the Review Log.

Review Log entry:

```markdown
### Pass 2: Independent review — [date]
Reviewers: [agent type, model passed], one per lens. Raw totals: A [B/R/C], B [B/R/C], C [B/R/C].
**Found (merged):**
- [finding, lens, re-checked how]
**Dropped:**
- [finding that did not hold, and why]
**Changed:**
- [what was applied, where]
**Confirmed:**
- [what held up]
```

## When to re-run

A late change (a walk-through answer that adds design, an addendum, a new phase, a scope expansion, a pass's
own fixes) always gets the gap-analysis step and Pass 3 on the changed part. Pass 2 also re-runs, scoped to
the changed part, when the change adds a phase, a new interaction with an external system, or a new write
path.

## Output

Walk the decisions per `walk-through.md`, then write the plan's Next pass section
per `pass1.md` § Next pass handoff, and close:

> "Pass 2 complete. [Findings folded in; decisions recorded; decided-by-agent items for override.] Next:
> Pass 3 (quality gates) in a fresh session; the paste is in the plan's Next pass section.
>
> **Plan file:** `plans/YYYY-MM-DD-N-plan-<slug>.md`"

## Reminders (critical, repeated for forefront)

- **Re-check before folding in.** No reviewer claim enters the plan unverified.
- **Do not execute during planning.** Pass 2 is analysis only; reviewers are read-only.
- **Never add to the plan without adding to the Review Log.** Every
  change after Pass 1 must be traceable.
