# Coding Agent Setup

This repo provides shared Claude Code agents, skills, commands, and instructions.
It is installed globally at `~/.claude/coding-agents/` and loaded via
`~/.claude/CLAUDE.md` `@` includes.

Org-specific repos (AlpheusCEF/coding-agents, mycelium-agent-framework/coding-agents)
layer on top with org-only content. See those repos' READMEs for org setup.

## How it works

Claude Code loads instructions and agents from `~/.claude/` (global) and a
project's `.claude/` directory (project-local). This repo provides the global
layer:

- **`@` imports** in `~/.claude/CLAUDE.md` pull in `CLAUDE.md` and `agents.md`
  from this repo at load time.
- **Symlinks** in `~/.claude/commands/` point to skills in this repo for
  slash-command access.
- **Agent definitions** are available to Claude via the global `.claude/agents/`
  directory or via symlinks from project repos.
- **Hooks** in `~/.claude/hooks/` (symlinked from this repo) enforce TDD
  programmatically via Claude Code hook events. Registered in
  `~/.claude/settings.json` by `hooks/install.sh`.

`settings.local.json` is **not** shared — it holds per-repo permission
allowlists and stays in each project repo.

## Choosing Your Mechanism

Three primitives exist for extending Claude Code. Choose the lightest one that
fits the need.

| | Command | Agent | Skill |
|---|---------|-------|-------|
| **Triggered by** | User types `/name` | Claude auto-invokes from description | Claude auto-invokes from description |
| **Context** | Runs inline (shared session) | Separate subprocess (isolated) | Runs inline (shared session) |
| **Memory** | No | Yes (user/project/local) | No |
| **Best for** | Multi-step workflows the user explicitly starts | Autonomous verification or analysis that benefits from isolation | Reusable domain knowledge Claude should surface automatically |

**Decision tree:**

1. Is this a multi-step workflow the user explicitly kicks off? → **Command**
   (e.g., `/pr`, `/release-alph`, `/config-scout`)
2. Does it need context isolation, autonomous multi-step analysis, or persistent
   memory? → **Agent** (e.g., tdd-guardian, pr-reviewer)
3. Is it reusable domain knowledge that Claude should auto-surface when
   relevant? → **Skill** (e.g., testing-anti-patterns, systematic-debugging)

**Resolution order** when multiple could work: prefer Skill (lightest) over
Agent (heavier) over Command (requires explicit user invocation).

**Mapping:**
- **Commands** orchestrate workflows (git operations, release pipelines, external comparisons)
- **Agents** enforce disciplines (TDD compliance, type safety, code quality, documentation)
- **Skills** provide domain knowledge (testing patterns, debugging methodology, architecture guidance)

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

### Agent Memory

Some agents have persistent project-scoped memory (`memory: project` in
frontmatter). Memory lives in `.claude/agent-memory/<agent-name>/` within each
consuming repo. The first 200 lines of `MEMORY.md` are auto-injected into the
agent's system prompt at startup.

**Agents with memory:** learn, pr-reviewer, refactor-scan, tdd-guardian

**Memory conventions:**
- Memory stores project-specific knowledge, not general principles (those belong
  in the agent definition itself)
- Each agent's definition documents what to remember and what not to remember
- Prune memory periodically — remove entries for code that no longer exists,
  conventions that changed, or exceptions that were resolved
- When `MEMORY.md` exceeds ~150 lines, organize into topic-specific files and
  keep `MEMORY.md` as an index

**Memory does NOT replace:**
- CLAUDE.md (canonical project-wide knowledge)
- LEARNINGS.md (per-feature learnings managed by progress-guardian)
- ADRs (architectural decisions managed by adr agent)

### Turn Limits

All agents have `maxTurns` set in frontmatter to prevent runaway execution.
Analysis-only agents (tdd-guardian, py-enforcer, refactor-scan, learn,
use-case-data-patterns) have 15 turns. Agents that do more complex work
(pr-reviewer, progress-guardian, adr, docs-guardian) have 20 turns.

## File reference

| File | Role |
|------|------|
| `CLAUDE.md` | Core TDD/type-safety/style rules — loaded globally |
| `tdd-guardian.md` | Enforces RED-GREEN-REFACTOR, catches test-after violations |
| `py-enforcer.md` | Enforces type annotations, immutability, no standalone `Any` |
| `pr-reviewer.md` | Reviews PRs for correctness, test coverage, and style |
| `refactor-scan.md` | Identifies refactoring opportunities after green |
| `progress-guardian.md` | Tracks WIP state and implementation progress |
| `adr.md` | Writes Architecture Decision Records |
| `docs-guardian.md` | Keeps documentation consistent with implementation |
| `learn.md` | Captures learnings and gotchas while context is fresh |
| `use-case-data-patterns.md` | Analyses use case and data modelling patterns |
| `skills/` | On-demand skills (testing-anti-patterns, hexagonal-architecture, etc.) |
| `commands/` | Slash commands (`/pr`, `/generate-pr-review`) |
| `hooks/` | Programmatic TDD enforcement (edit guard, stop guard, pre-commit) |
