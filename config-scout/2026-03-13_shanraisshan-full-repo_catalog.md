# Config Scout Catalog: shanraisshan/claude-code-best-practice (Full Repo)

**Source**: https://github.com/shanraisshan/claude-code-best-practice
**Date**: 2026-03-13
**Previous analysis**: 2026-03-13 (RPI workflow only — this covers the full repo)
**Total items**: 6 best-practice docs, 2 workflows, 2 orchestration examples, 5 reports, CLAUDE.md, implementation guides

---

## Nature of Source

This repo is a **documentation/reference hub**, not a working agent config. It
catalogs Claude Code features, settings, and patterns rather than defining a
development philosophy. Most value comes from configuration reference material
and architectural patterns, not from principles or skills to adopt.

---

## Best Practice Docs

| # | Doc | Category | Local Equivalent | Relevance | Notes |
|---|-----|----------|-----------------|-----------|-------|
| 1 | claude-commands.md | Reference | (none) | MEDIUM | Complete list of 60 built-in commands with 4 frontmatter fields. Useful reference, not philosophy. |
| 2 | claude-skills.md | Reference | skill-hygiene skill | MEDIUM | 10 frontmatter fields documented. We should verify our skills use all relevant fields. |
| 3 | claude-subagents.md | Reference | agents.md | HIGH | 14 frontmatter fields for agents. Several we may not be using (maxTurns, permissionMode, memory, skills preloading, hooks, isolation). |
| 4 | claude-settings.md | Reference | (none) | MEDIUM | 55+ settings, 140+ env vars. Reference material. Some settings could improve our workflow. |
| 5 | claude-memory.md | Reference | (none) | LOW | CLAUDE.md loading mechanics. We already understand this from our @import pattern. |
| 6 | CLAUDE.md | Config | CLAUDE.md | HIGH | Their CLAUDE.md is a project-config example. Has Command→Agent→Skill architecture pattern and workflow best practices worth comparing. |

## Workflows

| # | Workflow | Category | Local Equivalent | Relevance | Notes |
|---|---------|----------|-----------------|-----------|-------|
| 7 | RPI Workflow | Workflow | (analyzed separately) | — | Already analyzed in previous report. Skip. |
| 8 | Cross-Model Workflow | Workflow | (none) | LOW | Claude Code + Codex CLI pattern. Not relevant — we're single-model. |

## Orchestration Examples

| # | Example | Category | Local Equivalent | Relevance | Notes |
|---|---------|----------|-----------------|-----------|-------|
| 9 | Command→Agent→Skill pattern | Architecture | agents.md orchestration | HIGH | Concrete example of layered orchestration. Compare to our new orchestration sequences. |
| 10 | Agent Teams pattern | Architecture | (none) | MEDIUM | Multi-agent parallel dev with data contracts. Interesting but we don't do parallel agent execution yet. |

## Reports

| # | Report | Category | Local Equivalent | Relevance | Notes |
|---|--------|----------|-----------------|-----------|-------|
| 11 | claude-agent-command-skill.md | Architecture | agents.md | HIGH | When to use agent vs command vs skill. Clear decision framework we lack. |
| 12 | claude-agent-memory.md | Reference | (none) | HIGH | Agent persistent memory across sessions. We have no memory guidance for agents. |
| 13 | claude-skills-for-larger-mono-repos.md | Reference | (none) | LOW | Skill discovery in monorepos. Not our architecture. |
| 14 | claude-advanced-tool-use.md | Reference | (none) | LOW | PTC, dynamic filtering, tool search — API-level features, not CLI config. |
| 15 | llm-day-to-day-degradation.md | Meta | (none) | MEDIUM | Interesting meta-topic but couldn't fetch content. |

## CLAUDE.md Best Practices (from their CLAUDE.md)

| # | Practice | Category | Local Equivalent | Relevance | Notes |
|---|---------|----------|-----------------|-----------|-------|
| 16 | "Keep CLAUDE.md under 200 lines" | Skill hygiene | skill-hygiene skill | ALREADY COVERED | We have this in skill-hygiene. |
| 17 | "Use commands for workflows instead of standalone agents" | Architecture | agents.md | HIGH | We have this as practice but haven't codified it. |
| 18 | "Create feature-specific subagents with skills (progressive disclosure)" | Architecture | agents.md | MEDIUM | Relates to our orchestration patterns. |
| 19 | "Perform manual /compact at ~50% context usage" | Workflow | (none) | MEDIUM | Practical tip we haven't documented. |
| 20 | "Break subtasks small enough to complete in under 50% context" | Workflow | progress-guardian | MEDIUM | Related to our task granularity guidance. |
| 21 | "Start with plan mode for complex tasks" | Workflow | progress-guardian | LOW | We use progress-guardian instead. |

---

## Relevance Summary

**HIGH (6 items):** claude-subagents.md (#3), CLAUDE.md (#6), Command→Agent→Skill
pattern (#9), agent-command-skill report (#11), agent-memory report (#12),
"commands for workflows" practice (#17)

**MEDIUM (7 items):** claude-commands.md (#1), claude-skills.md (#2),
claude-settings.md (#4), agent teams (#10), degradation report (#15),
progressive disclosure (#18), /compact guidance (#19), subtask sizing (#20)

**LOW (4 items):** claude-memory.md (#5), cross-model workflow (#8),
monorepo skills (#13), advanced tool use (#14)

**ALREADY COVERED (1):** CLAUDE.md line limit (#16)

**PREVIOUSLY ANALYZED (1):** RPI workflow (#7)
