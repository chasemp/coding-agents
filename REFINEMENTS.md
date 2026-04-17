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

## 2026-04-17: Verbal batched proposals should persist to plans/

**Observed pattern:** A long multi-session thread accumulated 18
commits' worth of meaningful changes (new agent, 3 skills, 3
commands, 2 ledgers, phase-plan split, escalation unification, doc
impact enforcement, one-plan clarification) without a single file
in `plans/` being written for the session itself. Each batch was a
functional plan — problem statement ("escalation defined but
unused"), proposed solution (list of specific edits), reasoning
("pair with orthogonal workflow"). User approved via "let's do all
that" and work proceeded. The rationale survived in commit messages
and `REFINEMENTS.md` entries but never as one cohesive plan doc.

**Evidence:**
- 2026-04-16 and 2026-04-17 commits `cc13767` through `a444ad8` —
  all substantive, all directed by verbal proposals approved in
  conversation, none preceded by a `plans/` file.
- User statement 2026-04-17: "we made a plan here without phase
  plan, although this is maybe just barely at that threshold."
- `phase-plan` trigger didn't fire because each turn's increment
  felt small — it was the session-level accumulation that crossed
  the threshold.

**Proposed refinement:** One of these three shapes (user to pick,
or reject all three as over-engineering).
- **A. Trigger-language tweak.** Extend `phase-plan` description:
  "…or when an approved batched proposal in conversation would
  touch 3+ files, new files, or skill/agent/command definitions —
  persist the proposal to `plans/` before executing, even if
  short." Lightest touch; no new skill.
- **B. New skill `persist-verbal-plan`.** Auto-trigger when Claude
  is about to begin executing a batched change approved in
  conversation and the batch crosses a threshold (3+ files, new
  files, or configuration-of-Claude-Code changes). Writes a short
  plan doc to `plans/` capturing the verbal proposal before the
  first edit. Small, focused, complements `plan-doc-reasoning`.
- **C. Park it.** One strike only (this session); the pattern may
  not recur if individual users pace differently. Revisit if a
  second session replays the same shape.

**Rationale:** Rationale survived this session via commit messages
and the ledgers, so no knowledge was lost — but future-us reading
`git log` to reconstruct "why did external-learn get a ledger in
addition to REFINEMENTS.md" will find the answer scattered across
four commits and two entries instead of one plan doc. The plan doc
is the artifact whose absence we would not immediately feel but
would regret in three months.

**Status:** proposed

**Notes:** User's framing — "this is maybe just barely at that
threshold" — suggests the refinement should be conservative. Option
A (trigger tweak) is my lean; Option B if A proves insufficient
after another strike. Meta-observation: this session's work itself
is the kind of thing the new `Documentation Impact` requirement
would have caught at plan time (we had to update README, agents.md,
CLAUDE.md repeatedly as reactive patches).

## 2026-04-17: Documentation Impact in phased plans + one-plan clarification

**Observed pattern:** Recent multi-session work adding skills
(`ask-questions-if-underspecified`, `plan-doc-reasoning`,
`claude-code-docs`), a new agent (`external-learn`), two ledgers
(`REFINEMENTS.md`, `EXTERNAL-LEARNINGS.md`), and a command (`/audit`)
required doc updates to `README.md`, `agents.md`, CLAUDE.md, and
cross-references across multiple skills. Those updates happened —
but reactively, when the user or `/audit` caught drift, not
proactively as part of the plan's phase items. User flagged: "docs
are getting crusty." Separate issue in the same session: an agent
using the skill attempted to create per-pass plan files
(`plans/foo-pass1.md`) because `skills/phase-plan/pass{1,2,3}.md`
exists and the relationship wasn't explicit.

**Evidence:**
- Multiple commits from 2026-04-16 where `agents.md` had to be
  updated after-the-fact (learn role update, REFINEMENTS.md add,
  external-learn add, EXTERNAL-LEARNINGS.md add, /audit add).
- User statement 2026-04-17: "we're not incorporating refining
  documentation in our plans already and we need to be."
- User statement 2026-04-17: "I had an agent trying to use the skill
  get confused on whether there were per pass individual plan files."

**Proposed refinement:** Two related additions to `phase-plan`.

Documentation Impact (five edits):
1. Plan doc template gets a required `Documentation Impact` section
   between `Verified Assumptions` and `Phases`.
2. Pass 1 gains a new step 7 ("Inventory documentation impact")
   between "Draft phases" and "Size phases"; steps 7–9 renumbered
   to 8–10.
3. Pass 3 gains a new Check 7 ("Documentation impact coverage")
   and a "Documentation impact" line in the Review Log format.
4. Execute checklist gains a "Documentation updates scheduled for
   this phase are done" item.
5. Main file gets a TRACKING block dated 2026-04-17.

One-plan clarification (three edits):
1. Main file gets a new `## One plan, three passes` section
   immediately before `## Loading the Per-Pass Files`, explicitly
   stating that the plan is a single file and that the per-pass
   skill files are instructions, not plan templates.
2. Each per-pass file (`pass1.md`, `pass2.md`, `pass3.md`) gets a
   "Not a plan template" banner under the existing loading note,
   telling readers not to create per-pass plan files.
3. TRACKING block includes the clarification context.

**Rationale:** The doc-impact addition mirrors the wiring-test fix —
work belongs in the phase that triggers its need, not a later
cleanup phase that gets skipped when time pressure hits. It
complements `docs-guardian` (advisory at PR time) by catching doc
impact at plan time when it's cheapest to schedule correctly. The
one-plan clarification closes a real confusion mode observed in a
user's session.

**Status:** accepted

**Notes:** Applied 2026-04-17. Files changed:
- `skills/phase-plan.md` (template `Documentation Impact` section +
  `One plan, three passes` section + TRACKING block)
- `skills/phase-plan/pass1.md` (step 7 added, step renumbering,
  banner)
- `skills/phase-plan/pass2.md` (banner only)
- `skills/phase-plan/pass3.md` (Check 7 + Review Log row + banner)
- `skills/phase-plan/execute.md` (Phase completion checklist item)

## 2026-04-16: Plan docs must record Problem/Approach/Reasoning

**Observed pattern:** Plans created outside `phase-plan`'s three-pass
flow frequently shipped without persisted reasoning — change lists
with no trace of WHY the change was proposed. The user reported
having to remind about this repeatedly in-session. `phase-plan`'s
template already enforces this for its own flow, but nothing
generalized the rule to ad-hoc plans, review reports, or interim
drafts written directly to `plans/`.

**Evidence:**
- User statement 2026-04-16: "let's ensure we have solid direction
  on persisting the problem statements, proposed solution, and
  rationale to our plan files… I feel like I have to remind on
  that a lot"
- Session survey: `plans/xml-tag-enhancement.md` follows phase-plan
  format (Problem Statement + Reasoning); `plans/external-learn-
  ask-questions-if-underspecified.md` uses external-learn's review
  format (Source Summary + per-candidate Rationale). Both comply by
  their respective template — but no rule forces compliance for
  plans outside those templates.

**Proposed refinement:**
- **Target:** three layers, mirroring the TDD three-tier enforcement
  pattern
- **Change:**
  - `CLAUDE.md` Development Workflow — added rule that plans in
    `plans/` must carry Problem Statement, Approach, and Reasoning,
    format flexible but presence required.
  - New skill `skills/plan-doc-reasoning.md` — auto-triggers when
    writing/editing `plans/*.md`. Prescribes the three required
    elements in any format. Notes that phase-plan/external-learn/ADR
    templates already satisfy the floor.
  - `commands/audit.md` Check 7 — advisory scan of `plans/*.md` for
    reasoning-related headings. Flags plans with no heading matching
    the expected vocabulary (Problem / Reasoning / Rationale / Why
    this / Source Summary / Context / Decision / Approach).
- **Rationale:** Single-layer reinforcement (just the rule in
  CLAUDE.md) has not been enough — user reported repeated reminders.
  Mirroring the TDD three-tier pattern (always-loaded rule + on-write
  skill + periodic audit check) provides enough redundancy that
  forgetting becomes unlikely. "Load-bearing repetition" is the
  designed-in insurance.

**Status:** accepted

**Notes:** Applied 2026-04-16. Files changed: `CLAUDE.md` (added bullet
in Development Workflow § Quick reference), `skills/plan-doc-reasoning.md`
(new ~90-line skill), `commands/audit.md` (added Check 7). Check 7
passes on both current `plans/*.md` files — `xml-tag-enhancement.md`
has "Problem Statement" and "Reasoning" headings; `external-learn-
ask-questions-if-underspecified.md` has "Source Summary" heading.

## 2026-04-16: /audit Scope B — consumer project .claude/ audit

**Observed pattern:** The `/audit` command lands in this repo as
Scope A (audits this repo's own skills, agents, commands, and
cross-references). A consumer project (e.g., clauditor) can also have
project-local skills and commands in its own `.claude/` directory.
Those have the same drift risk but are out of scope for the current
audit implementation.

**Evidence:**
- `/audit` command built 2026-04-16 for Scope A only
- User flagged Scope B as a deferred todo in the same session

**Proposed refinement:**
- **Target:** extend `commands/audit.md`
- **Change:** Detect the working directory. If running inside
  `~/.claude/coding-agents/` (or a symlink to it), run Scope A as
  today. Otherwise, run Scope B: audit the consumer project's
  `.claude/commands/` and any project-local skills. Scope B's check
  set is a subset of Scope A — no cross-refs to our `skills/`, no
  root-level agent checks, just the project-local artifacts.
- **Rationale:** Consumer projects accumulate the same drift. One
  command, two modes is cleaner than two commands.

**Status:** parked

**Notes:** Deferred to a future session. Revisit when a consumer
project has accumulated enough local `.claude/` content to make the
audit worth running.

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

**Status:** accepted

**Notes:** Applied 2026-04-16. Extended `skills/skill-hygiene.md`
§ Incorporating External Ideas step 4 to require attribution in both
the file and the commit message. Extended `external-learn.md` Quality
Gates with a matching requirement for `adopt` / `adopt with adaptation`
candidates. Concrete example of the target pattern is
`skills/ask-questions-if-underspecified.md` (created 2026-04-16,
commit `aa7499d`).

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

**Status:** accepted

**Notes:** Applied 2026-04-16. Restructured `skills/skill-hygiene.md`
§ Deduplication Rules: split the prior "Exception:" step out into a
new "Named exceptions to the deduplication rule" subsection with two
items — Operational restatement (existing) and Load-bearing repetition
(new). The phase-plan split is named as the canonical example of the
latter.

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
