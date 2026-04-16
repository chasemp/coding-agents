# External Learnings Ledger

Running ledger of external skills, agents, plugins, and other Claude Code
content we have reviewed — with references, takeaways, and what we
adopted or rejected. Maintained by the `external-learn` agent.

**Relationship to other ledgers:**
- `REFINEMENTS.md` — individual refinement proposals (what might change
  in our repo). Managed by `learn`.
- `EXTERNAL-LEARNINGS.md` (this file) — external sources we've studied
  (what influenced us). A single entry here may spawn zero, one, or many
  `REFINEMENTS.md` entries.
- The review reports in `plans/external-learn-<name>.md` hold the full
  comparison analysis. Entries here are summaries with pointers.

## Why keep this ledger

- **Avoid re-reviewing the same source.** If a skill was already compared
  and rejected as redundant, a future session should recognize that
  quickly rather than re-running the analysis.
- **Track upstream drift.** If an external source was reviewed at commit
  X and later substantially changes, it may be worth re-reviewing.
- **Show influences.** Over time, we can see which ecosystems have
  shaped this repo and where — useful when answering "why do we do X
  this way?"

## Entry format

```markdown
## YYYY-MM-DD: <source name>

**Source type:** file | URL | plugin | raw content | multi-source batch
**Reference:** <URL, file path, plugin identifier>
**Upstream (if git):** <repo URL, branch, commit SHA reviewed — when known>
**Reviewed version:** <version tag, release name, or "HEAD as of YYYY-MM-DD">
**Review report:** `plans/external-learn-<name>.md`
**Author / publisher:** <individual, org, project — when known>

**Source summary:** <one to two sentences on what the source does, in
the author's framing>

**Takeaways:**
- **Adopted:** <what we accepted as-is, with pointers to where it
  landed in our repo>
- **Adapted:** <what we accepted with changes (reworded, re-scoped)>
- **Extended:** <what extended an existing skill/agent, naming the target>

**Rejected:**
- <pattern name> — <reason> (record so the same pattern from a different
  source can be recognized faster)

**Status:** reviewed | partially adopted | fully adopted | rejected | parked

**Follow-ups:**
- <action items not yet adopted but worth revisiting>
- <if upstream is active, note when to re-check for changes>
```

## Status lifecycle

- **reviewed** — written when external-learn completes the review, before
  any adoption action.
- **partially adopted** — user accepted some proposals; see `REFINEMENTS.md`
  entries linked in Follow-ups.
- **fully adopted** — every proposal from this source was accepted.
- **rejected** — nothing from this source was adopted. Reason(s) recorded
  under Rejected.
- **parked** — review is complete, decision deferred.

---

## Entries

<!-- New entries added below in reverse-chronological order (newest first). -->

## 2026-04-16: ask-questions-if-underspecified (trailofbits/skills)

**Source type:** URL (GitHub directory)
**Reference:** https://github.com/trailofbits/skills/tree/main/plugins/ask-questions-if-underspecified
**Upstream (if git):** `github.com/trailofbits/skills`, branch `main`, last commit touching path `9f7f8ad` (2026-02-18)
**Reviewed version:** HEAD as of 2026-04-16
**Review report:** `plans/external-learn-ask-questions-if-underspecified.md`
**Author / publisher:** Kevin Valerio (skill author), Trail of Bits (publisher)

**Source summary:** Single-skill plugin that fires when a request has
multiple plausible interpretations or unclear details (objective / done
/ scope / constraints / environment / safety). Prescribes 1–5 must-have
questions in a compact multiple-choice format with defaults and a
fast-path reply, followed by a restatement of confirmed requirements
before work starts. Includes a "pause before acting" rule and an
anti-pattern against asking what a discovery read could answer.

**Takeaways:**
- **Adopted:** New skill created at `skills/ask-questions-if-underspecified.md`
  absorbing:
  - Overall "ask before implementing when underspecified" concept
  - 6-axis underspecified checklist (objective / done / scope / constraints / environment / safety)
  - Multiple-choice + defaults question format with `defaults` fast-path and compact reply (`1a 2b`)
  - "Pause before acting" rule until must-have answers arrive
  - "Ask vs look up" anti-pattern (don't ask questions a quick discovery read can answer)
  - Question templates adapted to our voice
- **Adapted:** Voice rewritten throughout; added explicit hand-off rules
  to `phase-plan` for when scope turns out non-trivial; source
  attribution included in skill frontmatter paragraph.
- **Extended:** Added cross-reference from `skills/phase-plan/pass1.md` step 1 so
  readers see the interpretation-vs-detail distinction.

**Rejected:**
- None this round. Every pattern in the source had adoption value at some scope.

**Status:** fully adopted

**Follow-ups:**
- Both `REFINEMENTS.md` entries accepted in-session (skill created,
  phase-plan cross-reference applied).
- Upstream repo is active; re-check in ~3 months for iterations.
- Parked question from the review: should phase-plan's walk-through also gain a "defaults" fast-path? Revisit after the underspec skill sees real use.
