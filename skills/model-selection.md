---
name: model-selection
description: >
  Guide for selecting Claude model, effort level, thinking mode, and temperature
  when building multi-agent systems or configuring API calls. Trigger when
  choosing between opus/sonnet, setting effort levels, enabling thinking modes,
  or optimizing cost/speed/quality tradeoffs. Based on empirical A/B data from
  a production multi-agent security audit pipeline.
---

# Model Selection for Claude API Applications

Choosing model, effort, thinking mode, and temperature is not a single decision
— it's a per-role decision based on what each agent actually does.

**Core principle: Match the configuration to the task type, not the perceived
importance.** Opus on a structured task wastes money and time. Sonnet on an
exploratory task misses findings. The model is a tool, not a status symbol.

---

## When to Trigger

Load this skill when:

- Choosing a model for a new agent or API call
- Configuring `effort`, `thinking`, or `temperature` parameters
- Optimizing a multi-agent pipeline for cost or speed
- Debugging slow API calls or max_tokens exhaustion
- Deciding whether to use adaptive thinking

---

## Task Type Taxonomy

Every agent call falls into one of two categories. Classify first, then
configure.

### Structured Tasks

Deterministic input-to-output mapping. The "right answer" is derivable from
the inputs. Run-to-run variance is a defect, not a feature.

**Characteristics:**
- JSON/structured output with constrained fields
- Enum-valued decisions (phase decomposition, merge/split, clear/retry)
- Classification, matching, or routing tasks
- The task has a "correct" answer given the inputs

**Optimal configuration:** Lower effort, disabled thinking, temp=0, cheaper model.

**Examples:** Phase planning, finding consolidation (merge/split), risk
calibration (entry matching), code generation from specs, data transformation,
schema validation.

### Exploratory Tasks

Open-ended investigation or narrative synthesis. Output quality depends on
creative reasoning, varied approaches, and depth of analysis.

**Characteristics:**
- Free-text narrative output (assessments, summaries, reports)
- Investigation tasks where varied approaches discover different things
- Judgment calls where the "right answer" is ambiguous
- Tasks where depth of reasoning correlates with quality

**Optimal configuration:** Higher effort, thinking enabled, temp>0, more
capable model.

**Examples:** Code investigation, security auditing, evidence evaluation,
quality assessment, spirit/narrative synthesis, architecture review.

### The Gray Zone: Structured + Qualitative

Some tasks have structured output but require qualitative judgment. The output
is JSON with enum fields, but the *decision* filling those fields requires
reasoning about quality, sufficiency, or risk.

**Characteristics:**
- Structured output format (JSON, enums)
- But the values require evaluating evidence, not just counting
- Edge cases exist where the decision is genuinely ambiguous

**Optimal configuration:** More capable model, but lower effort. The model
quality matters for the judgment; the effort level matters less because the
task is procedural enough that first-pass reasoning is usually sufficient.

**Examples:** Evidence evaluation (is this finding well-supported?), coverage
assessment (is 80% coverage sufficient given what's missing?), severity
calibration (is this truly CRITICAL or just HIGH?).

---

## Configuration Parameters

### Model Selection

```
┌─────────────────────────────────────────────────────┐
│ Task Type          │ Recommended Model              │
├─────────────────────────────────────────────────────┤
│ Structured         │ sonnet (fastest, cheapest)     │
│ Exploratory        │ opus (deepest reasoning)       │
│ Structured+Qual    │ opus at low effort             │
│ User-facing choice │ configurable (let user decide) │
└─────────────────────────────────────────────────────┘
```

**Data point:** In A/B testing across 135 API calls, sonnet-low produced
identical structured output to opus-high on planning tasks (6 phases, same
decomposition) at 6x faster and 6x cheaper. On the synthesizer (posture
assessment), 15/15 runs across all model/effort combos produced identical
posture decisions.

**Where opus adds measurable value:** Merge/split decisions in finding
consolidation. Sonnet-low produced 19.7 canonical findings vs opus-med's
24.0 from the same 36 inputs — sonnet merged more aggressively, losing
granularity. This is the one task type where model capability directly
affected output quality in A/B testing.

### Effort Parameter

The `effort` parameter (`low`, `medium`, `high`) controls how much
computation the model spends on reasoning. It is the **primary tuning knob**
for cost/speed — more impactful than model selection in many cases.

```
┌──────────────────────────────────────────────────────────────┐
│ Effort  │ Best For                        │ Watch Out        │
├──────────────────────────────────────────────────────────────┤
│ low     │ Structured tasks, routing,      │ May cut corners  │
│         │ classification, simple JSON     │ on edge cases    │
├──────────────────────────────────────────────────────────────┤
│ medium  │ Most tasks — good default       │ Balanced         │
├──────────────────────────────────────────────────────────────┤
│ high    │ Exploratory investigation,      │ Slow, expensive, │
│         │ complex multi-step reasoning    │ max_tokens risk  │
└──────────────────────────────────────────────────────────────┘
```

**Data points:**
- Planner: low=16s, med=24s, high=31s — all produced 6 phases. Low is
  sufficient for this structured task.
- Consolidator: effort correlates with canonical count (low=19.7,
  med=21.3, high=21.3 on sonnet). Higher effort = more careful splits.
- Synthesizer: low=57s, med=79s, high=81s — all produced HARM_LIKELY.
  Low is sufficient for posture decisions.

**Opus-low is unstable on some tasks.** Opus with `effort=low` +
`thinking=adaptive` produced a 4-phase outlier (1/3 runs) on a planning
task where all other combos consistently produced 6. The combination of
adaptive thinking + low effort on opus can cut structural corners. If using
opus, prefer `effort=medium` as the floor.

### Thinking Mode

```
┌───────────────────────────────────────────────────────────────────┐
│ Mode      │ When to Use                     │ Constraint          │
├───────────────────────────────────────────────────────────────────┤
│ adaptive  │ Opus on exploratory/qualitative  │ Requires temp=1.0   │
│           │ tasks where reasoning depth helps │ Shares max_tokens   │
├───────────────────────────────────────────────────────────────────┤
│ disabled  │ Sonnet (doesn't support adaptive)│ No constraint       │
│           │ OR any structured task           │                     │
├───────────────────────────────────────────────────────────────────┤
│ enabled   │ Rarely — fixed budget required   │ budget_tokens param │
│           │                                  │ max_tokens risk     │
└───────────────────────────────────────────────────────────────────┘
```

**Critical warning: adaptive thinking shares max_tokens.** On a consolidation
task with 36 findings, adaptive thinking generated a thinking block that
consumed all 16,384 max_tokens before producing any text output. The model
had to recover, re-read all inputs, and retry — doubling the total time and
cost. This is not a theoretical risk; it happened on the first production run.

**Rule of thumb:** If the task is structured enough that you'd set
`effort=low`, thinking should be `disabled`. The two are contradictory —
low effort says "don't think hard" while adaptive thinking says "think as
much as you want."

### Temperature

```
┌─────────────────────────────────────────────────────────────┐
│ Temp  │ When                             │ Constraint        │
├─────────────────────────────────────────────────────────────┤
│ 0     │ Structured tasks where you want  │ Requires thinking │
│       │ deterministic, reproducible output│ disabled or None  │
├─────────────────────────────────────────────────────────────┤
│ 1.0   │ Exploratory tasks, or when       │ Required when     │
│       │ thinking is enabled              │ thinking enabled  │
└─────────────────────────────────────────────────────────────┘
```

**Data point:** Planner at temp=0 vs temp=1 produced identical output and
identical timing across 9 runs. For tasks that are already deterministic,
temp=0 adds no value but also costs nothing. Use it for semantic clarity
("this task should be deterministic") rather than for practical effect.

**Implication for opus:** If temp=0 is right for a role, and opus requires
temp=1.0 for thinking, that's an argument for sonnet on that role. Opus with
disabled thinking + temp=0 is just expensive sonnet.

---

## Multi-Agent Pipeline Configuration

When building a pipeline with multiple agent roles, configure each role
independently:

```yaml
# Example: security audit pipeline
agents:
  planner:        # Structured: decompose audit into phases
    model: sonnet
    effort: low
    thinking: disabled
    temperature: 0

  investigator:   # Exploratory: read code, find issues
    model: opus          # or configurable per user preference
    effort: medium
    thinking: adaptive
    temperature: 1.0

  evaluator:      # Structured+Qualitative: judge evidence quality
    model: opus
    effort: low
    thinking: adaptive
    temperature: 1.0

  consolidator:   # Structured but nuanced: merge/split decisions
    model: opus
    effort: medium
    thinking: adaptive
    temperature: 1.0

  synthesizer:    # Narrative + structured posture decision
    model: sonnet
    effort: low
    thinking: disabled
    temperature: 1.0    # narrative benefits from variance
```

### Cost Optimization Strategy

1. **Start with sonnet-low everywhere.** Run the pipeline. Identify which
   agents produce degraded output.
2. **Upgrade only the degraded roles.** In practice, this is usually 1-2
   roles in a pipeline, not all of them.
3. **Effort before model.** Before switching from sonnet to opus, try
   increasing effort. Sonnet-high is often sufficient and cheaper than
   opus-low.
4. **A/B test with saved artifacts.** Replay agents against frozen inputs
   to compare output quality at different configurations. Speed/cost
   metrics without output comparison are insufficient.

---

## Anti-Patterns

### "Opus for everything"

Using the most capable model for all roles because "quality matters."
Quality matters *differently* per role. A planner that takes 90s and $0.51
on opus produces the same 6-phase decomposition that sonnet produces in 16s
for $0.09. The extra cost buys nothing.

### "High effort for safety"

Setting `effort=high` on all agents because "we don't want to miss
anything." High effort on structured tasks generates enormous thinking
blocks that consume max_tokens, trigger recovery cycles, and can double
both time and cost. High effort should be reserved for genuinely
exploratory tasks.

### Adaptive thinking on structured tasks

Enabling `thinking=adaptive` on a task that produces constrained JSON
output. The model generates thousands of thinking tokens reasoning about
a decision that has one correct answer given the inputs. Those thinking
tokens compete with output tokens for max_tokens budget.

### Ignoring the effort parameter

Choosing between sonnet and opus without considering effort. The effort
parameter often has more impact on output quality than model selection.
Opus-low can underperform sonnet-medium on some tasks due to the
interaction between adaptive thinking and low effort producing
inconsistent results.

### "Temperature 0 for reliability"

Setting temp=0 expecting more reliable output. On tasks that are already
deterministic (structured output, constrained enums), temp=0 and temp=1
produce identical results. On tasks that benefit from varied reasoning
(investigation, narrative), temp=0 actively hurts quality by eliminating
the exploration that finds non-obvious answers.

---

## Measuring Model Selection Decisions

### What to measure

1. **Output quality** — Does the output change when you downgrade? Save
   full outputs and diff them, not just metrics.
2. **Consistency** — Run 3x at each configuration. If results vary, the
   task has non-deterministic elements that may benefit from a better model.
3. **Speed** — Wall clock per call, including all turns for multi-turn agents.
4. **Cost** — Total cost including recovery cycles and retries.
5. **Max-tokens hits** — Any configuration that exhausts max_tokens is
   misconfigured, regardless of output quality.

### What NOT to measure

- **Single-run comparisons.** One run can be an outlier. Always use 3+.
- **Speed without quality.** Fast and wrong is worse than slow and right.
- **Quality on easy inputs.** Test on edge cases — the easy cases will
  pass regardless of configuration. A judge that clears a 100%-coverage
  phase tells you nothing about how it handles 70% coverage.

---

## Quick Reference

```
Structured task?
  ├─ Yes → sonnet, effort=low, thinking=disabled, temp=0
  │        (planning, routing, classification, data transform)
  │
  ├─ Mostly, but needs judgment → opus, effort=low, thinking=adaptive, temp=1.0
  │        (evaluation, calibration, quality assessment)
  │
  └─ No, exploratory → opus, effort=medium, thinking=adaptive, temp=1.0
           (investigation, code review, narrative synthesis)

Multi-turn tool agent?
  └─ Bottleneck is turn count, not model speed.
     Reduce tool interaction chattiness before upgrading model.
```
