---
description: >
  Compare an external Claude/agent configuration against the local AlpheusCEF
  setup. Identifies overlaps, gaps, and actionable refinements. Stores a
  timestamped report in config-scout/ for tracking what was analyzed and when.
  Usage: /config-scout <url-or-filepath> [--recheck] [--batch]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, WebFetch, Agent]
---

# Config Scout — External Configuration Comparator

You are analyzing an external Claude Code / AI agent configuration and comparing
it against the local AlpheusCEF setup. Your goal is to produce a structured
comparison that identifies overlaps, novel ideas, and actionable refinements.

## Input

The user provides one of:
- **A URL** to a GitHub repo, raw file, blog post, or gist containing Claude
  configuration (CLAUDE.md, .cursorrules, agent configs, etc.)
- **A local file path** to an external config already downloaded
- **`--recheck`** flag with a source slug (e.g., `/config-scout --recheck some-repo`)
  to re-analyze a previously compared source and show what changed

If no argument is provided, ask the user for the source to compare.

## Detecting Large Sources (Batch Mode)

Before diving in, assess the source's size. If it contains **more than ~5
distinct skills, agents, or config files**, switch to batch mode automatically.
Signs of a large source:
- A repo with a `skills/` directory containing many subdirectories
- Multiple agent definitions
- A plugin/marketplace structure
- Any source where a single flat report would exceed ~300 lines

### Batch Mode Workflow

Large sources are handled in three passes:

**Pass 1 — Catalog and Classify (the "map")**

Fetch the repo structure (use the GitHub tree API or directory listing) and
build a catalog of every skill, agent, command, and config file. For each item,
record:
- Name and path
- One-line description (from frontmatter, first paragraph, or filename)
- **Category tag** from the standard dimensions (testing, workflow, debugging,
  collaboration, documentation, architecture, code quality, meta/tooling)
- **Relevance estimate**: high / medium / low / unknown — based on whether
  AlpheusCEF already covers the topic

Save this catalog as: `config-scout/YYYY-MM-DD_<source-slug>_catalog.md`

Present the catalog to the user with relevance estimates and ask:
> "This source has N items. I've flagged M as high-relevance. Want me to
> deep-dive all high-relevance items, a specific subset, or everything?"

**Pass 2 — Deep Dive (the "analyze")**

For each item the user selects (or all high-relevance items by default):
- Fetch the full content
- Compare against the specific local file/skill/agent that covers the same
  territory
- Use the Agent tool with subagent_type=Explore to parallelize fetches when
  possible
- Produce a per-item comparison block (same structure as Step 3 below but
  scoped to one skill/agent)

**Pass 3 — Rollup (the "synthesize")**

After all deep dives complete:
- Aggregate findings into the standard report format (Step 6)
- Add a **Coverage Heatmap** section showing which of our categories the
  external source covers vs. doesn't
- Add a **Catalog Reference** section linking to the full catalog file
- Deduplicate recommendations that appear across multiple items
- Flag items where the external source has depth we lack entirely (new
  category, not just a new item within an existing category)

The rollup report is saved as the main report:
`config-scout/YYYY-MM-DD_<source-slug>.md`

### Context Management for Batch Mode

Large sources can exhaust context. To manage this:
- Use Agent subagents to fetch and analyze individual items in isolation — each
  subagent handles 1-3 related skills and returns a structured comparison block
- The main conversation only holds the catalog and rolled-up findings
- If a source has 15+ items, process in waves of 3-5 subagents at a time
- Each subagent should return findings in a consistent format so they can be
  mechanically merged into the rollup

## Step 1 — Fetch the External Configuration

### For URLs
Use WebFetch to retrieve the content. Extract the full text of any Claude/agent
configuration files. If it is a GitHub repository URL, look for:
- `CLAUDE.md` or `.claude/CLAUDE.md`
- `.claude/settings.json`
- `.claude/commands/*.md`
- `.cursorrules`
- `.github/copilot-instructions.md`
- Any agent definition files (`.md` files with YAML frontmatter)
- Skills directories

Use the Agent tool with subagent_type=Explore if you need to navigate a complex
repo structure to find all relevant config files.

### For local files
Read the file directly.

### For --recheck
Find the most recent report for that source slug in `config-scout/` and note
its date and content for delta comparison later.

## Step 2 — Inventory the Local Setup

Read and catalog the local AlpheusCEF configuration:

1. **Core instructions**: `CLAUDE.md` (root) and `.claude/CLAUDE.md`
2. **Skills**: All files in `skills/*.md` — extract name, description, and key
   principles from each
3. **Agents**: All `*.md` files in the repo root that define agent behavior
   (tdd-guardian, pr-reviewer, py-enforcer, etc.)
4. **Commands**: All files in `commands/*.md` — extract description and purpose
5. **Global user config**: Note that user has global instructions at
   `~/.claude/CLAUDE.md` (do NOT read contents for privacy — just note it exists)

Build a structured inventory with categories:
- Testing philosophy & practices
- Type safety & code quality
- Architecture & design patterns
- Development workflow (TDD, CI/CD, git)
- Code style & conventions
- Language-specific guidance
- Tool integrations & automation
- Documentation practices
- Agent/skill ecosystem

## Step 3 — Compare Across Dimensions

For each dimension, analyze:

### 3a. Overlaps
Things both configurations address. Note if the external config phrases
something more clearly or concisely — that is itself a finding.

### 3b. Unique to External
Capabilities, rules, patterns, or tooling the external config has that
AlpheusCEF does not. For each item, assess:
- **Relevance**: Would this be valuable in the AlpheusCEF context? (high/medium/low)
- **Effort**: How hard to incorporate? (trivial/moderate/significant)
- **Category**: Which local file or skill would this belong in?

### 3c. Unique to Local
Things AlpheusCEF has that the external config lacks. This validates the local
setup's strengths and identifies areas where AlpheusCEF is ahead.

### 3d. Philosophical Differences
Places where the two configs actively disagree or take different approaches to
the same problem. Note the tradeoffs of each approach.

## Step 4 — Generate Recommendations

Produce a prioritized list of actionable refinements:

1. **Quick wins** — High relevance, trivial effort. Things we should just do.
2. **Worth investigating** — High relevance, moderate effort. Need design thought.
3. **Nice to have** — Medium relevance. File for later consideration.
4. **Noted but skipped** — Low relevance or conflicts with core philosophy. Document
   why we're passing.

For each recommendation, include:
- What to change or add
- Where it would go (which file/skill/agent)
- A brief rationale
- Any caveats or adaptations needed for the AlpheusCEF context

## Step 5 — Delta Analysis (recheck mode only)

If this source was previously analyzed, compare the current external config
against the previous report:
- What is new in the external config since last check?
- What was removed or changed?
- Do any previous "skipped" items now look more relevant given changes?
- Have any of the previous recommendations already been implemented locally?

## Step 6 — Write the Report

Save the report to: `config-scout/YYYY-MM-DD_<source-slug>.md`

The source slug should be a kebab-case identifier derived from the source
(e.g., `anthropic-claude-code`, `cursor-rules-example`, `some-users-setup`).

### Report Format

```markdown
# Config Scout Report: <source name>

**Source**: <url or path>
**Date**: <YYYY-MM-DD>
**Previous analysis**: <date of last report for this source, or "none">
**Local setup version**: <git short hash of HEAD>

## Executive Summary

<2-3 sentence overview of key findings>

## Source Overview

<Brief description of what the external config contains, its scope, and
apparent philosophy>

## Comparison Matrix

| Dimension | Overlap | External Only | Local Only | Conflicts |
|-----------|---------|---------------|------------|-----------|
| Testing   | ...     | ...           | ...        | ...       |
| Types     | ...     | ...           | ...        | ...       |
| ...       | ...     | ...           | ...        | ...       |

## Detailed Findings

### Overlaps
<grouped by dimension>

### Novel in External Config
<grouped by relevance>

### Local Strengths
<what AlpheusCEF has that external lacks>

### Philosophical Differences
<where approaches diverge>

## Recommendations

### Quick Wins
1. ...

### Worth Investigating
1. ...

### Nice to Have
1. ...

### Noted but Skipped
1. ...

## Delta Since Last Check
<only if recheck mode — otherwise omit this section>

## Coverage Heatmap (batch mode only)

| Category | Local Depth | External Depth | Gap Direction |
|----------|------------|----------------|---------------|
| Testing  | deep       | moderate       | ← local leads |
| ...      | ...        | ...            | ...           |

## Catalog Reference (batch mode only)

Full item-by-item catalog: `config-scout/YYYY-MM-DD_<slug>_catalog.md`

## Raw Notes
<any additional observations, interesting patterns, or things to revisit>
```

## Step 7 — Summarize to User

After writing the report, provide the user with:
1. Path to the saved report
2. The executive summary
3. The quick wins list
4. Count of items in each recommendation tier

Do NOT dump the entire report into the conversation — the user can read the
file. Keep the summary concise and actionable.

## Step 8 — Update the Decision Journal

After the user reviews the report and decides what to adopt, skip, or defer,
update `config-scout/DECISIONS.md` — the cumulative decision journal that tracks
what we chose and why over time.

### Decision Journal Format

Each entry in `DECISIONS.md` follows this structure:

```markdown
### YYYY-MM-DD — <source-slug>

**Adopted:**
- <what was incorporated> → <where it went> | Rationale: <why>

**Deferred:**
- <what was postponed> | Reason: <why not now> | Revisit: <trigger or date>

**Rejected:**
- <what was skipped> | Reason: <why it doesn't fit>

**Patterns Noticed:**
- <any meta-observations about what keeps appearing across sources, what we
  keep rejecting, what our blind spots seem to be>
```

### How to Maintain the Journal

- Read the existing `DECISIONS.md` before writing new entries so you can
  reference prior decisions ("previously rejected X from source Y, but this
  source phrases it differently and addresses our concern")
- Look for **recurring themes** across reports — if three sources independently
  recommend something we keep skipping, flag that pattern explicitly
- Track **adoption success** — when revisiting a source (--recheck), note
  whether previously adopted recommendations worked out
- Note **emerging consensus** — if the community is converging on a practice
  we lack, that signal is stronger than any single source

### Meta-Learning Questions

After each comparison, reflect on and record answers to:

1. **Selection bias**: Are we only comparing configs from people who think like
   us? What would a radically different approach teach us?
2. **Rejection patterns**: What do we keep saying no to? Is that principled
   consistency or a blind spot?
3. **Adoption lag**: How long between "worth investigating" and actually
   implementing? What blocks adoption?
4. **Surprise value**: What was the most unexpected finding? Surprises are where
   learning lives.
5. **Scope evolution**: Is our setup growing in a coherent direction, or
   accreting features? Does each addition serve the core philosophy?

These reflections go in the **Patterns Noticed** section of each journal entry.
Over time, this creates a meta-narrative about how our context management
approach is evolving and what forces shape it.

## Guidelines

- Be opinionated. The user wants recommendations, not just a diff.
- Respect the local philosophy. AlpheusCEF is TDD-first, functional,
  type-strict. Recommendations that conflict with these must be flagged clearly.
- Capture verbatim quotes from the external config when something is
  particularly well-phrased — good wording is worth borrowing.
- Note the external config's apparent maturity and scope. A personal blog post
  config is different from a team's battle-tested setup.
- When in doubt about relevance, include it as "nice to have" rather than
  dropping it. The user can triage.
- When updating the decision journal, look backward as much as forward — the
  value compounds when you can trace the arc of decisions across months.
- **Git provenance**: When committing changes adopted from external sources,
  include a `Source: <url>` trailer in the commit message. This creates an
  implicit git-based record — `git log --grep="Source:"` shows the full adoption
  timeline, and `git blame` on any line traces back to where the idea originated.
  Combined with DECISIONS.md, this gives two views: the journal records the
  *deliberation* (what we considered, why), and git records the *implementation*
  (what landed, when, in what form).
