# Agent Setup for AlpheusCEF Repos

All AlpheusCEF repos share a single set of Claude Code agents and instructions maintained in this repo. This document explains how the wiring works and how to set up a new repo.

## Design context

See [overview/STATE.md](../overview/STATE.md) for the full project design and [overview/PLAN.md](../overview/PLAN.md) for the implementation roadmap.

## How it works

Claude Code loads instructions and agents from a project's `.claude/` directory. Instead of each repo maintaining its own copies, repos wire in the shared files using:

- **`@` imports** for `CLAUDE.md` — Claude Code inlines the referenced file at load time. Each repo's `.claude/CLAUDE.md` is a single line pointing here.
- **Symlinks** for agents — each repo's `.claude/agents/` contains symlinks pointing to the agent `.md` files in this repo. Editing an agent file here is immediately reflected in all repos.

`settings.local.json` is **not** shared — it holds per-repo permission allowlists and stays in each repo.

## Wiring a new repo

From the new repo root:

```bash
# 1. Create .claude structure
mkdir -p .claude/agents .claude/commands

# 2. Point CLAUDE.md at the shared instructions
AGENTS=/Users/cpettet/git/chasemp/AlpheusCEF/agents
echo "@${AGENTS}/CLAUDE.md" > .claude/CLAUDE.md

# 3. Symlink each agent
for agent in tdd-guardian py-enforcer pr-reviewer refactor-scan progress-guardian adr docs-guardian learn use-case-data-patterns; do
  ln -sf "${AGENTS}/${agent}.md" ".claude/agents/${agent}.md"
done

# 4. Symlink commands
for f in "${AGENTS}"/commands/*.md; do
  ln -sf "$f" ".claude/commands/$(basename $f)"
done

# 5. Write a per-repo settings.local.json (see an existing repo for a template)

# 6. Add agents.md at the repo root (copy and update from agents/agents.md)
```

## Agent Orchestration

Agents are discipline enforcers, not task executors. They verify that work meets
standards — they do not perform the implementation. The sequences below define
when to invoke which agents and how their outputs relate.

### Recommended Sequences

**TDD Cycle** (every RED-GREEN-REFACTOR iteration):
```
tdd-guardian (blocking) → refactor-scan (advisory)
```
tdd-guardian verifies test-first compliance. If it flags violations, stop and
fix before proceeding. refactor-scan runs after GREEN to assess improvement
opportunities — its output is advisory (refactoring is not always needed).

**PR Preparation** (before creating a pull request):
```
progress-guardian (plan alignment, blocking) → pr-reviewer (code quality, blocking) → docs-guardian (advisory)
```
progress-guardian checks that the work matches what was planned. pr-reviewer
checks code quality across 5 categories. docs-guardian checks if documentation
needs updating. Do not start code quality review before plan alignment passes.

**Post-Merge** (after work is merged):
```
learn (capture learnings)
```
Invoke learn to capture gotchas, patterns, and decisions while context is fresh.

**Architecture Decisions** (when evaluating design choices):
```
effective-design-overview skill → adr (record decision)
```
Use the design skill to evaluate the problem space, then adr to record the
decision and its rationale.

**Python Code** (when writing or reviewing Python):
```
py-enforcer (blocking, can run in parallel with tdd-guardian)
```
py-enforcer checks type safety independently of TDD compliance. Both can run
on the same changeset without interference.

### Dependency Rules

- **Blocking** agents must pass before proceeding. Do not skip or defer their findings.
- **Advisory** agents produce recommendations. Their output informs but does not gate.
- progress-guardian before pr-reviewer — plan alignment first, then code quality.
- tdd-guardian before refactor-scan — verify TDD compliance before assessing refactoring.
- Never run docs-guardian before pr-reviewer — fix code issues before documenting.

### Escalation Convention

When an agent finds something ambiguous — not a clear violation, but a concern —
it should flag it as:

```
⚠️ ESCALATION: [description of concern]
Recommendation: [what the agent suggests]
Decision needed: [what the human should weigh in on]
```

This format is consistent across all agents and signals that the agent is not
blocking but needs human judgment.

## File reference

| File | Role |
|------|------|
| `CLAUDE.md` | Core TDD/type-safety/style rules — imported by all repos |
| `tdd-guardian.md` | Enforces RED-GREEN-REFACTOR, catches test-after violations |
| `py-enforcer.md` | Enforces type annotations, immutability, no standalone `Any` |
| `pr-reviewer.md` | Reviews PRs for correctness, test coverage, and style |
| `refactor-scan.md` | Identifies refactoring opportunities after green |
| `progress-guardian.md` | Tracks WIP state and implementation progress |
| `adr.md` | Writes Architecture Decision Records |
| `docs-guardian.md` | Keeps documentation consistent with implementation |
| `learn.md` | Captures learnings and gotchas while context is fresh |
| `use-case-data-patterns.md` | Analyses use case and data modelling patterns |
| `commands/` | Slash commands (`/pr`, `/generate-pr-review`) |
