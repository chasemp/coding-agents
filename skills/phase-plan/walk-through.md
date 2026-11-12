# Phase Plan — Walk-through

> Loaded on demand by the `phase-plan` skill whenever a pass or execution has a list of things for the user
> to decide. **Not a plan template.** It is the one procedure every pass file and `execute.md` points to.

## When to use

Any list the user must decide: open questions at the end of a pass, Pass 2 review findings, probe results that
change the plan, and decisions that come up during execution. If there is nothing for the user to decide, say
so in one line and skip the walk.

## Procedure

1. **Sort first.** Split the list into decisions the user owns (scope, behaviour others will see, risk they
   carry, anything that reverses an earlier answer) and engineering-internal choices. Decide the internal ones
   yourself and record each as `Decided by agent: X, because Y`. They are listed at the end for override, not
   walked.
2. **Brief listing.** One line per user-owned item, numbered, so the user sees the size of the walk. Offer
   "accept all as recommended" here.
3. **One item per message.** Never two decisions in one message. Each item, in this order:
   - **The decision**, in one plain-English sentence: what has to be chosen.
   - **Situation:** what happens today and why it matters, with any domain term glossed in a few words.
   - **Concrete example:** one case from the user's own work or this plan, not an abstract one.
   - **Options**, each with its consequence: what changes, what it costs, what it rules out.
   - **Recommendation**, with the reason.
   - **Proposed tag** (BLOCKING / PHASE-GATED (phase) / ADVISORY). The tag is a label on the answer, not the
     question; never ask the user to confirm a tag on its own.
4. **Echo the answer in one line** before acting on it: what you took it to mean and what you will now write.
   If it conflicts with an earlier answer or a locked decision, say which one and ask before writing.
5. **Write the answer into the plan immediately**, before the next item: the decision in its durable home (a
   numbered decision, the phase it changes), and the question marked resolved with a pointer to it. An answer
   held only in conversation is lost at the next context reset.
6. **Close the walk** with a short summary: each answer in one line, then every `Decided by agent` item for
   override. Run the scoped re-check for answers that added work (see the pass file's late-change rule) before
   calling the plan ready.

"Accept all as recommended" applies the recommendations and tags as written, writes them in, and still prints
the closing summary.

## Review grades and question tags

Pass 2 reviewers grade findings BLOCKER / REVISE / CONFIRMED; questions carry BLOCKING / PHASE-GATED /
ADVISORY. They label different things: a reviewer's finding, and a decision the user owns. The mapping:
a BLOCKER finding that needs a user decision becomes a BLOCKING question.
A BLOCKER or REVISE finding with one correct fix is folded in and logged, not walked.

## Worked example

A plan's main skill file must end under its 500-line budget, and the measured estimate after planned cuts is
about 540.

> **Item 1 of 4. Where should the last ~40 lines of the main file go?**
>
> *Situation:* the main file is loaded in every session, so its size is paid each time; the budget is checked
> by the repo's audit. Planned cuts get it to about 540.
>
> *Example:* the Phase 0 template block is 48 lines and is only used while drafting a plan in Pass 1.
>
> *Options:* (A) move the Phase 0 template into `pass1.md`, leaving a one-line pointer: under budget, and
> drafting still has it at hand. (B) trim the Usage Patterns: under budget, but they are what a new session
> reads to pick a pass. (C) raise the budget: no move, but the audit flag stays.
>
> *Recommendation:* A, because only Pass 1 uses the template. *Proposed tag:* PHASE-GATED (size phase).

User: "A". Echo: "Moving the Phase 0 template to `pass1.md` with a one-line pointer; writing it as a decision
now." Then the plan gets the decision, the question is marked resolved with a pointer, and the walk moves to
item 2.
