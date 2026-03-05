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
mkdir -p .claude/agents

# 2. Point CLAUDE.md at the shared instructions
echo "@/Users/cpettet/git/chasemp/AlpheusCEF/agents/CLAUDE.md" > .claude/CLAUDE.md

# 3. Symlink each agent
AGENTS=/Users/cpettet/git/chasemp/AlpheusCEF/agents
for agent in tdd-guardian py-enforcer pr-reviewer refactor-scan progress-guardian adr docs-guardian learn use-case-data-patterns; do
  ln -s "$AGENTS/${agent}.md" ".claude/agents/${agent}.md"
done

# 4. Write a per-repo settings.local.json (see an existing repo for a template)

# 5. Add agents.md at the repo root (copy and update this file)
```

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
