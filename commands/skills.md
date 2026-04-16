---
description: List available skills, commands, and agents with descriptions and trigger conditions, grouped by type
allowed-tools: Bash(ls:*), Bash(head:*), Bash(test:*)
---

List everything available locally, grouped into three sections: **Skills**,
**Commands**, **Agents**. For each entry, surface the description from
frontmatter and (where applicable) a short "trigger" summary so the user
can see at a glance when each one fires.

## Step 1: Enumerate sources

Skills (auto-triggered, frontmatter-driven):
!`ls ~/.claude/coding-agents/skills/*.md 2>/dev/null`

Global commands:
!`ls ~/.claude/commands/*.md 2>/dev/null`

Project commands (if the current project has any):
!`ls .claude/commands/*.md 2>/dev/null`

Agent definitions (root `.md` files in coding-agents — filter to those
with agent frontmatter, excluding documentation):
!`ls ~/.claude/coding-agents/*.md 2>/dev/null`

## Step 2: Read frontmatter from each file

For every file above, extract the frontmatter by reading the first 15
lines:

!`for f in ~/.claude/coding-agents/skills/*.md ~/.claude/commands/*.md ~/.claude/coding-agents/*.md; do echo "=== $f ==="; head -15 "$f" 2>/dev/null; done`

## Step 3: Classify and present

Use the frontmatter to place each file into one of three buckets:

- **Skills** — files in `skills/` with a `name:` field in frontmatter.
  **Exclude** `skills/phase-plan/*.md` — those are content files loaded
  by the `phase-plan` skill, not standalone skills.
- **Commands** — files in `commands/` (global or project). They have
  `description:` and `allowed-tools:` but no `tools:` or `model:`.
- **Agents** — root-level `.md` files with `tools:`, `model:`, and
  `maxTurns:` in frontmatter. **Exclude** documentation files
  (`CLAUDE.md`, `README.md`, `agents.md`, `LICENSE`, `RTK.md`,
  `REFINEMENTS.md`).

## Step 4: Render three sections

Present as three separately-labeled sections. Do not merge them into
one table — the types serve different purposes and the user benefits
from seeing the groupings distinctly.

### Skills (auto-triggered by Claude)

One row per skill:

| Name | What it does | Triggers when |
|------|--------------|---------------|
| `<name>` | <first sentence of description> | <trigger phrase from description — the "Trigger when..." / "Use when..." / "Invoke when..." portion> |

If no explicit trigger phrase is present in the description, use the
first sentence that describes the invocation condition.

### Commands (user-invoked via `/name`)

One row per command:

| Invocation | What it does | Scope |
|------------|--------------|-------|
| `/<filename without .md>` | <description> | global / project |

Mark symlinks explicitly — if a command file is a symlink, note "→ symlinks to `<target>`" in the What column.

### Agents (auto-invoked by Claude for verification/analysis)

One row per agent:

| Name | What it does | When invoked | Memory |
|------|--------------|--------------|--------|
| `<name>` | <first sentence of description> | proactive / reactive / both | yes / no |

Parse "When invoked" from description keywords:
- "proactively" + "reactively" → both
- only "proactively" → proactive
- only "reactively" → reactive
- neither → both (default)

"Memory" reflects whether the agent has `memory: project` in frontmatter.

## Step 5: Summary line

After the three sections, print a one-line count: "`N` skills, `M`
commands (`X` global, `Y` project), `K` agents."
