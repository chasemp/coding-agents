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
| `hooks/` | Programmatic TDD enforcement for Claude Code and git |

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

## TDD enforcement hooks

Prompt-level TDD instructions work most of the time, but Claude can lose them
from context during long sessions. These hooks enforce TDD programmatically —
they fire on tool use events, not natural language, so they cannot be forgotten.

Three tiers of enforcement, from lightest to strictest:

```
┌─────────────────────────────────────────────────────────────────┐
│  Edit guard (real-time nudge)                       [global]    │
│  Fires on: Edit, Write tool calls                               │
│  Prompts for confirmation when editing production code without  │
│  any test file changes in the working tree. Debounced to once   │
│  per 2 minutes so it nudges without nagging.                    │
├─────────────────────────────────────────────────────────────────┤
│  Stop guard (session gate)                          [global]    │
│  Fires on: session completion                                   │
│  Blocks Claude from ending a session when production files      │
│  have uncommitted changes but no test files do.                 │
├─────────────────────────────────────────────────────────────────┤
│  Pre-commit guard (commit gate)                     [per-repo]  │
│  Fires on: git commit                                           │
│  Rejects commits where production files are staged without      │
│  test files. Optionally runs the test suite.                    │
└─────────────────────────────────────────────────────────────────┘
```

**Quick start (edit guard + stop guard):**

```bash
./hooks/install.sh
```

This symlinks the hook scripts into `~/.claude/hooks/` and registers them in
`~/.claude/settings.json`. After install, every Claude Code session in every
repo gets TDD enforcement automatically. No per-repo configuration needed.
Restart Claude Code to activate.

To uninstall: `./hooks/install.sh --uninstall`

**Pre-commit guard (per-repo, opt-in):** For the strictest enforcement,
consuming repos install the git pre-commit hook. See
[hooks/README.md](hooks/README.md) for setup and configuration.

**Opt-out:** Drop a `.notdd` file in any repo root to disable all tiers for
that repo. Useful for repos where TDD enforcement does not apply (scripts,
configs, spikes).

## Recommended external skills

Skills from the [Anthropic Skills Marketplace](https://github.com/anthropics/skills)
that complement this repo's guidance. These are installed globally and
auto-trigger in consuming projects — they don't modify this repo.

| Skill | Trigger | Why |
|-------|---------|-----|
| [claude-api](https://github.com/anthropics/skills/tree/main/skills/claude-api) | Detects `anthropic` / `@anthropic-ai/sdk` / `claude_agent_sdk` imports | Loads current SDK context so Claude works from verified API behavior instead of stale training data. Directly supports the "no assumed behavior" principle in phase-plan. |

**Install:**

```bash
/plugin marketplace add https://github.com/anthropics/skills
```

## Org repos

Org-specific coding-agents repos extend this with org-only content:

- [AlpheusCEF/coding-agents](https://github.com/AlpheusCEF/coding-agents) — release-alph, doc-sync, config-scout
- [mycelium-agent-framework/coding-agents](https://github.com/mycelium-agent-framework/coding-agents) — spore-validator, ring-inspector
