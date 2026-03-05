# AlpheusCEF Agents

Shared Claude Code agents, instructions, and commands for all AlpheusCEF repos.

This is the single source of truth. All AlpheusCEF repos reference these files directly rather than maintaining their own copies.

## Design context

Full project design, architecture decisions, and implementation plan are in the [overview repo](../overview/STATE.md).

## What's here

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Shared project instructions imported by all repo `.claude/CLAUDE.md` files |
| `tdd-guardian.md` | TDD enforcement and coaching agent |
| `py-enforcer.md` | Python type safety and immutability enforcer |
| `pr-reviewer.md` | Pull request review agent |
| `refactor-scan.md` | Refactoring opportunity scanner |
| `progress-guardian.md` | Progress tracking and WIP state agent |
| `adr.md` | Architecture Decision Record writer |
| `docs-guardian.md` | Documentation consistency guardian |
| `learn.md` | Learning capture agent |
| `use-case-data-patterns.md` | Use case and data pattern analysis |
| `commands/` | Shared slash commands |

## How repos consume these files

Each AlpheusCEF repo has:

```
.claude/
  CLAUDE.md            # single line: @/abs/path/to/agents/CLAUDE.md
  agents/
    tdd-guardian.md    # symlink → agents repo
    py-enforcer.md     # symlink → agents repo
    ...
  settings.local.json  # per-repo permissions, not shared
agents.md              # documents the setup for contributors
```

To wire up a new repo, run the setup script documented in `agents.md`.

## Updating agents

Edit files here. All repos pick up changes immediately via symlinks — no sync step needed.
