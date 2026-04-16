---
name: ask-questions-if-underspecified
description: >
  Front-door clarification skill. Trigger when a request has multiple
  plausible interpretations, or when the objective, "done" criteria,
  scope, constraints, environment, or safety are unclear. Ask 1–5
  must-have questions in a compact multiple-choice format with
  defaults before starting work. Pause until answers arrive. Yields
  to `phase-plan` when the resulting scope turns out non-trivial.
  Adapted from trailofbits/skills.
---

# Ask Questions If Underspecified

Some requests are clear enough to act on; some aren't. When a request
has multiple plausible interpretations or key details are missing,
asking 1–5 targeted questions up front beats starting work and
backfilling questions when things go sideways.

This skill is the **front door** for ambiguous requests. When the
clarified scope turns out to be non-trivial, hand off to `phase-plan`
for structured planning.

**Source attribution:** Adapted from the
[trailofbits/skills ask-questions-if-underspecified plugin](https://github.com/trailofbits/skills/tree/main/plugins/ask-questions-if-underspecified)
by Kevin Valerio (commit `9f7f8ad`, reviewed 2026-04-16). Review and
adaptation rationale in
`plans/external-learn-ask-questions-if-underspecified.md`.

## Trigger test: is the request underspecified?

Treat a request as underspecified if any of these axes is unclear
after a quick look at the code and the user's message:

1. **Objective** — what should change vs stay the same
2. **Done** — acceptance criteria, examples, edge cases
3. **Scope** — which files, components, users are in or out
4. **Constraints** — compatibility, performance, style, deps, time
5. **Environment** — language/runtime versions, OS, build/test runner
6. **Safety / reversibility** — data migration, rollout/rollback, risk

If there are multiple plausible interpretations of the request, treat
it as underspecified. Err on the side of asking when two of these
axes are ambiguous at once — the questions are cheap, the rework is
not.

## When NOT to trigger

- The request is already clear and a single interpretation is obviously
  correct.
- The missing details can be resolved by a quick, low-risk discovery
  read (grep an existing config, read a nearby file, check `--help`).
  See the anti-pattern below.
- `phase-plan` is already active — its Pass 1 walk-through handles
  clarification inside the planning workflow using a different
  (severity-based) format. Do not run both at once.
- The user has explicitly said "just do your best interpretation" or
  equivalent.

## Anti-pattern: ask vs look up

**Do not ask questions that a quick discovery read would answer.**

- Running `python --version` takes less time than asking which Python.
- Reading `pyproject.toml` takes less time than asking about dependencies.
- `ls` on a directory is faster than asking what files exist.
- Reading the relevant function beats asking what it returns.

A labeled discovery step ("let me check what's already in the project
before asking anything") is always fine and often avoids the question
entirely. Only ask what genuinely requires a human decision.

## Ask 1–5 must-have questions

Keep the first pass small. Prioritize questions that eliminate whole
branches of work over questions that tune a specific detail.

### Format rules

- **Short and numbered.** Avoid paragraphs. One sentence per question.
- **Multiple-choice when possible.** Fewer decisions, faster response.
- **Bold the recommended default.** Mark it clearly so "go with the
  default" is a single-character reply.
- **Include a "not sure — use default" option** where it helps.
- **Separate "need to know" from "nice to know"** if the distinction
  reduces friction. Only the "need to know" block is blocking.
- **Provide a compact-reply format.** "Reply with `defaults` or
  `1a 2b 3c`."

### Template

```text
Before I start, I need:

Need to know:
1) Scope of the change?
   a) **Just this function (default)**
   b) This file end to end
   c) Related modules too
   d) Not sure — use default

2) Compatibility target?
   a) **Current project defaults (default)**
   b) Also support older: <specify>
   c) Not sure — use default

Nice to know (optional):
3) Style preference on X?
   a) **Match nearby code (default)**
   b) <alternative>

Reply with: `defaults`, or `1a 2a 3a`, or anything else.
```

Adapt the question count and axes to the actual request — don't ask
about compatibility if the change has no compatibility surface.

### Common templates

- "Before I start, I need: (1)…, (2)…, (3)…. If you don't care about
  (2), I will assume <default>."
- "Which of these should it be? A)… B)… C)… (pick one)"
- "What would you consider 'done'? For example: …"
- "Any constraints I must follow (versions, performance, style)? If
  none, I will target the existing project defaults."

## Pause before acting

Until the must-have questions are answered:

- **Do not** run commands that change state, edit files, or produce a
  detailed plan that depends on the unknowns.
- **Do** perform a clearly labeled, low-risk discovery step if it
  does not commit to a direction (inspect repo structure, read
  config files, check tool versions). Say what you are doing and why.

If the user explicitly asks to proceed without answers, state your
assumptions as a short numbered list and ask them to confirm before
starting work. Do not silently proceed on guessed assumptions.

## Restate before starting

Once answers arrive, restate the confirmed requirements in 1–3
sentences before beginning work. This catches misunderstandings while
they are still cheap to fix.

> "Confirmed: narrow refactor of `pkg/auth/token.go`'s `Validate()`
> function, keeping the public signature unchanged, targeting Go 1.22
> defaults. No tests being added beyond what already exists. Starting
> now."

## Relationship to phase-plan

This skill is the front door — it resolves interpretation. `phase-plan`
is the planning room — it resolves structure and detail for
non-trivial changes.

**Hand off to `phase-plan` when:**

- The clarified scope turns out to touch 3+ files or involve several
  ordered steps.
- The change has meaningful downstream effects (schema, API, shared
  state).
- The user asks for a plan explicitly.

**Do not hand off when:**

- The clarified scope is a one-file change with clear done-when.
- The change is a simple refactor with no new behavior.
- `phase-plan` would add ceremony without improving the outcome.

Phase-plan's Pass 1 uses a severity-based walk-through (BLOCKING /
PHASE-GATED / ADVISORY) rather than multiple-choice questions. Both
formats are intentional — multiple-choice is faster for independent
early-stage questions, severity-based is better for interdependent
planning-stage questions.

## Quality gates

Before asking questions, verify:

- You tried the discovery-read alternative. If grep, read, or
  `--help` would answer the question, use it instead.
- Each question would meaningfully change what you do. "Just curious"
  questions do not belong in the must-have set.
- Defaults are marked clearly so the fast path is a single reply.
- You have not started any state-changing work (edits, commits, calls
  to external APIs) before the must-have answers arrive.
