# Config Scout Report: shanraisshan/claude-code-best-practice (RPI Workflow)

**Source**: https://github.com/shanraisshan/claude-code-best-practice/blob/main/development-workflows/rpi/rpi-workflow.md
**Date**: 2026-03-13
**Previous analysis**: none
**Local setup version**: a98a6df

## Executive Summary

The RPI (Research-Plan-Implement) workflow is a heavyweight, gate-driven feature
development system with specialized role-based agents (product manager, CTO
advisor, UX designer, code reviewer, documentation writer). It fills a different
niche than AlpheusCEF — RPI is focused on the *feature lifecycle* (should we
build it? how? execute.), while AlpheusCEF is focused on *code quality
disciplines* (TDD, types, architecture patterns). The most valuable takeaways
are the explicit GO/NO-GO research gate, the structured feature folder
convention, and the phased implementation with human validation checkpoints.

## Source Overview

The repo documents Claude Code best practices across 8 feature categories
(commands, agents, skills, hooks, MCP, plugins, settings, workflows). The RPI
workflow is the centerpiece — a three-stage gated system:

1. **Research** — GO/NO-GO feasibility analysis with product + technical assessment
2. **Plan** — Multi-perspective spec generation (PM, UX, eng, implementation roadmap)
3. **Implement** — Phased execution with validation gates at each phase

It uses 7 specialized agents playing distinct organizational roles (requirement
parser, product manager, senior engineer, CTO advisor, UX designer, code
reviewer, documentation writer). The philosophy is waterfall-influenced with
explicit human approval gates — quite different from AlpheusCEF's TDD-driven
incremental approach.

**Apparent maturity**: Well-structured teaching example. The repo positions itself
as "best practices" documentation rather than a battle-tested team config. The
agents are role-play oriented (CTO advisor with "blue theme") rather than
behavior-verification oriented.

## Comparison Matrix

| Dimension | Overlap | External Only | Local Only | Conflicts |
|-----------|---------|---------------|------------|-----------|
| Testing | Both mention TDD | — | Deep TDD enforcement, anti-patterns, mutation testing | — |
| Types | — | — | Strict type safety across 3 languages, py-enforcer | — |
| Architecture | Both have architecture guidance | CTO-level strategic evaluation | DDD-grounded design, hexagonal architecture skill | Approach differs |
| Workflow | Both have phased workflows | GO/NO-GO research gate, feature folders | RED-GREEN-REFACTOR micro-cycle, progress-guardian | Granularity differs |
| Code style | Both mention clarity | — | Functional programming, immutability, detailed conventions | — |
| Agents | Both use specialized agents | Role-based personas (PM, UX, CTO) | Discipline-based verification (TDD, types, refactoring) | Philosophy differs |
| Documentation | Both value docs | Multi-format doc generation (pm/ux/eng) | docs-guardian 7 pillars, doc-sync automation | — |
| Code review | Both have review | Phase-gate validation with retry limits | PR-reviewer with 5-category scoring | — |
| Feature planning | Both plan | Structured feature folders with REQUEST/RESEARCH/PLAN/IMPLEMENT | PLAN.md/WIP.md/LEARNINGS.md system | — |

## Detailed Findings

### Overlaps

**Development workflow structure**: Both systems recognize that significant work
needs phases with checkpoints. RPI uses Research/Plan/Implement. AlpheusCEF uses
RED/GREEN/REFACTOR at the micro level and PLAN/WIP/LEARNINGS at the macro level.

**Code review as a gate**: Both include automated code review agents. RPI's
code-reviewer focuses on correctness, security, and maintainability. AlpheusCEF's
pr-reviewer covers TDD compliance, type safety, functional patterns, and general
quality. Both produce structured output with severity tiers.

**Documentation emphasis**: Both treat documentation as a first-class concern
with dedicated agents/patterns for maintaining it.

**Test-driven development**: RPI's senior-software-engineer agent mentions TDD
with atomic commits. AlpheusCEF makes TDD the non-negotiable foundation of
everything.

### Novel in External Config

**1. GO/NO-GO Research Gate**
- **What**: Before any planning or coding, a structured research phase evaluates
  product-market fit, technical feasibility, and strategic alignment. Produces an
  explicit GO/NO-GO/CONDITIONAL/DEFER recommendation.
- **Relevance**: HIGH — AlpheusCEF has no equivalent "should we build this?"
  gate. We jump straight from idea to TDD implementation.
- **Effort**: Moderate — would need a new command and possibly a research agent.
- **Where**: New `commands/research-gate.md` or integrate into progress-guardian.
- **Verbatim worth noting**: "Prevents wasted effort on non-viable features."

**2. Structured Feature Folder Convention**
- **What**: Each feature gets `rpi/{feature-slug}/` with REQUEST.md, research/,
  plan/, implement/ subdirectories. Creates a persistent, navigable record of the
  full feature lifecycle.
- **Relevance**: MEDIUM — AlpheusCEF's PLAN/WIP/LEARNINGS are transient
  within a conversation. A persistent folder structure would help with
  longer-running features that span multiple sessions.
- **Effort**: Moderate — needs convention definition and progress-guardian updates.
- **Where**: Could extend progress-guardian or create a new command.

**3. Multi-Perspective Planning (PM/UX/Eng specs)**
- **What**: The plan phase generates separate documents from product, UX, and
  engineering perspectives before implementation begins.
- **Relevance**: LOW for AlpheusCEF's current scope — we are focused on
  developer tools and CLI apps, not user-facing product features with UX
  concerns. However, the principle of examining a problem from multiple angles
  before coding is sound.
- **Effort**: Significant — would need role-based agents we don't have.
- **Where**: N/A unless scope expands to product features.

**4. Implementation Retry Limits**
- **What**: "After two unsuccessful attempts at alternative approaches, workflow
  halts and requests user guidance."
- **Relevance**: MEDIUM — a good guardrail against infinite loops. AlpheusCEF
  doesn't have explicit retry limits.
- **Effort**: Trivial — add to agent guidelines or CLAUDE.md.
- **Where**: CLAUDE.md development workflow section or individual agents.

**5. Constitutional/Principles Document**
- **What**: RPI references an optional "project constitution" that agents check
  alignment against. A meta-document defining what the project values.
- **Relevance**: LOW — AlpheusCEF's CLAUDE.md already serves this purpose with
  its explicit philosophy section. The naming is interesting but the function is
  covered.
- **Effort**: N/A
- **Where**: Already covered.

**6. Explicit Agent Model Selection**
- **What**: RPI specifies `model: opus` on complex reasoning agents and leaves
  simpler agents on default. Deliberate model tier assignment by task complexity.
- **Relevance**: MEDIUM — AlpheusCEF agents don't specify model preferences.
  As model capabilities diverge, this becomes more relevant.
- **Effort**: Trivial — add model frontmatter to agent definitions.
- **Where**: Individual agent .md files.

### Local Strengths (Unique to AlpheusCEF)

1. **Deep TDD enforcement** — tdd-guardian agent, testing-anti-patterns skill,
   watch-the-fail principle. RPI mentions TDD in passing; AlpheusCEF makes it
   the foundation with active verification.

2. **Type safety across 3 languages** — py-enforcer agent, TypeScript strict
   mode, Go patterns. RPI has no type safety guidance.

3. **DDD-grounded architecture** — effective-design-overview provides a
   strategic framework for choosing patterns. hexagonal-architecture provides
   tactical implementation. RPI's CTO advisor is role-play; AlpheusCEF's
   architecture skills are pattern-based.

4. **Functional programming discipline** — Immutability, pure functions, no
   mutation as core principles. RPI doesn't address code style at this level.

5. **Refactoring as a discipline** — refactor-scan agent with semantic vs
   structural duplication analysis. RPI has no refactoring guidance.

6. **Learning capture** — learn agent and LEARNINGS.md create a feedback loop.
   RPI's documentation is forward-looking (specs) but doesn't capture what was
   learned during implementation.

7. **Skill-based progressive disclosure** — CLAUDE.md stays lean (~100 lines)
   with skills loaded on demand. RPI loads everything into agent definitions
   upfront.

8. **External API discipline** — "Never guess or infer API endpoints." RPI has
   no equivalent boundary for external integrations.

### Philosophical Differences

**Agent design philosophy**:
- RPI: Agents are *organizational roles* (PM, CTO, UX designer). They simulate
  a team structure. This is intuitive but means agents carry a lot of generic
  role context that may not be relevant.
- AlpheusCEF: Agents are *discipline enforcers* (TDD, types, refactoring). They
  verify specific quality dimensions. This is more focused but means there's no
  "big picture" strategic agent.
- **Tradeoff**: Role-based agents feel natural for product features. Discipline
  agents are more effective for code quality. These aren't mutually exclusive.

**Workflow granularity**:
- RPI: Macro phases (Research → Plan → Implement) with human gates between them.
  Days-to-weeks scale.
- AlpheusCEF: Micro cycles (RED → GREEN → REFACTOR) with continuous flow.
  Minutes-to-hours scale.
- **Tradeoff**: RPI is better for "should we build this feature?" decisions.
  AlpheusCEF is better for "how do we build this correctly?" execution. Both are
  needed at different scales.

**Documentation timing**:
- RPI: Heavy upfront documentation (specs before code).
- AlpheusCEF: Documentation emerges from implementation (learnings captured
  during and after).
- **Tradeoff**: Upfront docs prevent misalignment but can become stale. Emergent
  docs are more accurate but may miss strategic context.

## Recommendations

### Quick Wins

1. **Add retry/bail limits to agent guidelines** — "After N failed attempts,
   stop and ask the user." Prevents agents from spinning. Add to CLAUDE.md
   development workflow section. Could be as simple as: "If an approach fails
   twice, pause and reassess with the user before trying alternatives."

2. **Add model tier hints to agent definitions** — Add `model: opus` or
   `model: sonnet` frontmatter to agents where task complexity warrants it. The
   tdd-guardian and refactor-scan could run on sonnet; pr-reviewer and adr may
   benefit from opus for deeper reasoning.

### Worth Investigating

3. **Research/feasibility gate for significant features** — A lightweight
   version of RPI's research phase. Not the full 5-phase pipeline, but a
   structured "before you start coding, answer: Is this the right thing to build?
   What are the risks? What's the simplest viable approach?" Could be a new
   command or an extension to progress-guardian's PLAN.md step.

4. **Persistent feature folders** — For work that spans multiple sessions,
   a convention like `features/{slug}/` with PLAN.md, LEARNINGS.md, and
   implementation notes that persist beyond a single conversation. The
   progress-guardian's three-document model is good but ephemeral.

### Nice to Have

5. **Multi-perspective pre-implementation review** — Before coding a significant
   feature, explicitly consider it from at least two angles (e.g., "what would a
   user expect?" and "what would break?"). Lighter than RPI's full PM/UX/eng
   split but captures the value of diverse viewpoints.

6. **Feature lifecycle documentation** — A template for capturing the full arc
   of a feature: motivation, research, decisions, implementation, outcomes. RPI's
   folder structure does this. AlpheusCEF could do a lighter version as part of
   ADR or progress-guardian.

### Noted but Skipped

7. **Role-based agent personas** (PM, CTO, UX designer) — Does not fit
   AlpheusCEF's discipline-verification philosophy. Role-play agents carry
   generic context and are harder to verify. Our discipline-based agents are more
   testable and focused. *However*, the strategic thinking that a "CTO advisor"
   provides is valuable — we get this through effective-design-overview and ADR
   instead.

8. **Heavyweight waterfall-style planning** — RPI's Research → Plan → Implement
   pipeline with 5+ phases and multiple agent handoffs. Too heavy for the
   incremental, TDD-first approach. The overhead would conflict with the
   principle of small, working increments.

9. **Agent color/theme metadata** — RPI assigns colors to agents ("Blue" for
   CTO, "Purple" for UX). Cosmetic; no functional value in a CLI context.

## Raw Notes

- The broader repo has 30+ tips beyond RPI. Worth a separate scan of the main
  README for Claude Code usage patterns (context management, debugging,
  screenshots, background tasks).
- RPI's `constitutional-validator` agent is mentioned in implement.md but not
  defined in the agents directory — possibly aspirational or in another branch.
- The repo positions itself as replacing startup tools (Greptile, CodeRabbit,
  OpenClaw) — interesting framing for what agent configs can displace.
- RPI's documentation-analyst-writer agent has a good principle: "Study existing
  documentation to understand established patterns before writing." This is
  already implicit in AlpheusCEF's docs-guardian but could be made more explicit.
- The "Adopt > adapt > invent" principle from the senior-software-engineer agent
  is well-phrased. Worth considering as a general principle for AlpheusCEF —
  prefer using what exists over building new.
