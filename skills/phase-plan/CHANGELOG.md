# Phase Plan — Changelog

History of the `phase-plan` skill, moved out of the main file's TRACKING comments on 2026-11-12 so
the always-loaded file stays small. Oldest first, as written at the time; names of other projects
made generic. The main file keeps one block, `TRACKING: File split (2026-04-16)`, which
`/audit` Check 6 and `skills/skill-hygiene.md` name.

## Wiring gap issue (2026-04-07)

Recurring problem: phases build isolated components with passing unit tests
but fail to wire them into the entry point. All tests green, feature doesn't
work. Added: Wiring test field, entry-point verification requirements,
Isolation Trap anti-pattern section (now in phase-plan/execute.md). Monitor
whether these changes actually prevent the failure mode in practice. If it
recurs, the next step is a programmatic hook that checks for entry-point
test coverage at phase boundary.

## Discovery + Validation additions (2026-04-10)

Two additions: (1) Phase 0 Discovery for validating assumptions before
committing to implementation — triggered when unknowns exist. (2) Per-phase
Validation field calibrated to scope — tests are the floor, not the ceiling.
Also added: Combined Pass 1+2 usage pattern, Phase 0 execution rules,
validation calibration as Pass 3 quality gate. Monitor whether Phase 0
catches assumption errors that would have caused mid-execution rework,
and whether validation strategies are actually calibrated vs defaulting
to "tests are sufficient" for everything.

## Discovery exemption + plans dir + walk-through (2026-04-16)

Three additions: (1) Promoted the Phase 0 "no TDD" rule to a named
Discovery Exemption with explicit scope, bounded to discovery work only.
Added per-task Disposition field (throwaway / keep-as-fixture / promote)
to resolve the hybrid case where spike code becomes production code.
Context: observed in an evaluation-dataset plan in another repo, where the D1
spike produced disposable code alongside reflexive TDD tests — the
skill's "no TDD in Phase 0" signal was too weak to override the TDD
instinct. (2) Prescribed plans/ as the default location for plan docs,
with directory auto-creation; fall back to existing project convention
(e.g., docs/) if one is established. (3) Made one-at-a-time walk-through
the default for confirming open-question severities at the end of each
pass (previously a bulk listing). Brief listing first, then each
question presented individually with a confirm/override prompt. User
can opt out with "accept all as recommended" — default changed because
bulk listings let the user skim past questions that deserve a real
decision. Monitor: (a) whether the Discovery Exemption neutralizes the
TDD-instinct override during Phase 0 execution, or whether spikes
continue to accumulate tests by reflex; (b) whether the walk-through
surfaces severity overrides that would have been missed by the bulk
listing, or whether users reflexively opt out. If the exemption isn't
holding, escalate to a programmatic check.

## Plan filename convention (2026-04-16)

Changed the default plan doc filename from `plans/<kebab-name>.md` to
`plans/YYYY-MM-DD-N-plan-<slug>.md`. Rationale: chronological sort by
name (dates ascending, ordinals ascending within a day), an
unambiguous "plan" marker so files read as plans out of context, and
collision-free naming when multiple plans land on the same day. The
ordinal is always present (not just on collisions) so sort order
stays stable retroactively when a second plan lands that day.
Triggered by a rename pass over an existing `plans/` tree where
~50 files had mixed conventions (`plan-X.md`, `X-plan.md`, no
marker) and no temporal ordering — the new convention solves both.
Monitor: (a) whether agents remember the ordinal on day-1 plans
(likely failure mode: they drop it when there's no collision yet),
(b) whether the convention survives contact with projects that
already have a plan directory with a different scheme, (c) whether
days ever exceed 9 plans and force the zero-padding fallback. If
the ordinal rule is forgotten, escalate to a Write-tool guard that
validates the filename pattern before creating the file.

## Documentation Impact + One-plan clarification (2026-04-17)

Two related additions. (1) Added a Documentation Impact required
section to the plan doc template plus a Pass 1 inventory step and
Pass 3 coverage check. Context: recent multi-session work on this
repo (new skills, new agent, two ledgers) required doc updates to
README.md, agents.md, and cross-references in multiple files — and
those updates happened reactively when audit or the user caught
drift, not proactively in phase items. User flagged: "docs are
getting crusty." Mirrors the wiring-test fix — work belongs in the
phase that triggers its need, not a later cleanup phase that gets
skipped. (2) Added "One plan, three passes" clarification section
plus banners on each per-pass skill file. Context: an agent using
the skill tried to create per-pass plan files (plans/foo-pass1.md
style) because the skill dir has pass1.md/pass2.md/pass3.md and
the relationship wasn't explicit. Monitor: (a) whether plans
actually populate Documentation Impact with real content vs
rubber-stamping "no impact," and (b) whether the clarification
holds up — if agents still try to create per-pass plan files,
escalate to a Write-tool guard that rejects them.

## Concurrency planning + isolation invariants (2026-05-04)

Added: per-phase Read-set / Write-set / Shared-state contract /
Re-entry verification fields, top-level Concurrency Map section,
Pass 1 derivation step, Pass 2 disjointness check, Pass 3 isolation-
honesty check, execute.md parallel dispatch protocol with pre/post
snapshot of shared state and an Isolation Trampling anti-pattern.
Triggered by two failure modes observed in practice: (a) plans
default to sequential phases even when work is embarrassingly
parallel — no mechanism currently surfaces parallelizable subgraphs,
so concurrency is left on the table; (b) "trampling" incidents where
a supposedly worktree-isolated agent leaked state into the main repo
(e.g., a `git checkout` in the wrong worktree moved HEAD on the
parent), because the only declared isolation surface was the file
system. Files-only write-sets miss this — git HEAD, env vars,
working directory, ports, daemons, and other ambient state must be
declared explicitly, and re-entry verification must check them.
Monitor: (a) whether plans actually populate write-sets and shared-
state contracts vs leaving them empty or hand-waving "no shared
state"; (b) whether re-entry verification catches isolation leaks
proactively, or only after they cause confusion downstream; (c)
whether parallel dispatch shows up in execute.md runs at all, or
whether the sequential default holds even when the Concurrency Map
declares parallelism is safe. If write-sets are reflexively left
empty, escalate to a programmatic check that refuses to advance
past Pass 2 without them.
