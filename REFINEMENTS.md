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

## 2026-08-26: The gate that was run, but not the repo's gate

**Observed pattern:** A push goes out after a verification step that was *real, and ran, and
passed* — but was not the gate the repo declares. CI then catches what a local check should
have. This is distinct from skipping validation: the agent did validate, against the wrong
target, and therefore held justified confidence.

**Evidence:**
- eslint run as the pre-push check over a diff that added a new Rust file; two
  `clippy::pedantic` errors reached CI, went red, and blocked a deploy.
- A Homebrew `cargo-clippy` shadowing rustup's on `PATH` and lagging it by two minor
  versions (local 0.1.94, CI 0.1.97) — every "clean" local run was a different program.
  Cost three round trips before anyone read the version numbers. A scrubbed
  `CARGO_TARGET_DIR` ruled out caching and still disagreed.
- A gate non-reproducible in a fresh worktree because `android/local.properties` is
  gitignored and CI generates it — so the worktree lacked a file the gate assumed.

**Proposed refinement:**
- **Target:** extend `CLAUDE.md` § Development Workflow (adopted), plus workspace audit
  check 27 in the CroftC layer.
- **Change:** new bullet "Push runs the repo's DECLARED gate, named and resolved" — run the
  single command the repo declares rather than one inferred from the diff's file
  extensions; name it in the output; resolve the toolchain explicitly rather than off bare
  `PATH`; run both gates for a two-language diff; treat a repo that declares no gate
  command as a finding rather than an invitation to invent one; never let `--fix` autofix
  reach a commit unreviewed.
- **Rationale:** the existing "Validation must be CONCURRENT" rule governs whether the
  evidence is *good*; it does not govern whether the evidence-producing command was aimed
  at the right thing. Every observed failure was a real gate, honestly run, on the wrong
  target — which the CONCURRENT rule's three tests (time, extent, subject) do not catch,
  because the check was current, complete, and about the code under review. It was about
  the wrong *language*.

**Status:** accepted (2026-08-26)

**Notes:** The workspace-side half is CroftC audit check 27 (advisory): a repo whose CI runs
a gate must name that command in its own docs, so a session can find it without reading
`.github/workflows`. Fired on croft-stack and discovery on its first run. The diagnosis half
of this — pin *and* resolve, declare/read/refuse/resolve — already lived in
`CroftC/.claude/CI-PATTERN.md` rule 7; only the actor-side rule was missing.

## 2026-08-26: A short reply reads as unambiguous, which is why it is not checked

**Observed pattern:** Terse user input is over-interpreted rather than confirmed, and the
misreading is acted on immediately because a short answer carries no felt uncertainty to
prompt a check. Cost is rework, occasionally repo-wide.

**Evidence:**
- `gtg` read as "got to go" (the user meant "good to go"); the session began writing a
  session-state handoff file and had to be interrupted mid-write.
- `forage` heard as "four edge" — the project name, in the project's own session.
- A bare yes/no answered the wrong half of a two-part question; the author **handle** was
  built where the **display name** was meant, and the correction cascaded into a
  terminology rename across the repo.

**Proposed refinement:**
- **Target:** extend skill `ask-questions-if-underspecified` § Restate before starting.
- **Change:** the existing rule restates answers to questions *you asked*. Add the
  unprompted case: any reply under roughly five words that gates a naming or
  implementation decision gets restated as a full sentence, and you wait, before editing
  any file.
- **Rationale:** the skill's restatement rule already existed and did not fire, because it
  is scoped to a question round. The expensive misreads all happened outside one.

**Status:** accepted (2026-08-26)

**Notes:** Deliberately scoped to *naming and implementation* decisions rather than all
short replies — a rule that fires on every "yes" gets ignored, which is how the original
scoping problem started.

## 2026-08-26: Jargon in the framing question, and layers collapsed into one sentence

**Observed pattern:** Design and protocol explanations lead with domain nouns instead of
actor narratives, and phrasings silently merge two system layers. Both are corrected by the
user — but often only after the sentence has been written into a canonical doc, where
unwinding it costs a revision block.

**Evidence:**
- A session opened with three jargon-heavy framing questions; the user required them
  re-explained before any work started.
- Layer-collapsing phrasings ("Bob is cut off", "silent dormant return") each drew an
  explicit correction: one described a relay refusing a call, the other a directory
  dropping a record, and the sentence did not distinguish them.
- A `tree.croft.ing` layering description conflated two layers and was corrected.

**Proposed refinement:**
- **Target:** new short section in `CLAUDE.md`, "Explaining Design and Protocol Work".
- **Change:** lead with an actor narrative before the noun phrase; no domain noun in a
  *framing question* without a one-line gloss; lead with the decision and its options;
  name layer boundaries rather than collapsing them.
- **Rationale:** this repo's `CLAUDE.md` covered tone (no exclamation points, no
  meta-commentary) but not *comprehensibility of the framing itself*. The rule belongs in
  the versioned layer: the tone guidance lives in `~/.claude/CLAUDE.md`, which is not in
  any git repo, so anything placed there is as durable as session memory.

**Status:** accepted (2026-08-26)

**Notes:** The first draft of this section duplicated the tone rules that already live in
`~/.claude/CLAUDE.md` § Communication Style — same guidance, same examples. Removed the same
day, on the owner's challenge. Recorded because the failure is instructive: the duplication
was introduced *by* an entry arguing the versioned layer is the durable one, which is exactly
how "put it somewhere safer" turns into a second copy.

Structural finding, restated correctly after that challenge: the problem with
`~/.claude/CLAUDE.md` is **not** that durable content lives there — it is that the file plays
two roles at once, manifest (`@`-imports) and content. The sorting test is **not** durable vs
ephemeral but **portable vs machine-local**: would this still be true on a different machine?
Git identity by path, SSH host aliases, MCP/Barndoor routing, scratchpad paths — machine-local,
correctly placed, and actively wrong to move into a shared repo. Communication style, subagent
model selection, visual-communication and progress-output conventions — portable, and currently
unversioned and unreviewable. Any correction is a **move**, never a copy; a rule that ends up
in both files has made things worse, not safer.

## 2026-08-26: A green suite is not a verdict — three ways the harness lies

**Observed pattern:** Wrong, confidently-stated, spec-relevant findings surviving
a green test suite — because the *harness* was wrong, not the code. Each had to
be publicly withdrawn after the fact.

**Evidence:**
- 2026-08 MLS exclusion/fold sessions — **a user story fabricated backwards from
  a test is not a scenario.** A "concurrent remove + re-add" test had a story
  invented to justify it; the owner asked how a moderator not yet synced with a
  removal could readmit someone they cannot see removed, and the pairing
  collapsed as socially unreachable. The reachable shape behaved differently — it
  hard-stopped.
- Same sessions — **`let _ = ingest(...)` corrupts verdicts.** Two apparent
  order-dependence failures were harness artifacts, invisible until error returns
  were printed. An experiment that discards errors cannot distinguish "resolved
  differently" from "never saw the fact."
- Same sessions — **a projection is not a verdict.** A `MEMBER` read from folded
  state was reported as "the addition won"; the group was actually hard-stopped
  in contradiction, and the member list was merely the projection of an escalated
  state. The status channel said the opposite of the value the assertion read.

**Proposed refinement:**
- **Target:** extend skill `testing-anti-patterns` (first and third points);
  extend skill `systematic-debugging` (second point). Companion to the
  *checks that expire* entry below — same family, different surface.
- **Change:** add *The harness can be the thing that is wrong*:
  (a) derive scenarios from actor behaviour **before** writing the test, never
  backwards from a test that already exists — a story invented to justify a test
  will justify any test;
  (b) print the outcome of every fallible harness call; a swallowed error in the
  *instrument* is worse than one in the code, because it corrupts the verdict
  rather than the run;
  (c) when a system exposes a status channel alongside a value (fork status,
  contradiction heads, validation state), assert on the status too — the value
  an assertion happens to read may be a projection of a state that contradicts it.
- **Rationale:** the existing "no completion claims without fresh evidence" rule
  assumes the evidence, once fresh, is sound. These are cases where the evidence
  was fresh, green, and *wrong* — and each produced a claim that had to be
  retracted in public.

**Status:** accepted, NARROWED — 2026-08-26

**Notes:** Promoted from agent memory 2026-08-26 at the user's direction, after
they asked "memory is not portable off this machine, when do we put things in
memory and when in repos?". The workspace-scoped sibling (quote sources
verbatim; verify a claim before repeating it) went to
`CroftC/.claude/COORDINATION.md` `fdeb3d3`, since cross-session messaging is
where that one bites.

**Accepted narrowed, by the user's decision.** The narrowing: the first two
points generalise to any project and land as full material, while the third —
"assert on the status channel too" — is *conditional*, since a system without a
status surface cannot have that bug. It is phrased so it simply does not apply
where there is nothing to apply it to, rather than presenting as a universal
rule that half of readers must decide to ignore.

**Landed as:**
- `skills/testing-anti-patterns.md` → **Anti-Pattern 8: The Harness Is the Thing
  That Is Wrong**, with form (a) a scenario written backwards from a test, form
  (b) the instrument swallowing its own errors, the conditional status-channel
  note, and a three-question gate. Three new entries in the closing Red Flags.
- `skills/systematic-debugging.md` → **Phase 1.4: Verify the Instrument Itself**,
  placed before the existing "Verify the Test Itself" because a dishonest
  instrument invalidates the test check too. Carries the fail-loud-binds-harnesses
  -harder point and the runner-globs-your-scratch-work observation.

**Why it earns a place next to "no completion claims without fresh evidence":**
that rule assumes evidence, once fresh, is sound. All three of these had fresh,
green evidence and were wrong. The workspace-scoped sibling (quote sources
verbatim; verify a claim before repeating it) went to
`CroftC/.claude/COORDINATION.md` `fdeb3d3`, since cross-session messaging is
where that one bites.

## 2026-08-26: A check that was true when it ran, and a plausible cause that fit

**Observed pattern:** Verification failing while the work is careful — not by
being skipped, but by going *stale* or by stopping at the first cause that fits.
"Check more carefully" is not the remedy for either, which is what makes them
worth a rule.

**Evidence:**
- forage, 2026-08-26 — scanned a registry for duplicate ids, got a true answer
  (`DL-001..DL-034`, no gaps), then allocated `DL-035` later **from a newer base
  without re-scanning**. A peer had taken it. The check was correct when it ran;
  a rebase invalidated it with nothing visibly changing. Worse than not
  checking, because it leaves *justified* confidence.
- forage, same day — a CI failure sat in a file that also contained a visible
  `waitForTimeout(300)`. Three sessions independently blamed the sleep. The real
  cause was an invisible race: the assertion already had a `waitForSelector`,
  the element *was* found, and a repaint replaced it before `.count()` ran.
  Waiting longer could never have fixed it.
- forage, same day, third instance — a peer ran `git show <sha> | head -8`, saw
  the unrelated change in frame and the fix below the fold, and reported
  "verified independently rather than take it on faith". A verification claim
  travelled on a truncated read, reaching their owner as "flaky test".

**Proposed refinement:**
- **Target:** extend skill `systematic-debugging`; possibly one line in `CLAUDE.md`
  beside "No completion claims without fresh evidence".
- **Change:** add a section, *Checks that expire and causes that merely fit*:
  (a) a uniqueness/allocation check is valid only against the tree you are
  committing — re-evaluate after any rebase, or use a reserving allocator;
  (b) before naming a cause, capture the actual failure output — a mechanism
  that *fits* the evidence is not the evidence;
  (c) when a fix changes two things, say which one was the fix, or the visible
  one gets the credit downstream;
  (d) never let a piped `head`/`tail` back the word "verified" — read `--stat`
  first to learn the size, then the full hunks, especially when the conclusion
  is "X is *not* the cause";
  (e) distinguish "load *revealed* it" from "load *caused* it" — calling a real
  latent race a flake is how races live forever.
- **Rationale:** these three failures occurred in one day across three sessions
  doing careful work, and every one produced a confidently-stated wrong claim
  that then travelled to someone else. The existing rule ("no completion claims
  without fresh evidence") covers unverified claims; it does not cover claims
  whose evidence was real and has since expired, or is real but partial.

**Status:** accepted, REFRAMED by the user — 2026-08-26

**Notes:** Raised by the user asking the right question — "memory is not
portable off this machine, when do we put things in memory and when in repos?"
The workspace-scoped half (registry id allocation) went to
`CroftC/.claude/TRACKING.md` (`0da573b`). This half is general engineering
discipline and belongs in the global layer, hence a proposal here rather than a
memory entry that dies with the machine.

**THE USER'S REFRAMING IS THE REFINEMENT, and it is better than what was
proposed.** I had framed this as "checks expire". Their formulation:

> *fresh is not prescriptive enough — fresh since the change, fresh since a
> time? Validation needs to be CONCURRENT with completion claims.*

That is the sharper rule, because **"fresh" invites the question *fresh enough?*,
which has no answer, while "concurrent" is binary**: did anything change between
the validation and the claim? It also subsumes all three observations more
cleanly than my framing did, along three axes:

| Observation | Under "fresh" | Under "concurrent" |
|---|---|---|
| id scan, then rebase, then allocate | arguably fresh — same session | not concurrent in **time** |
| `git show \| head -8` → "verified" | fresh, ran seconds prior | not concurrent in **extent** |
| visible sleep blamed for invisible race | fresh output | not concurrent in **subject** |

**Landed in `CLAUDE.md`** (always-loaded core), replacing *"No completion claims
without fresh evidence"* with **"Validation must be CONCURRENT with the
completion claim"** and the three axes — time, extent, subject — each carrying
its observed failure. The closing line is the part that makes it a rule rather
than an exhortation: *none of the three is caught by running the check more
often*, which is what separates them from carelessness and why "check more
carefully" is the wrong remedy.

The prior wording is preserved inside the new rule (run the proving command,
read complete output and exit code, no "should work", confidence from a previous
run does not count) — the reframing extends it, it does not discard it.

## Status lifecycle

- **proposed** — created by `learn`, awaiting user review.
- **accepted** — user applied the refinement. Record file(s) changed in Notes.
- **rejected** — user declined. Record the reason so it isn't re-proposed.
- **parked** — valid but deferred. Revisit if the pattern continues.

---

## Entries

<!-- New entries added below in reverse-chronological order (newest first). -->

## 2026-05-04: Mutation accommodation in TDD + concurrency planning with isolation invariants

**Observed pattern:** Two related gaps in the existing guidance:

1. **Mutation accommodation.** The TDD cycle ended at "VERIFY GREEN +
   REFACTOR" with no defense against assertions that mirror the
   implementation's shape rather than its behavioral edges. A test that
   passes today can be entirely satisfied by code where flipping `>` to
   `>=`, dropping a branch, or swapping a constant produces no failure.
   Coverage looks complete; behavior is unproven. The "watched-it-fail"
   principle prevents one failure mode (test never failed) but not the
   other (test fails on absence, passes on any shape that returns the
   right value at the asserted point).
2. **Concurrency in phase-plan.** Plans defaulted to sequential phases
   even when work was embarrassingly parallel — no mechanism surfaced
   parallelizable subgraphs, so concurrency was left on the table. When
   parallelism *was* attempted, write-set declarations were files-only;
   ambient state (git HEAD, env vars, ports, daemons) leaked across
   "isolated" boundaries and trampled the parent context, costing
   diagnostic time disproportionate to the trivial fix.

**Evidence:**
- User session 2026-05-04 explicitly naming both gaps: "mutation
  accommodation for test-driven development" and concurrency thinking
  where "they kind of trample each other."
- User-cited trampling incident: a worktree-isolated agent ran
  `git checkout` in the main worktree, moving HEAD on the parent repo.
  Wiring tests passed; downstream confusion took meaningful time to
  diagnose. The user's own retrospective: "the concurrency map could
  have noted the shared-state risk."

**Proposed refinement:** Accepted in this session — applied directly.

- **Target:** `skills/testing-anti-patterns.md`, `tdd-guardian.md`,
  `skills/phase-plan.md`, `skills/phase-plan/{pass1,pass2,pass3,execute}.md`
- **Change:**
  1. **Mutation:**
     - `testing-anti-patterns.md` § Anti-Pattern 6: Implementation-Mirrored
       Assertions. Mental Mutation Pass gate function. Updated TDD-prevents
       table, quick reference, red flags.
     - `tdd-guardian.md` Sacred Cycle extended to RED → VERIFY RED → GREEN
       → VERIFY GREEN → **MUTATE** → REFACTOR. Mental Mutation Pass section
       inline. Mutation concerns escalation example. Quality Gates checklist
       item. Common-violations entry.
  2. **Concurrency:**
     - `skills/phase-plan.md` plan-doc template extended with per-phase
       Read-set / Write-set / Shared-state contract / Re-entry verification
       fields, plus a top-level Concurrency Map section (required even when
       sequential).
     - `pass1.md` step 7 derives the Concurrency Map from per-phase fields;
       defaults to sequential, parallelism opt-in.
     - `pass2.md` step 5 audits disjointness, sharpens mechanisms into
       invariants, surfaces missed parallelism, adds Re-entry verification.
       Review Log gets a Concurrency entry.
     - `pass3.md` adds quality gate 5b (Concurrency honesty) — confirms
       contracts are invariants, not mechanisms, and Re-entry verification
       maps one-to-one to the contract.
     - `execute.md` adds an Executing Parallel Phases section (pre-dispatch
       snapshot, single-message dispatch with shared-state footprint
       reports, post-dispatch re-entry verification) and an Isolation
       Trampling anti-pattern section. Phase completion checklist gets a
       conditional re-entry verification item.
- **Rationale:**
  - Mutation: catches the most common form of false-confidence coverage
    at zero cost; escalates to mutmut/Stryker/go-mutesting only for
    high-stakes code. The mental pass is the floor, tooling is the
    ceiling.
  - Concurrency: forces the parallelism question to be asked in every
    plan (empty Concurrency Map = plan defect), forces shared-state
    declarations to be invariants (checkable) rather than mechanisms
    (wishful), and gives execute.md a snapshot/verification protocol
    that surfaces trampling at the cheapest moment to fix it.

**Status:** accepted

**Notes:**
- TRACKING comments added to `phase-plan.md` (concurrency rationale +
  trampling failure mode) and `execute.md` (Isolation Trampling
  anti-pattern). Monitor: (a) whether plans actually populate write-sets
  and shared-state contracts vs leaving them empty; (b) whether re-entry
  verification catches isolation leaks proactively; (c) whether parallel
  dispatch shows up in execute.md runs at all, or whether the sequential
  default holds even when the Concurrency Map declares parallelism is
  safe; (d) whether the mental mutation pass becomes habitual or whether
  green tests with implementation-mirrored assertions still slip through.
- If write-sets are reflexively left empty, escalate to a programmatic
  check that refuses to advance past Pass 2 without them. If trampling
  recurs despite the snapshot/verification protocol, escalate to a
  pre-dispatch hook that refuses to launch parallel agents when the
  parent repo is dirty or contracts contain only mechanisms.
- **2026-05-04 follow-up:** User clarified that parallel agents must
  consolidate **locally** into the feature branch, not via per-chunk
  PRs. Added `execute.md` § Executing Parallel Phases Step 4
  (Consolidate locally), Concurrency Map scope note in
  `phase-plan.md`, and a feedback memory at
  `feedback_parallel_consolidates_locally.md`. The branch is the unit
  of delivery; worktrees/subagents are execution-time concurrency
  underneath it. Monitor: whether agents still reach for `gh pr
  create` after parallel sets despite the explicit guidance, or
  whether the local-merge protocol becomes the default.


## 2026-04-17: Plan close-out must produce a reader-can-reconstruct narrative

**Observed pattern:** Plans were executing to completion (final phase
shipped, Outcome Summary rows present, per-phase `✅ SHIPPED` markers
in place) but the plan doc was not closing out cleanly. A reader
picking it up cold could not reconstruct the arc — what shipped,
what failed and why we stopped, and what we learned that changed our
mental model. Per-phase markers answered "what shipped where" but not
"what was the journey." `execute.md` § When the plan closes had a
Review Log requirement, but it was vague ("dated close-out entry
naming what the plan accomplished end-to-end, including any late
surprises") and in practice was skipped or reduced to a restatement
of the Outcome Summary.

**Evidence:**
- User report 2026-04-17 citing a session-level observation from
  another LLM: "the plan has Outcome Summary + Phase 4 SKIPPED
  rationale, but no dated close-out narrative tying execution
  together — no record of the smoke test success, no reasoning on
  the 'concurrency dominates wall clock' insight as an execution-time
  discovery, no enumeration of the final shipped state."
- User's explicit design goal, quoted verbatim: "A reader picking
  this up cold can reconstruct: what we shipped, what failed and why
  we stopped, and what we learned that changed our mental model."

**Proposed refinement:**
- **Target:** `skills/phase-plan/execute.md`
- **Change:**
  1. Strengthened § When the plan closes item 5 from a vague
     one-liner into a three-element template (Shipped / Stopped or
     skipped / Discoveries). Included the design-goal quote
     verbatim so the test for sufficiency is unambiguous.
  2. Added a phase-completion-checklist item that fires when Phase
     N is the final phase (or execution is abandoned): close-out
     Review Log entry written before the final commit, all three
     elements populated.
- **Rationale:** Per-phase `✅ SHIPPED` markers enumerate "what
  shipped where" but leave the arc implicit. The three-element
  close-out makes the arc explicit in one place. Without it, the
  plan's most valuable reader — the one reading months later to
  answer "why does the code do X?" — has to reconstruct execution
  by chasing commits and scanning scattered phase notes. That is
  the exact failure mode the plan doc exists to prevent.

**Status:** accepted

**Notes:** Applied 2026-04-17. Files changed:
`skills/phase-plan/execute.md` (strengthened close-out item 5 with
three-element template and design-goal quote; extended phase
completion checklist with final-phase close-out requirement).

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

**Status:** accepted (Option A) — 2026-08-26

**Notes:** User's framing — "this is maybe just barely at that
threshold" — suggests the refinement should be conservative. Option
A (trigger tweak) is my lean; Option B if A proves insufficient
after another strike.

**SECOND STRIKE, 2026-08-26 — and it decided this.** The entry's own
parking condition was "revisit if a second session replays the same
shape". It did, in the CroftC/forage work: a rename touching 49
files changed the event vocabulary (`field.created` →
`feed.created`), a published lexicon (`fyi.forage.field` →
`fyi.forage.feed`), and deliberately broke stored logs — approved in
a single conversational exchange, executed with no plan doc. In the
same session, `phase-plan` DID fire correctly when the user said
"make a plan for it", so the gap is specifically the conversational
"yes" that turns into a large change.

**Decided by the user: Option A.** Implemented — the trigger now also
fires on a batch approved in conversation that would create files,
change a data contract (schema, event vocabulary, published lexicon,
stored format, public API), or span several files, and the skill body
gains a short *A batch approved in conversation* section carrying both
strikes as the recorded why. The threshold wording deliberately leads
with "data contract" rather than a file count: 3+ files is a weak
signal on its own (plenty of trivial changes touch three), while the
data-contract clause would have caught both strikes.

**What to watch:** whether this fires so often it becomes noise on
ordinary multi-file edits. If it does, tighten to data-contract and
file-creation only, and drop the file-count clause. Option B (a
dedicated skill) remains the escalation if A proves insufficient. Meta-observation: this session's work itself
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
