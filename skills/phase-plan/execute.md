# Phase Plan — Execution

> Loaded on demand by the `phase-plan` skill when the user says "let's
> execute" after planning is complete. Assumes the main `phase-plan.md`
> skill is already loaded.

When the user says "let's execute" after Pass 3, these rules govern how
you work through the plan. **Read this whole file before starting
execution** — it contains the Discovery Exemption, the execution
reminder, Phase 0 guidance, the Executing Parallel Phases protocol
(snapshot, dispatch, re-entry verification, local consolidation), the
phase completion checklist, the plan-doc-sync rules, the mid-phase
check, the Isolation Trap anti-pattern, and the Isolation Trampling
anti-pattern.

**Scope:** The rules below govern implementation phases (Phase 1 and beyond).
Phase 0 Discovery follows the **Discovery Exemption** — read that section
before executing Phase 0.

---

## Discovery Exemption

Phase 0 discovery tasks produce knowledge, not production code. The following
implementation rules **do not apply** to discovery work:

- **No RED-GREEN-REFACTOR cycle.** Spike code answers a question; it does
  not need tests written first. Adding tests "because everything needs tests"
  defeats the purpose of a spike and is the anti-pattern this exemption
  exists to prevent.
- **No wiring test requirement.** The spike itself is the verification —
  did it answer the question with concrete evidence?
- **No commit-per-item rule.** Commit the findings summary when discovery
  is complete, not every probe iteration. Probe code may never be committed
  at all (see `throwaway` disposition).
- **No no-stubs rule.** Hardcoded paths, skipped edge cases, inline literals,
  and shortcuts are expected in spike code. The spike is a scaffold, not
  a product.

The following rules **still apply** during discovery:

- **Verified Assumptions must be updated with concrete evidence** — a docs
  link, `file:line` reference, command output, or probe response. Inference
  is not evidence.
- **Findings must be recorded in the plan doc**, not only in chat. The plan
  doc is the artifact that travels across context windows; a finding that
  isn't written down is effectively lost.
- **Each task must honor its declared Disposition.** The disposition
  (`throwaway`, `keep-as-fixture`, `promote`) was declared during planning
  for a reason — it resolves the ambiguity about what happens to spike
  code once the question is answered.
- **No assumed behavior dressed up as a finding.** If a probe didn't actually
  run, a doc wasn't actually read, or output wasn't actually captured, the
  assumption is not verified — it is still an Open Question.

**Why this exemption is named and scoped:** The TDD-first instinct is strong
and correct for implementation work. Without an explicit exemption, discovery
spikes accumulate tests by reflex, which defeats the point of a spike. The
scope is narrow — the exemption applies to Phase 0 only, and once spike code
is promoted to production (via the `promote` disposition), full TDD rules
resume in the named follow-up phase.

---

## The execution reminder (print in full at execution start)

Print this once at the start of execution. At the start of each subsequent
phase, print the short mantra only:

> **TDD first. Full phases. No stubs. No dead code. Commit when green. Plan matches reality.**

Full reminder (first-phase print):

> **TDD first. Full phases. No stubs. No dead code. Commit at stable points. Plan matches reality.**
>
> - Write tests before implementation — every phase, every change.
> - Execute each phase of the plan completely and in order. Do not skip
>   ahead, do not leave a phase partially done.
> - **No stubbing, no placeholders, no "we'll come back to this."** Every
>   piece of work in a phase is finished before moving to the next phase.
>   If a function is in the plan, it gets a real implementation — not a
>   stub that returns a hardcoded value or raises NotImplementedError.
> - **Everything built must be wired.** A function that exists but is never
>   called from where the plan says it should be called is dead code, not
>   progress. After implementing an item, trace the call path from the
>   entry point to verify it's reachable — not just that it passes its
>   own test in isolation.
> - Run tests after completing each phase to confirm regression safety
>   before proceeding.
> - **Commit after each phase.** When the phase checklist passes, commit.
>   This creates a rollback point and makes "done" concrete. If it's not
>   committed, it's not done.
> - **Keep the plan doc in sync with reality.** Phase shipped → update
>   its header + Outcome Summary. Phase skipped → mark skipped in-place
>   with the decision. Discovery invalidates an assumption → update VA
>   and any affected phase specs before moving on. The plan is a living
>   document; stale plan text lies to the next reader.

---

## Executing Phase 0 (Discovery)

If the plan includes Phase 0, execute it before any implementation phase.
The **Discovery Exemption** (above) governs which rules apply. Additional
execution guidance:

- **Honor the declared disposition for each task.** The disposition was
  chosen during planning — follow it:
  - `throwaway` — delete or archive the spike code after recording
    findings. Do not leave disposable scripts in the repo pretending to
    be production code. A `spike/` or `tests/spike/` location is fine
    if the code has any residual diagnostic value.
  - `keep-as-fixture` — save the output to its target location
    (e.g., `tests/fixtures/`, `tests/eval/ground_truth.json`) and record
    the path in the plan doc. The fixture does not need tests, but
    consumers that read it do.
  - `promote` — the spike code stays, but the named follow-up phase
    must wrap it in real tests before it ships. Until then, flag the
    spike code as non-production (a module-level comment or a dedicated
    directory) so no one mistakes it for vetted code.
- **Update the plan doc as you go.** Move findings into Verified Assumptions.
  Resolve Open Questions. If a discovery invalidates an assumption that later
  phases depend on, update those phases now — flag the changes in the Review Log.
- **Report findings before proceeding.** At the end of Phase 0, summarize what
  was confirmed, what changed, and whether any phases need restructuring. Get
  user approval before starting Phase 1 if the plan changed materially.
- **Phase 0 is not open-ended.** Each discovery task has a concrete question
  and a concrete way to answer it. If a task's answer leads to more questions,
  scope those as new discovery tasks — don't let Phase 0 expand indefinitely.

---

## Executing Parallel Phases

If the Concurrency Map declares a parallel set (e.g., `{Phase 2A, Phase 2B}`),
execution follows a different rhythm than sequential phases. **Read this
whole section before dispatching** — skipping any step is how isolation
leaks become silent and trampling damage compounds across later phases.

### Step 1 — Pre-dispatch snapshot

Before launching any parallel agents, snapshot the shared state declared
in each phase's Shared-state contract. The snapshot is what Re-entry
verification will compare against. Record at minimum:

- Parent repo HEAD SHA and current branch
- `git status --porcelain` output (must be clean — abort if not)
- `git worktree list` output
- Bound ports (`lsof -iTCP -sTCP:LISTEN -P -n`) if any phase touches
  network state
- Any other ambient state named in the contracts

Save the snapshot as a Review Log entry or a temp file. **If `git status`
is not clean, do not dispatch.** Dirty pre-dispatch state means a leak
has nothing to compare against.

### Step 2 — Dispatch in a single message

Launch every phase in the parallel set as **multiple Agent tool calls in
one message**. Sequential Agent calls run serially even when the work is
independent — single-message multi-tool-use is the only way concurrency
actually happens.

Each dispatched agent receives, in its prompt:

- Its phase spec from the plan doc (Goal, Changes, Wiring test, Done-when)
- Its **Shared-state contract** — read as binding, not aspirational
- An explicit instruction to emit a **shared-state footprint report** at
  completion, naming every external surface it touched: commits made on
  its branch, ports bound, processes spawned, env vars exported, files
  written outside its declared write-set
- Its **Re-entry verification** checks, so the agent knows what the
  orchestrator will measure on return

The shared-state footprint report is the in-flight reflection point —
the agent self-audits what it actually did versus what its contract
said it would. If the footprint exceeds the contract, the report flags
it immediately rather than letting it surface as a re-entry failure.

### Step 3 — Re-entry verification

When all parallel agents return, run each phase's Re-entry verification
checks against the pre-dispatch snapshot. Compare:

- Current HEAD SHA against the snapshot's HEAD SHA. **If it changed, an
  agent trampled the parent repo.** This is the most common failure mode.
- `git worktree list` against the snapshot.
- Bound ports against the snapshot.
- Every other invariant named in the contracts.

**If any check fails, stop and report.** Do not silently restore the
expected state — the trampling itself is the bug, and silently fixing it
hides the fact that a parallel grouping was unsound. Add a Review Log
entry naming what leaked, then either:

1. With the user's awareness, manually restore the trampled state and
   continue
2. Pull the conflicting phases back to sequential in the Concurrency Map
   and re-execute the work that was undone

The whole point of the contract is that violations are visible.
Trampling caught at re-entry is cheap (usually one `git checkout`);
trampling caught three phases later is expensive.

### Step 4 — Consolidate locally (do not open PRs)

After re-entry verification passes, the parallel work must be merged
back into the feature branch **locally**. Worktrees and subagents are
an execution-time parallelism mechanism within a single feature branch
— they are not a sub-PR factory.

**The rule:** Parallel agents commit on their own branches (typically
inside their isolated worktrees). The orchestrator then merges each of
those branches back into the parent feature branch with a local
`git merge` — usually `git merge --no-ff <agent-branch>` so the
parallel structure remains visible in the feature branch's history. No
PRs are opened to consolidate parallel chunks; PRs are reserved for
the feature-branch → main hand-off, and only when the user explicitly
asks for one.

**Why this matters:** Treating per-agent branches as PR fodder
fragments a single feature into many merge events, inverts the
branching model, and creates review noise. The user's branch is the
unit of delivery; the parallel agents are an execution detail
underneath it.

**Procedure:**

1. Confirm each agent's branch is committed locally on its own branch
   inside its worktree. **Nothing is pushed at this stage** — per-agent
   branches stay local until the feature branch is consolidated and the
   user approves a push of the feature branch as a whole.
2. Return the orchestrator's working directory to the feature branch in
   the parent repo (verify with `git branch --show-current`).
3. For each agent's branch, in the order the Concurrency Map
   designates (or arbitrary order if the merges commute):
   `git merge --no-ff <agent-branch>` — preserves the parallel topology
   in history. Use `--ff-only` instead if linear history is the
   project's convention.
4. Delete the per-agent worktrees: `git worktree remove <path>`.
5. Delete the per-agent branches once their commits are reachable
   from the feature branch: `git branch -d <agent-branch>`.
6. **Re-run the wiring tests on the consolidated feature branch.**
   Each parallel phase's wiring test passed in its own branch's reality
   — but that reality didn't include the other parallel branches' work.
   The consolidated state is the one that ships, so the wiring tests
   must be re-validated after the merge. If any wiring test fails post-
   merge, the parallel set was unsound — record what broke in the
   Review Log and resolve before continuing. Run the full suite as well
   to catch any regression the merge introduced.

**If the merges conflict:** That's a sign the Pass 2 disjointness check
missed something. Resolve the conflict, record what overlapped in the
Review Log, and tighten the next plan's write-set declarations. A
clean parallel set produces clean merges; conflicts mean the write-sets
weren't actually disjoint.

**Push timing:** Per-agent branches are never pushed. The consolidated
feature branch is pushed only when the user asks. Local merges first,
then push of the feature branch (on user approval), then PRs (on user
request) — in that order. Worktrees and subagents are an execution
detail; only the feature branch crosses the local boundary.

### Step 5 — Report and proceed

After consolidation completes:

- Report each phase's wiring test result
- Report each phase's shared-state footprint
- Report the re-entry verification results
- Report the merge results (which branches merged cleanly, any conflicts
  resolved, current feature-branch SHA)
- Note any deviations from the Concurrency Map and explain them

Then proceed to the next sequential phase, treating the parallel set as
a single completed checkpoint. Each parallel phase still gets its own
commit (the commit-per-phase rule does not change), and the set as a
whole has one re-entry verification record plus one consolidation record
in the Review Log.

---

## Phase completion checklist

Before moving from Phase N to Phase N+1, confirm:

- [ ] **Re-read the phase spec.** Open the plan doc and re-read Phase N's
      goal, changes list, call chain, wiring test, and done-when criteria.
      Diff what was specified against what was implemented. This is the
      single most effective check against partial completion — items missed
      during implementation become obvious when you re-read the spec after
      the work is done.
- [ ] All changes listed in Phase N are implemented (not stubbed)
- [ ] **Wiring test is GREEN.** Run the phase's wiring test and confirm it
      passes. This test exercises the entry point, not just the isolated
      module. If the phase has no wiring test, that's a plan defect — stop
      and add one before claiming the phase is done. **This is the gate.**
      Unit tests passing is necessary but not sufficient.
- [ ] The call chain specified in the phase is wired end-to-end — trace
      from the entry point to the new code and confirm reachability
- [ ] The behavioral done-when criterion holds (not just the test command)
- [ ] **Validation strategy executed.** Run the validation declared in the
      phase spec. If the phase says "run the system and exercise the feature
      manually," do that — don't substitute with "tests pass." If the phase
      says "tests are sufficient," tests are sufficient. The validation
      strategy was calibrated during planning for a reason. Report what you
      validated and what you observed.
- [ ] Tests for Phase N's changes were written first and are passing
- [ ] Existing tests still pass (regression check)
- [ ] **Documentation updates scheduled for this phase are done.**
      Cross-check Phase N against the plan's Documentation Impact
      section. If a doc update was scheduled for this phase, it is
      applied in the same commit window — not deferred to the next
      phase. If no updates were scheduled, confirm the Documentation
      Impact section accounts for this phase's changes (or record
      "no refs" with the search terms used).
- [ ] The system is in a working state
- [ ] Phase N changes are committed
- [ ] **Plan doc reflects the outcome.** Phase N's header marked
      ✅ SHIPPED with the commit SHA; Outcome Summary row added or
      updated; any deviations from the Pass 3 spec noted. See
      "Keep the plan doc in sync with reality" below.
- [ ] **If Phase N ran in a parallel set, Re-entry verification passed.**
      Compare the post-dispatch state against the pre-dispatch snapshot
      (HEAD SHA, worktree list, bound ports, every invariant from the
      Shared-state contract). Record the result in the Review Log. If
      verification failed, the phase is *not* done regardless of wiring
      test status — see "Executing Parallel Phases" § Step 3 for
      recovery.
- [ ] **If Phase N is the final phase (or execution is being
      abandoned), the close-out Review Log entry is written before
      the final commit.** Three required elements — Shipped, Stopped
      or skipped, Discoveries. Template and design goal in
      "Keep the plan doc in sync with reality" § When the plan
      closes. Per-phase markers are not a substitute; the close-out
      is the narrative that ties the arc together for a cold reader.

Report this checklist to the user at each phase boundary. Do not silently
move on.

**The wiring test is the checklist item most likely to expose incomplete
phases.** Unit tests for isolated components will pass even when nothing
calls the component from the entry point. The wiring test is the only
thing that catches this. If you find yourself wanting to skip it because
"the unit tests already cover the logic" — that is exactly the situation
where dead code accumulates.

---

## Keep the plan doc in sync with reality

**The plan is a living document.** Its value after close-out is as a
record that matches what actually happened — not what was hoped for at
Pass 3. A plan that says "Phase 2 will do X" when Phase 2 was skipped,
or claims a Verified Assumption that discovery disproved, is worse than
no plan: future readers trust the text and act on stale information.

Every phase-boundary event has a corresponding plan-doc update. Skip
these updates and the plan silently drifts. Make them part of the same
commit as the code change when possible, so the plan's state matches
the repo's state at every step.

### When a phase ships

After the phase completion checklist passes and you commit:

1. **Edit the phase section header in-place** to mark it shipped and
   link the commit SHA. Format:
   `### Phase N: <Name> — ✅ SHIPPED (\`<sha>\`)`
2. **If the phase delivered something different from the Pass 3 spec**,
   append a short "Delivered:" note describing the difference and why
   it was chosen. Don't rewrite the original spec — append. The spec
   is the contract; the delivered note is the reconciliation.
3. **Add a one-line entry to the Outcome Summary** (at the top of the
   plan — create it if it doesn't exist) with the commit SHA and a
   one-sentence outcome. This is the at-a-glance view for future readers.

### When a phase is skipped

A conditional phase that the gate never tripped, or a phase rendered
unnecessary by discovery, must be **marked skipped in place** — not
deleted. Format:

- Change header to `### Phase N: <Name> — ⏭️ SKIPPED`
- Prepend a "Decision YYYY-MM-DD:" paragraph explaining why the gate
  did or didn't fire, with the concrete numbers/evidence that drove
  the call.
- Leave the original spec below the decision paragraph so a future
  reader can see what would have happened if the gate had flipped.
- Update the Outcome Summary entry to reflect the skip.

### When discovery changes the problem or solution

Phase 0 is the only phase allowed to alter the structure of later
phases — and the alterations must land in the plan doc before Phase 1
starts. Specifically:

- **Assumption disproven** → update the corresponding Verified
  Assumption entry with the finding, and update Reasoning if the
  approach hinges on it. Don't leave the original statement lying
  around implying it's still true.
- **Assumption invalidates a later phase** → update that phase's spec,
  Depends-on list, or scope. If the phase is no longer needed, mark it
  skipped per the rules above.
- **Discovery produces data the plan doesn't anticipate** → add a new
  VA entry rather than mixing the finding into the Review Log alone.
  VA is the source of truth; Review Log is the narrative.
- **Problem Statement is wrong** → edit it. The original can stay in
  the Review Log as "original framing" if the revision is material,
  but the top-of-plan text has to reflect current understanding.

### When new findings surface mid-execution

Not every observation needs a plan update — only those that change
decisions or invalidate assumptions. The filter: would a future reader
need to know this to understand the plan's outcomes? If yes, update.
If it's purely operational (transient error, environment quirk, known
flake), keep it in chat.

Typical mid-execution updates:
- A follow-up the plan surfaced but won't address → add a bullet under
  the phase that surfaced it, point at `TODO.md` for tracking.
- A new risk that didn't exist at Pass 3 → Review Log entry, and if
  it changes the decision for a later phase, update that phase's spec.
- A decision you made that the plan doesn't cover → Review Log entry
  with "Decision YYYY-MM-DD:" and the reason.

### When the plan closes

Closing a plan is not just "I wrote the last commit." It's a specific
act:

1. **Outcome Summary exists at the top** with one row per phase showing
   outcome (✅/⏭️/❌) + commit SHA + one-sentence note.
2. **Every phase section** has its ✅/⏭️/❌ header prefix.
3. **Status header** (top of plan) reads Closed, with a one-line tally
   of what shipped vs skipped vs deferred.
4. **Deferred work** (anything the plan surfaced but didn't land) is
   in `TODO.md` (or the project's equivalent) with a pointer back to
   the plan path, so future readers can find the full context.
5. **Review Log has a dated close-out entry** with three required
   elements — this is the narrative that ties execution together.
   Per-phase headers cover "what shipped where"; the close-out entry
   covers the arc.

   **Design goal:** a reader picking this up cold can reconstruct
   what we shipped, what failed and why we stopped, and what we
   learned that changed our mental model.

   **Required template:**

   ```markdown
   ### Plan close-out — YYYY-MM-DD
   **Shipped:** <final state in git after this plan — the commits,
                 files, and observable behavior that now exist. Not
                 a phase-by-phase replay; one coherent paragraph or
                 bullet list that enumerates the shipped surface.>
   **Stopped or skipped:** <what didn't land, and the reasoning.
                             Phases skipped, work deferred to TODO,
                             anything abandoned. Write "nothing" if
                             the plan shipped in full.>
   **Discoveries:** <what execution taught us that changed our
                     mental model — insights we wouldn't have
                     captured during planning. Failed approaches
                     that informed the shipped one; surprises from
                     smoke tests; assumptions that turned out wrong
                     mid-phase. Write "none noteworthy" if execution
                     went exactly as planned (rare — interrogate
                     this before writing it).>
   ```

   Per-phase `✅ SHIPPED (sha)` markers are necessary but not
   sufficient. The close-out is the paragraph the next reader will
   open first when they ask "why does the code do X?"

### Why this matters

Plans are read twice: once during execution, once months later when
someone is asking "why does the code do X?" The second read is what
determines whether the plan was worth writing. If the doc matches the
code, the reader gets the full why-chain without chasing commits. If
it doesn't, they trust the stale text and make the wrong call, or
give up and read the code raw — which is the failure mode the plan
existed to prevent.

**A plan that doesn't reflect reality is technical debt with a
credibility surface.** Fix it as you go.

---

## Mid-phase check

If implementation of a single item in a phase takes more than a few
test/implement iterations without converging, stop. Do not keep pushing.
Report to the user:

- What item you're stuck on
- What you've tried
- Whether the plan's assumptions about this item were wrong

This catches problems before they compound. The instinct to "just get it
working" mid-phase is where stubs and hacks creep in.

---

## Why this matters

There are two forms of phantom progress, and both break the contract:

1. **Stubs and placeholders** — code that exists but doesn't do anything real.
   The plan looks done but the system doesn't work.
2. **Dead code** — real implementations that are never wired into the system.
   A function defined but never called, an event type created but never
   emitted, a config file specified but never seeded. These pass their own
   tests in isolation but the feature doesn't work end-to-end.

Both create the same outcome: a "complete" implementation with gaps that
surface later. Committing after each verified phase creates concrete
checkpoints — you can't claim a phase is done without the commit to prove it,
and the wiring check catches dead code before it compounds across phases.

---

## Known Anti-Pattern: The Isolation Trap

<!-- TRACKING: This section added 2026-04-07 to address recurring wiring gap.
     If phases still complete without wiring after these changes, escalate to
     a programmatic hook (e.g., hooks/phase-wiring-check.sh). -->

The most common phase-plan execution failure is what looks like a complete
implementation but isn't wired to anything. The pattern:

1. Phase builds a component (model, agent, function)
2. Phase writes unit tests for the component
3. Unit tests pass
4. Phase feels "done" — commit, move on
5. The entry point (cli.py, main.py, the router) still runs the old code
6. All tests green. Feature doesn't work. Nobody notices until end-of-plan review.

**Why this happens:** Unit tests passing creates false confidence. The phase
completion checklist says "trace the call chain" but that's a mental exercise
easily skipped when tests are green. The Verification command runs isolated
module tests, which pass regardless of whether anything calls the module.

**How to prevent it:** Each phase needs a **wiring test** — an integration
test that starts at the entry point and asserts the new behavior is reachable.
This test is RED at phase start (proving the feature doesn't exist yet) and
GREEN at phase end (proving the wiring is live). The Verification command
must run this wiring test, not just the unit tests.

**How to detect it during execution:** If you finish a phase and the only
tests you ran are in `tests/test_<component>.py`, ask: "What test proves
that the entry point can reach this code?" If the answer is "none yet" or
"that's in a later phase," the phase is not done.

---

## Known Anti-Pattern: Isolation Trampling

<!-- TRACKING: Section added 2026-05-04 alongside the Concurrency Map
     additions to phase-plan.md. If parallel phases still trample shared
     state after these changes (despite snapshot/verification protocol),
     escalate to a programmatic pre-dispatch check (e.g.,
     hooks/parallel-dispatch-check.sh) that refuses to launch agents
     when the parent repo is dirty or when contracts contain only
     mechanisms ("worktree") instead of invariants. -->

The most common parallel-execution failure is what looks like isolated
agents quietly mutating shared state. The pattern:

1. Phase 2A and Phase 2B are declared parallel-safe — disjoint write-sets,
   "both run in worktrees."
2. Phase 2A is launched in worktree A; Phase 2B in worktree B.
3. Phase 2B's agent runs `git checkout main` (or `git stash`, or
   `git rebase`) in what it thinks is its worktree, but the command
   lands on the parent repo — because git operations from a child
   worktree can move HEAD on the parent under certain command forms,
   or because the agent's working directory drifted.
4. The parent repo's HEAD silently moves.
5. The next sequential phase reads the parent's HEAD, gets the wrong
   commit, and either fails confusingly or — worse — silently produces
   the wrong output.
6. Hours or days later, someone notices the orchestrator branch is on
   the wrong commit. The fix is one `git checkout` command. The
   diagnosis takes the rest of the day.

**Why this happens:** Worktrees are file-system isolation, not full
repo isolation. They share the parent's git database; commands that
manipulate refs (`checkout`, `stash`, `rebase`) can leak across the
boundary. A Shared-state contract that lists "isolated worktree" but
doesn't name *what would break the isolation* gives the orchestrator
no early-warning signal.

The same shape applies beyond git: shared tmp directories, ambient
env vars, lock files, port collisions, shared databases. Files-only
isolation has a long history of leaking through ambient state.

**How to prevent it (planning-side):** The Shared-state contract must
list **invariants**, not mechanisms. "Runs in worktree" is a mechanism
— it describes what wrapper is used. "Does not invoke `git checkout`,
`git stash`, or `git rebase` in the parent worktree; binds no ports;
writes only under `$TMPDIR/<phase-id>/`" is a list of invariants —
each one is a checkable statement about behavior. Pass 3's concurrency-
honesty check exists to catch mechanism-only contracts.

**How to detect it during execution:** The pre-dispatch snapshot and
re-entry verification protocol (see "Executing Parallel Phases" above)
catches this. If the parent HEAD SHA at re-entry doesn't match the
snapshot, isolation trampling happened — even if every wiring test
went GREEN, the parallel grouping was unsound and the plan's
Concurrency Map needs adjustment.

**Recovery:** Trampling caught at the re-entry check is cheap — the
fix is usually one `git checkout`. The damage is the wasted time when
it isn't caught and downstream phases run on the wrong base. Catching
it early is the entire purpose of the snapshot/verification discipline.

When trampling is observed, write a Review Log entry that captures:
the phase that leaked, what state it touched, what the contract said,
and what the contract should say next time. The Concurrency Map for
the *next* plan benefits from this entry; the current plan benefits
from the recovery.

---

## Execution guardrails (repeated for forefront)

These guardrails also appear in the main `phase-plan.md`. Repeated here
because forgetting them during execution is the primary failure mode.

- **No stubs, ever.** Every item in a phase gets a real implementation.
  If you catch yourself writing a placeholder, stop — either implement it
  fully or flag that the phase needs to be broken down further. Phase 0
  discovery is the only exception (see Discovery Exemption above).
- **Built means wired, and wired means tested.** Code that exists but
  isn't reachable from the entry point is dead code, not progress. After
  building something, trace the call path. If nothing calls it yet, that's
  part of the same item — not a separate task for later. The wiring test
  is what makes this enforceable: if the wiring test is still RED, the
  wiring isn't done regardless of how many unit tests pass.
- **Commit at every stable point.** After each phase passes its checklist,
  commit. No batching phases into a single commit. Each commit is a
  verified, working checkpoint that can be rolled back to independently.
- **No assumed behavior.** If you discover mid-phase that something
  doesn't work as the plan assumed, stop and update the plan before
  continuing. "I believe this method returns X" is not validation.
