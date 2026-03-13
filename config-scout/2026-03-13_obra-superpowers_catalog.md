# Config Scout Catalog: obra/superpowers

**Source**: https://github.com/obra/superpowers
**Date**: 2026-03-13
**Total items**: 14 skills, 1 agent, 3 deprecated commands, hooks system
**Philosophy**: Plugin-based workflow system for coding agents. Design-first,
TDD-enforced, subagent-orchestrated development with structured planning and
two-stage code review.

---

## Skills Inventory

| # | Skill | Category | Local Equivalent | Relevance | Notes |
|---|-------|----------|-----------------|-----------|-------|
| 1 | test-driven-development | Testing | tdd-guardian agent | HIGH | Direct overlap. Compare enforcement approaches. |
| 2 | systematic-debugging | Debugging | (none) | HIGH | We have no debugging skill/agent. New capability area. |
| 3 | verification-before-completion | Quality | (none) | HIGH | "No completion claims without fresh verification." We lack this. |
| 4 | writing-plans | Workflow | progress-guardian agent | HIGH | Compare plan structures and granularity. |
| 5 | executing-plans | Workflow | progress-guardian agent | MEDIUM | Plan execution with worktree integration. |
| 6 | subagent-driven-development | Orchestration | (none) | HIGH | Subagent dispatch patterns. We use agents but lack orchestration guidance. |
| 7 | dispatching-parallel-agents | Orchestration | (none) | MEDIUM | When/how to parallelize. Useful but narrower. |
| 8 | writing-skills | Meta | config-scout command | MEDIUM | TDD applied to skill writing. Meta-skill creation patterns. |
| 9 | brainstorming | Design | effective-design-overview | MEDIUM | Design-first discipline vs our architecture selection. Different angles. |
| 10 | requesting-code-review | Code Review | pr-reviewer agent | MEDIUM | Process for requesting reviews. Our pr-reviewer is the review itself. |
| 11 | receiving-code-review | Code Review | (none) | MEDIUM | How to evaluate and respond to feedback. Novel angle. |
| 12 | using-git-worktrees | Tooling | (none) | LOW | Worktree management. Useful but operational, not philosophical. |
| 13 | finishing-a-development-branch | Workflow | pr command | LOW | Branch completion. Our /pr command covers similar ground. |
| 14 | using-superpowers | Meta | (none) | LOW | Self-referential — how to use the superpowers system. Not transferable. |

## Agent

| Agent | Category | Local Equivalent | Relevance | Notes |
|-------|----------|-----------------|-----------|-------|
| code-reviewer | Code Review | pr-reviewer agent | HIGH | Compare review categories and severity frameworks. |

## Other

| Item | Category | Local Equivalent | Relevance | Notes |
|------|----------|-----------------|-----------|-------|
| hooks/session-start | Tooling | (none) | MEDIUM | Session initialization hook. Interesting pattern. |
| Plugin system (marketplace) | Distribution | (none) | LOW | Multi-platform plugin packaging. Not relevant to our scope. |

---

## Relevance Summary

**HIGH (6 items):** test-driven-development, systematic-debugging,
verification-before-completion, writing-plans, subagent-driven-development,
code-reviewer agent

**MEDIUM (6 items):** executing-plans, dispatching-parallel-agents,
writing-skills, brainstorming, requesting-code-review, receiving-code-review,
session-start hook

**LOW (3 items):** using-git-worktrees, finishing-a-development-branch,
using-superpowers
