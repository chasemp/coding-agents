---
description: List all available local skills, commands, and agents
allowed-tools: Bash(ls:*), Bash(head:*)
---

List everything available locally. Run these commands and present the results in a single organized table:

Global commands:
!`ls ~/.claude/commands/ 2>/dev/null`

Project commands:
!`ls .claude/commands/ 2>/dev/null`

Skills (auto-trigger):
!`ls ~/.claude/coding-agents/skills/ 2>/dev/null`

Agents:
!`ls ~/.claude/coding-agents/agents/ 2>/dev/null`

For each item, read the first few lines to get the description from frontmatter. Present as a table grouped by type (commands, skills, agents) with name and one-line description. Note which commands are symlinks to skills.
