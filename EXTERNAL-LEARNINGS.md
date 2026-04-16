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
