# External Learn Review: ask-questions-if-underspecified (trailofbits/skills)

**Source:** https://github.com/trailofbits/skills/tree/main/plugins/ask-questions-if-underspecified
**Upstream:** github.com/trailofbits/skills, branch `main`, last commit touching this path `9f7f8ad` (2026-02-18) by Dan Guido
**Reviewed:** 2026-04-16
**Summary verdict:** Adopt as a new skill (`ask-questions-if-underspecified`) with adaptation. Light-weight front-door that complements `phase-plan` — triggers earlier, on any ambiguous request, before the three-pass planning workflow engages. Five of six candidate patterns are adoption-worthy with moderate re-voicing; one extension to `phase-plan` Pass 1 should cross-reference it.

## Source Summary

Single-skill plugin from Trail of Bits, authored by Kevin Valerio. The skill
fires when a request has multiple plausible interpretations or when key
details (objective, done, scope, constraints, environment, safety) are
unclear. It prescribes asking **1–5 must-have questions** in a compact,
multiple-choice format with defaults, a fast-path `defaults` reply, and a
restatement of confirmed requirements before work starts. It also asserts
a "pause before acting" rule and an anti-pattern against asking questions
that a quick discovery read would answer.

## Our Current Coverage

- `skills/phase-plan.md` + `skills/phase-plan/pass1.md` — Pass 1 step 1 says
  "Ask clarifying questions — do not assume." Open Questions section with
  BLOCKING / PHASE-GATED / ADVISORY severities, confirmed via the
  walk-through procedure at the end of each pass.
- `CLAUDE.md` § External APIs — "never guess or infer API endpoints,
  payload shapes, or field names." Narrow to external-API ambiguity.
- `CLAUDE.md` § Working with Claude — "capture gotchas, patterns,
  decisions" (different axis).
- `CLAUDE.md` § Development Workflow — "Bail on repeated failure" (after
  something is already happening, not before).

**Gap:** No skill fires on a casual request that turns out to be
ambiguous *before* `phase-plan` is invoked. Phase-plan triggers on
"non-trivial changes that benefit from structured reasoning" — it does
not fire on a five-line fix-it request that happens to have two
interpretations. Today, that case relies on Claude's judgment without
skill-level backing.

## Candidate-by-Candidate Analysis

### Candidate 1: The overall concept (ask before implementing when underspecified)

**External claim:** Ask the minimum set of clarifying questions needed to
avoid wrong work. Use when the request has multiple plausible
interpretations.

**Our current state:** Pass 1 step 1 of phase-plan covers this *inside*
the planning workflow. No equivalent for pre-planning, trivial-scope
work.

**Rating:** **adopt with adaptation** (as a new skill)

**Rationale:** The gap is real — not every ambiguous request warrants the
full three-pass ceremony, but most of them warrant a question. A
lightweight skill that fires earlier closes the gap without bloating
phase-plan.

**If adopting:** Create `skills/ask-questions-if-underspecified.md`
with adapted voice. Keep the skill narrow — it should yield to
`phase-plan` when the resulting scope turns out to be non-trivial
rather than trying to do phase-plan's job.

### Candidate 2: 6-axis checklist for "underspecified"

**External claim:** Treat a request as underspecified if any of
objective / done / scope / constraints / environment / safety is unclear.

**Our current state:** Phase-plan Pass 1's "What to ask the user" lists
constraints, blast radius, codebase familiarity — related but not the
same framing.

**Rating:** **adopt with adaptation**

**Rationale:** The 6-axis checklist is crisper and more portable than
our current prompts. Objective / done / scope / constraints /
environment / safety is a complete enough mental model to catch the
common omissions and the checklist form is easy to skim.

**If adopting:** Include verbatim (with small voice tweaks) in the new
skill's trigger section. Do *not* replace phase-plan's "What to ask the
user" — they serve different moments and different phases of
clarification.

### Candidate 3: Multiple-choice question format with defaults

**External claim:** Optimize for scannability. Numbered questions,
lettered options, bolded recommended defaults, compact reply format
like `1a 2b`, and a `defaults` fast-path.

**Our current state:** Phase-plan's walk-through presents one
question at a time with full rationale and severity override
(BLOCKING / PHASE-GATED / ADVISORY). Different problem shape — the
walk-through is for confirming severity on already-drafted questions.

**Rating:** **adopt with adaptation** (in the new skill)

**Rationale:** The multiple-choice + defaults format is a genuine UX win
when questions are independent and discrete. It fits the
"ask-questions-if-underspecified" use case perfectly: 1–5 quick gating
questions. It does *not* fit phase-plan's walk-through, where each
question has a severity call that benefits from full rationale.

**If adopting:** Include the format template in the new skill. Mark
clearly that phase-plan uses a different (walk-through) format, so
readers understand both are intentional.

**Tension to flag:** Our existing plan-stage clarification is
severity-based; theirs is option-based. A reader looking at both might
see inconsistency. Resolve by stating in the new skill: "once the
scope turns out to be non-trivial, phase-plan takes over and uses its
walk-through pattern instead."

### Candidate 4: "Pause before acting" rule

**External claim:** Until must-have answers arrive, do not run commands,
edit files, or produce a detailed plan that depends on unknowns. Low-risk
discovery reads are allowed if clearly labeled.

**Our current state:** CLAUDE.md has "Bail on repeated failure" and
"No completion claims without fresh evidence," but no explicit
"pause-before-starting-on-ambiguity" rule.

**Rating:** **adopt with adaptation**

**Rationale:** The "pause before acting" phrasing is load-bearing — it
prevents Claude from starting work and then backfilling questions when
things go sideways. It pairs naturally with the "ask vs look up"
distinction (Candidate 5).

**If adopting:** Include as a core principle in the new skill. Do not
add to CLAUDE.md — the lean v3.0 doesn't need another general
principle, and the skill-local framing is stronger.

### Candidate 5: "Discovery read vs asking" distinction

**External claim:** Don't ask questions you can answer with a quick,
low-risk discovery read (configs, existing patterns, docs). A labeled
discovery step is OK if it doesn't commit you to a direction.

**Our current state:** Phase-plan Pass 1 step 2 ("Ground the plan in
the codebase") is adjacent — read code before drafting phases. But it
is framed as grounding, not as a substitute for asking.

**Rating:** **adopt with adaptation**

**Rationale:** The "ask vs look up" framing is the right anti-pattern
to guard against. Without it, the new skill could cause over-asking
(questions that waste the user's time when a quick file read would do).

**If adopting:** Include as an anti-pattern section in the new skill.
Reference phase-plan's grounding step for the planning-stage
equivalent.

### Candidate 6: Question templates

**External claim:** Pre-built templates like "Before I start, I need:
(1)..., (2)..., (3).... If you don't care about (2), I will assume..."

**Our current state:** No ready-made templates at this level of
specificity.

**Rating:** **adopt with adaptation**

**Rationale:** Templates are cheap to include and they nudge the
question-writer toward concision. Worth keeping; low cost.

**If adopting:** Include two or three templates in the new skill, rewritten
in our voice. Don't copy verbatim — their templates are tuned for a
slightly different tone.

## Extension to Phase-Plan

**Target:** `skills/phase-plan/pass1.md` step 1 ("Understand the problem
space. Ask clarifying questions — do not assume.")

**Change:** Add a one-line cross-reference: "If the request itself is
ambiguous (multiple plausible interpretations), the
`ask-questions-if-underspecified` skill is the upstream front door —
resolve interpretation there first, then come back to Pass 1."

**Rationale:** Without this pointer, a reader of phase-plan might think
it's the only clarification skill. The cross-reference clarifies the
relationship.

## Proposals for REFINEMENTS.md

The user may copy any of these into `REFINEMENTS.md` once they decide
to act.

### Proposal 1: New skill `ask-questions-if-underspecified`

```markdown
## 2026-04-16: Adopt ask-questions-if-underspecified as new skill

**Observed pattern:** Ambiguous short-scope requests — ones that don't
warrant phase-plan but still have 2+ plausible interpretations — rely
on Claude's judgment with no skill-level backing. This leads to starting
work in the wrong direction and backfilling questions mid-work.

**Evidence:**
- External source: trailofbits/skills plugin
  `ask-questions-if-underspecified` (commit 9f7f8ad, 2026-02-18)
- Gap confirmed: no existing skill fires before phase-plan on
  ambiguous requests

**Proposed refinement:**
- **Target:** new skill `skills/ask-questions-if-underspecified.md`
- **Change:** Create a light-weight skill adapting the trailofbits
  skill. Keep the 6-axis checklist (objective / done / scope /
  constraints / environment / safety), the multiple-choice + defaults
  question format, the "pause before acting" rule, and the
  "ask vs look up" anti-pattern. Adapt voice to our style.
- **Rationale:** Closes the gap between "casual request" and
  "phase-plan triggers." Prevents Claude from starting work on the
  wrong interpretation.

**Status:** proposed

**Notes:** Source review in
`plans/external-learn-ask-questions-if-underspecified.md`.
```

### Proposal 2: Cross-reference from phase-plan Pass 1

```markdown
## 2026-04-16: Cross-reference ask-questions-if-underspecified from phase-plan Pass 1

**Observed pattern:** Phase-plan Pass 1 step 1 says to ask clarifying
questions but doesn't distinguish "request is ambiguous"
(interpretation) from "planning needs unknowns resolved" (detail).
Without a pointer, readers may think phase-plan is the only
clarification skill.

**Evidence:**
- Review of trailofbits external skill surfaced the distinction
  (2026-04-16)

**Proposed refinement:**
- **Target:** extend `skills/phase-plan/pass1.md` § Steps, step 1
- **Change:** Add a one-line pointer: "If the request itself is
  ambiguous (multiple plausible interpretations), use the
  `ask-questions-if-underspecified` skill first — it uses a lighter
  multiple-choice format better suited to resolving interpretation
  before planning."
- **Rationale:** Clarifies the separation of concerns: underspec skill
  resolves interpretation, phase-plan resolves planning detail.

**Status:** proposed (depends on Proposal 1 being accepted first)

**Notes:** Source review in
`plans/external-learn-ask-questions-if-underspecified.md`.
```

## Conflicts Worth Surfacing

None. Our severity-based walk-through (phase-plan) and the
multiple-choice-with-defaults format (external) serve different moments
and don't contradict each other. The new skill would occupy an earlier
point in the workflow.

## Open Questions

- **Do you want the new skill to be global (for all consumers of this
  repo) or project-scoped?** Default suggestion: global (lives in
  `skills/`), matching the other skills here.
- **Should the new skill have a memory flag?** It's a skill (not an
  agent), so it doesn't have persistent memory. No action needed unless
  we promote the pattern to an agent later.
- **Should phase-plan's walk-through also gain a "defaults" fast-path?**
  Potentially useful for experienced users, but phase-plan's questions
  are typically harder calls than the underspec skill's. My lean: leave
  phase-plan's walk-through as-is for now; revisit if the underspec
  skill's fast-path proves popular.
