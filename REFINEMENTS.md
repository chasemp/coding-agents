# Refinements Ledger

Global ledger of observed patterns and proposed refinements to this
coding-agents repo. Maintained by the `learn` agent; reviewed and acted
on by the user.

**Not to be confused with `LEARNINGS.md`** in consumer projects (managed
by progress-guardian for per-feature project learnings). This ledger
targets refinements to this repo's own skills, agents, and commands.

## Entry format

```markdown
## YYYY-MM-DD: <short title>

**Observed pattern:** <what keeps recurring — one or two sentences>

**Evidence:**
- <first observation — session, project, file:line if applicable>
- <second observation — the one that promotes it past two-strike>

**Proposed refinement:**
- **Target:** <new skill X | extend skill Y | new agent Z | extend agent W | command | park>
- **Change:** <specific edit or addition — name files, sections>
- **Rationale:** <why this prevents the pattern from recurring>

**Status:** proposed | accepted | rejected | parked

**Notes:** <follow-ups, decisions — updated as the user acts on the proposal>
```

## Status lifecycle

- **proposed** — created by `learn`, awaiting user review.
- **accepted** — user applied the refinement. Record file(s) changed in Notes.
- **rejected** — user declined. Record the reason so it isn't re-proposed.
- **parked** — valid but deferred. Revisit if the pattern continues.

---

## Entries

<!-- New entries added below in reverse-chronological order (newest first). -->

## 2026-04-16: Inline source attribution in adopted skill files

**Observed pattern:** When adopting content from an external source,
`skill-hygiene.md:164` prescribes `Source: <url>` in the commit message.
That dies in git history — a reader opening the skill file five months
later has no way to trace its origin without running `git blame` on
every line. In the trailofbits adoption this session, I additionally
put a paragraph at the top of the adopted skill with the upstream
link, the reviewed commit SHA, and a pointer to the review report —
the user flagged this as worth codifying.

**Evidence:**
- `skills/ask-questions-if-underspecified.md` adopted 2026-04-16
  includes an explicit "Source attribution" paragraph near the top
- User request at end of that session: "If you want the 'source
  attribution in adopted skills' pattern codified, that'd be a quick
  addition to external-learn.md's output instructions."

**Proposed refinement:**
- **Target:** extend both `skill-hygiene.md` § Incorporating External
  Ideas and `external-learn.md` output rules
- **Change:**
  - `skill-hygiene.md` step 4 ("Add provenance") — change from
    "in the commit message, include `Source: <url>`" to "in the
    adopted file itself, include a short paragraph near the top
    with upstream link, reviewed commit SHA, and pointer to the
    external-learn review report; also include `Source: <url>` in
    the commit message."
  - `external-learn.md` Quality Gates — add: "Every `adopt` or
    `adopt with adaptation` proposal includes an inline attribution
    paragraph in the target file, not just in the commit message."
- **Rationale:** File-local attribution survives git history drift and
  gives future readers (and `external-learn` itself) an anchor for
  tracking upstream changes. Commit-message-only attribution fails on
  both counts.

**Status:** proposed

**Notes:** Concrete example of the target pattern: the source
attribution paragraph in `skills/ask-questions-if-underspecified.md`
(created 2026-04-16, commit `aa7499d`).

## 2026-04-16: Load-bearing redundancy exception to DRY

**Observed pattern:** `skill-hygiene.md` § Deduplication Rules
(line 84) has an operational-restatement exception: "agents may
restate a principle in operational terms if the restatement adds
enforcement-specific value." That is one kind of justified
repetition. A different kind came up during the phase-plan split:
critical rules ("no stubs", "commit per phase", "wiring tests
required") are intentionally repeated across the main file and each
per-pass/execute file not for enforcement framing but because
forgetting them mid-execution is the primary failure mode we are
guarding against.

**Evidence:**
- Phase-plan split (2026-04-16): critical execution rules repeated
  verbatim across `phase-plan.md`, `phase-plan/execute.md`, and
  pass files, with a TRACKING comment documenting that redundancy
  is load-bearing
- User statement during the split discussion: "redundancy is ok in
  some cases, it keeps it forefront, we have a lot of issues with
  skipping or not following plans to completion"

**Proposed refinement:**
- **Target:** extend `skills/skill-hygiene.md` § Deduplication Rules
- **Change:** Add a second named exception to the existing exception
  list: "**Load-bearing repetition** — critical rules that are
  frequently skipped (e.g., 'no stubs', 'commit per phase', wiring
  requirements) may be repeated verbatim across files where they
  apply, because forgetting them is the primary failure mode. The
  redundancy is intentional. Mark it with a TRACKING comment so
  future refactors don't collapse it as DRY violation."
- **Rationale:** Without this exception, a future hygiene pass could
  collapse the load-bearing repetition in phase-plan's split files
  back into a single source — which would undo the split's whole
  purpose. Making the exception explicit prevents the regression.

**Status:** proposed

**Notes:** The phase-plan TRACKING comment at 2026-04-16 already
documents this decision locally. This proposal promotes it to a
general hygiene principle.

## 2026-04-16: Cross-reference ask-questions-if-underspecified from phase-plan Pass 1

**Observed pattern:** Phase-plan Pass 1 step 1 says to ask clarifying
questions but doesn't distinguish "request is ambiguous" (interpretation)
from "planning needs unknowns resolved" (detail). Without a pointer,
readers may think phase-plan is the only clarification skill.

**Evidence:**
- Review of trailofbits external skill surfaced the distinction
  (2026-04-16)

**Proposed refinement:**
- **Target:** extend `skills/phase-plan/pass1.md` § Steps, step 1
- **Change:** Added a pointer: "If the request itself is ambiguous
  (multiple plausible interpretations), use the
  `ask-questions-if-underspecified` skill first — it uses a lighter
  multiple-choice format better suited to resolving interpretation
  before planning engages."
- **Rationale:** Clarifies the separation of concerns: underspec skill
  resolves interpretation, phase-plan resolves planning detail.

**Status:** accepted

**Notes:** Applied 2026-04-16 in `skills/phase-plan/pass1.md` (step 1).
Depends on the ask-questions-if-underspecified proposal below, accepted
in the same session. Source review in
`plans/external-learn-ask-questions-if-underspecified.md`.

## 2026-04-16: Adopt ask-questions-if-underspecified as new skill

**Observed pattern:** Ambiguous short-scope requests — ones that don't
warrant phase-plan but still have 2+ plausible interpretations — rely
on Claude's judgment with no skill-level backing. This leads to
starting work in the wrong direction and backfilling questions mid-work.

**Evidence:**
- External source: trailofbits/skills plugin
  `ask-questions-if-underspecified` (commit `9f7f8ad`, 2026-02-18)
- Gap confirmed: no existing skill fires before phase-plan on
  ambiguous requests

**Proposed refinement:**
- **Target:** new skill `skills/ask-questions-if-underspecified.md`
- **Change:** Created a light-weight skill adapting the trailofbits
  skill. Kept the 6-axis checklist (objective / done / scope /
  constraints / environment / safety), the multiple-choice + defaults
  question format with `defaults` fast-path and compact reply syntax,
  the "pause before acting" rule, and the "ask vs look up"
  anti-pattern. Adapted voice to match our style. Added explicit
  hand-off rules to `phase-plan` when scope turns out non-trivial.
- **Rationale:** Closes the gap between "casual request" and
  "phase-plan triggers." Prevents Claude from starting work on the
  wrong interpretation.

**Status:** accepted

**Notes:** Applied 2026-04-16. New file:
`skills/ask-questions-if-underspecified.md` (~135 lines). Source
attribution included in the skill (link to upstream plugin, reviewed
commit SHA, pointer to review report). Review details in
`plans/external-learn-ask-questions-if-underspecified.md`.
