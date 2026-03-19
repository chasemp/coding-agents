# Coding Agents

Personal, authoritative Claude Code guidance — agents, skills, commands, and
instructions for coding agents across all orgs and projects.

## Layering model

This repo is the **personal layer** (Layer 1). Org-specific repos add on top.

```
┌─────────────────────────────────────────────┐
│ Layer 1: Personal (this repo)               │
│ Installed at: ~/.claude/coding-agents/      │
│ Loaded via: ~/.claude/CLAUDE.md @includes   │
├─────────────────────────────────────────────┤
│ Layer 2: Org-specific                       │
│ AlpheusCEF/coding-agents                    │
│ mycelium-agent-framework/coding-agents      │
│ Cloned into project .claude/org-agents/     │
├─────────────────────────────────────────────┤
│ Layer 3: Project                            │
│ Each repo's own CLAUDE.md                   │
└─────────────────────────────────────────────┘
```

## What's here

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Core TDD, type safety, code style, and workflow guidelines |
| `agents.md` | Agent setup guide, orchestration sequences, and decision tree |
| `*.md` (root) | Agent definitions (tdd-guardian, py-enforcer, pr-reviewer, etc.) |
| `skills/` | On-demand skill definitions (testing-anti-patterns, hexagonal-architecture, etc.) |
| `commands/` | Slash commands (pr, generate-pr-review) |

## Installation

```bash
git clone git@github-personal:chasemp/coding-agents.git ~/git/chasemp/coding-agents
ln -sf ~/git/chasemp/coding-agents ~/.claude/coding-agents
```

Add to `~/.claude/CLAUDE.md`:

```markdown
@coding-agents/CLAUDE.md
@coding-agents/agents.md
```

The symlink means edits to the working copy are immediately live — no sync step needed.

## Org repos

Org-specific coding-agents repos extend this with org-only content:

- [AlpheusCEF/coding-agents](https://github.com/AlpheusCEF/coding-agents) — release-alph, doc-sync, config-scout
- [mycelium-agent-framework/coding-agents](https://github.com/mycelium-agent-framework/coding-agents) — spore-validator, ring-inspector
