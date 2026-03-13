# Config Scout Report: shanraisshan/claude-code-best-practice (Full Repo)

**Source**: https://github.com/shanraisshan/claude-code-best-practice
**Date**: 2026-03-13
**Previous analysis**: 2026-03-13 (RPI workflow only — this covers the full repo)
**Local setup version**: 1adfe03

## Executive Summary

The shanraisshan repo is a documentation/reference hub cataloging Claude Code
features, not an opinionated development philosophy. Its primary value was
revealing frontmatter fields we weren't using (9 of 14 available), introducing
agent persistent memory, and providing a decision framework for choosing between
agents/commands/skills. Most adoptions were infrastructure hardening rather than
new capabilities.

## Source Overview

A reference catalog of Claude Code features: 6 best-practice docs, 2 workflows,
2 orchestration examples, 5 reports, and a CLAUDE.md. Documents 14 agent
frontmatter fields, 55+ settings, 140+ env vars, and architectural patterns
like Command→Agent→Skill. Different character from previous comparisons (RPI was
a product workflow, superpowers was a composable skill library) — this is
documentation, not philosophy.

## Coverage Heatmap

| Category | Local Depth | External Depth | Gap Direction |
|----------|------------|----------------|---------------|
| Testing | deep | none | ← local leads |
| Type safety | deep | none | ← local leads |
| Architecture | deep | none | ← local leads |
| Agent config | moderate | deep | → external leads (frontmatter fields, memory) |
| Decision frameworks | none | moderate | → external leads (agent vs command vs skill) |
| Context management | none | shallow | → external leads (compact guidance) |
| Orchestration | moderate | moderate | ≈ parity (different models) |
| Planning | deep | shallow | ← local leads |
| Code style | deep | none | ← local leads |
| Documentation | deep | none | ← local leads |

## Detailed Findings

### Overlaps

Both setups document agent orchestration patterns and emphasize progressive
disclosure (skills loaded on demand, not everything in CLAUDE.md). Both keep
CLAUDE.md under 200 lines. Both use commands for workflows.

### Novel in External Config

1. **Agent frontmatter fields** (9 we weren't using) — maxTurns, memory,
   permissionMode, skills preloading, disallowedTools, mcpServers, hooks,
   background, isolation
2. **Agent persistent memory** — three scopes (user/project/local), auto-inject
   first 200 lines of MEMORY.md into agent system prompt
3. **Agent vs Command vs Skill decision framework** — clear criteria and
   resolution order for choosing between primitives
4. **Command→Agent→Skill delegation hierarchy** — layered orchestration where
   commands invoke agents that preload skills
5. **Context management practices** — /compact at milestones, subtask sizing
   for context budget

### Local Strengths

1. Deep TDD enforcement with executable agent (not static docs)
2. Type safety across 3 languages with dedicated py-enforcer
3. DDD-grounded architecture skills
4. Functional programming as core principle
5. Testing anti-patterns catalogue with gate functions
6. Three-document progress system (PLAN/WIP/LEARNINGS)
7. Config-scout for systematic external comparison
8. Decision journal with deferred investigations tally system

### Philosophical Differences

**Reference vs philosophy**: shanraisshan documents what's available;
AlpheusCEF prescribes how to work. Different goals, complementary value.

**Delegation vs enforcement**: shanraisshan's Command→Agent→Skill is a
delegation hierarchy for building features. Our agent→agent pipelines are
verification chains for enforcing quality. Both are valid for their domains.

**Fixed thresholds vs judgment**: shanraisshan recommends "/compact at 50%."
We prefer awareness without arbitrary numbers — compact at natural milestones.

## Recommendations

### Adopted
1. `maxTurns` on all 9 agents (15 for analysis, 20 for complex work)
2. `memory: project` on learn, pr-reviewer, refactor-scan, tdd-guardian
3. Decision framework for agent vs command vs skill → agents.md
4. Context-budget awareness → progress-guardian plan review checklist

### Deferred
1. `permissionMode` field — needs testing with subagents
2. `skills` preloading field — current prose references work
3. Command→Agent→Skill delegation hierarchy — different paradigm
4. Workflow commands for agent sequences — problem doesn't exist (auto-invoke)

### Rejected
1. `/compact` at fixed 50% threshold — arbitrary
2. `disallowedTools` — redundant with allowlists
3. `mcpServers`, `hooks`, `background`, `isolation` — no use case
4. "Commands for workflows" as new principle — already implicit and correct

## Catalog Reference

Full item-by-item catalog: `config-scout/2026-03-13_shanraisshan-full-repo_catalog.md`
