# Config Scout Report: obra/superpowers

**Source**: https://github.com/obra/superpowers
**Date**: 2026-03-13
**Previous analysis**: none
**Local setup version**: a98a6df
**Catalog**: `config-scout/2026-03-13_obra-superpowers_catalog.md`

## Executive Summary

Superpowers is a plugin-based workflow system with 14 skills, 1 agent, and
multi-platform distribution (Claude Code, Cursor, Codex, Gemini). It shares
TDD-first philosophy with AlpheusCEF but approaches agent design differently —
superpowers uses skills as workflow guides while AlpheusCEF uses agents as
discipline enforcers. The most valuable takeaways were filling two genuine gaps
(systematic debugging, verification before completion), tightening TDD
enforcement phrasing, adding plan alignment to PR reviews, defining agent
orchestration sequences, and establishing skill hygiene practices.

## Source Overview

Superpowers is designed as a composable skill library for coding agents. Core
philosophy: design-first → plan → implement via subagents → two-stage review.
The system emphasizes structured planning with human gates, TDD as non-negotiable,
and systematic processes over ad-hoc approaches.

Maturity: Well-maintained open source project by Jesse Vincent (obra). Published
as a plugin on multiple platforms. Has tests, release notes, and documentation
plans dating back to late 2025. More mature than the RPI workflow we previously
analyzed.

## Coverage Heatmap

| Category | Local Depth | External Depth | Gap Direction |
|----------|------------|----------------|---------------|
| Testing | deep | moderate | ← local leads (agent + anti-patterns + mock gate) |
| Type safety | deep | none | ← local leads (py-enforcer, 3-language coverage) |
| Debugging | none | moderate | → external leads (systematic-debugging) |
| Verification | shallow | deep | → external leads (verification-before-completion) |
| Architecture | deep | none | ← local leads (DDD, hexagonal, ADR) |
| Planning | deep | deep | ≈ parity (different strengths) |
| Code review | deep | moderate | ← local leads (detection patterns, GitHub integration) |
| Orchestration | none | deep | → external leads (subagent dispatch patterns) |
| Skill meta | none | moderate | → external leads (writing-skills, TDD for skills) |
| Code style | deep | none | ← local leads (functional, immutability) |
| Documentation | deep | moderate | ← local leads (docs-guardian 7 pillars) |

## Detailed Findings

### Overlaps

**TDD as non-negotiable**: Both systems treat TDD as the foundational practice.
Near-identical phrasing: "NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST."
Superpowers' "watched-it-fail" principle matches AlpheusCEF verbatim.

**Plan-then-execute workflow**: Both require planning before implementation.
Different structures (superpowers: single plan doc; AlpheusCEF: PLAN/WIP/LEARNINGS)
but same principle.

**Code review as a gate**: Both have dedicated review agents with severity tiers.

**Commit discipline**: Both require approval before commits.

### Novel in External Config (adopted)

1. **Verification before completion** — "No completion claims without fresh
   evidence." Added to CLAUDE.md Development Workflow.
2. **Systematic debugging** — Four-phase framework. Created as new skill.
3. **TDD phrasing tighteners** — 5-step sacred cycle, scope definition, "spirit
   over ritual" rationalization, deletion mandate, crisper one-liners.
4. **Plan alignment in code review** — Category 0 added to pr-reviewer.
5. **Agent orchestration sequences** — Added to agents.md.
6. **Task granularity and specificity** — Enhanced progress-guardian step templates.
7. **Skill hygiene** — New skill for maintaining instruction set quality.

### Local Strengths

1. Deep TDD enforcement via executable agent (not just a static skill)
2. Type safety across 3 languages with dedicated py-enforcer agent
3. DDD-grounded architecture skills (effective-design-overview, hexagonal)
4. Functional programming as a core principle (immutability, pure functions)
5. Three-document progress system (PLAN/WIP/LEARNINGS) with learning merge
6. Testing anti-patterns catalogue with gate functions
7. Mock decision gate (superpowers has no mocking guidance)
8. External API discipline
9. Config-scout for systematic external comparison

### Philosophical Differences

**Skill vs agent paradigm**: Superpowers uses skills as workflow descriptions
that Claude follows. AlpheusCEF uses agents as independent enforcers that
verify compliance. Both work; ours is more verifiable.

**Distribution model**: Superpowers is designed as a distributable plugin
(marketplace, multi-platform). AlpheusCEF is designed as shared infrastructure
across a project's repos (symlinks, @imports). Different goals.

**Subagent orchestration**: Superpowers dispatches subagents as task executors
(implement this feature). AlpheusCEF dispatches agents as validators (check this
work). We adopted the orchestration patterns but adapted to our enforcement model.

## Recommendations (all adopted)

### Quick Wins (implemented)
1. Verification-before-completion → CLAUDE.md
2. TDD 5-step cycle, scope definition, "spirit over ritual" → tdd-guardian.md
3. Deletion mandate ("delete and restart") → tdd-guardian.md
4. Crisper one-liner ("tests passing immediately prove nothing") → tdd-guardian.md

### Worth Investigating (implemented)
5. Systematic debugging skill → skills/systematic-debugging.md (new)
6. Plan alignment in PR review → pr-reviewer.md Category 0
7. Agent orchestration sequences → agents.md
8. Task granularity and step specificity → progress-guardian.md
9. Skill hygiene discipline → skills/skill-hygiene.md (new)

### Noted but Skipped
- Plugin/marketplace distribution model — different scope
- Brainstorming skill — covered by effective-design-overview
- Git worktree management — operational, not philosophical
- Using-superpowers self-referential skill — not transferable
- UX designer / visual companion — outside our domain

## Raw Notes

- Superpowers' `writing-skills` skill applies TDD to skill authoring. We
  adopted this principle into skill-hygiene.md. The insight that you should
  observe baseline failures before writing a skill is powerful.
- The "Adopt > adapt > invent" principle from the RPI analysis appears again
  implicitly in superpowers — prefer existing patterns over novel approaches.
  Two independent sources converging on this idea. Added to deferred
  investigations in DECISIONS.md? (No — it's a principle, not a feature.)
- Superpowers' receiving-code-review skill has an interesting angle: how to
  evaluate review feedback with technical rigor rather than performative
  agreement. Worth revisiting if we expand pr-reviewer to cover the feedback
  recipient's side.
- The session-start hook pattern (auto-loading context at session begin) is
  interesting but not something we need now. Our @import system serves a
  similar purpose.
