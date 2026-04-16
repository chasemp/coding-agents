---
name: claude-code-docs
description: >
  Authoritative reference for Claude Code features — hooks, skills, slash
  commands, MCP servers, settings, agents, SDK, keyboard shortcuts, IDE
  integrations. Loads a local mirror of ericbuess/claude-code-docs so
  Claude answers from current documentation instead of stale training
  data. Trigger when the user asks about Claude Code behavior, configuration,
  or capabilities ("how do hooks work", "what's the caching TTL", "can
  Claude Code do X", "which settings control Y"), or when writing code
  that configures Claude Code (settings.json, hook scripts, skill
  frontmatter, MCP config). Refreshes the local copy if it's more than
  3 days old.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(cat:*), Bash(test:*), Bash(date:*), Bash(find:*), Read, Grep, Glob
---

# Claude Code Docs (Local Mirror)

Keeps a local, authoritative copy of the Claude Code documentation
mirror at [ericbuess/claude-code-docs](https://github.com/ericbuess/claude-code-docs).
Use it whenever you need to answer a question about Claude Code's own
behavior — hooks, skills, slash commands, MCP, settings, SDK, agents,
keyboard shortcuts, IDE integrations — so your answer reflects current
docs rather than training data that may be stale.

## When to trigger

- User asks about Claude Code features: "how do hooks work", "what's
  the cache TTL", "can Claude Code do X", "which setting controls Y",
  "what does the /foo command do"
- User is writing or debugging Claude Code configuration: `settings.json`,
  `settings.local.json`, hook scripts, skill frontmatter, MCP config,
  agent frontmatter
- User asks about the Claude Agent SDK or Claude API behaviors that
  interact with Claude Code
- You are about to answer a Claude Code question from memory — pause
  and load the relevant doc first

## When NOT to trigger

- General programming questions unrelated to Claude Code
- Questions about Anthropic's API directly (the `claude-api` skill
  covers those)
- Questions about other CLI tools or other LLMs

## Step 1: Ensure the local copy exists and is fresh

Run these commands in sequence. Each step's output determines the next.

### 1a. Check if the mirror exists

!`test -d ~/.claude/claude-code-docs/.git && echo "exists" || echo "missing"`

**If "missing":** clone it.

!`git clone --depth 1 https://github.com/ericbuess/claude-code-docs.git ~/.claude/claude-code-docs`

Then record the sync date:

!`date -u +"%Y-%m-%d" > ~/.claude/claude-code-docs/.last-sync`

**If "exists":** continue to freshness check.

### 1b. Check freshness

!`cat ~/.claude/claude-code-docs/.last-sync 2>/dev/null || echo "never"`

Compute days since last sync (using date math):

!`if [ -f ~/.claude/claude-code-docs/.last-sync ]; then last=$(cat ~/.claude/claude-code-docs/.last-sync); now=$(date -u +"%Y-%m-%d"); days=$(( ( $(date -jf "%Y-%m-%d" "$now" +%s 2>/dev/null || date -d "$now" +%s) - $(date -jf "%Y-%m-%d" "$last" +%s 2>/dev/null || date -d "$last" +%s) ) / 86400 )); echo "$days days since last sync"; else echo "no sync marker"; fi`

**If days > 3 or "never" or "no sync marker":** refresh.

!`cd ~/.claude/claude-code-docs && git pull --ff-only 2>&1 | tail -5`

Update the marker:

!`date -u +"%Y-%m-%d" > ~/.claude/claude-code-docs/.last-sync`

**If days ≤ 3:** skip the pull. The local copy is current enough.

## Step 2: Use the local docs

The docs live at `~/.claude/claude-code-docs/docs/`. Structure (may drift
as the mirror evolves — verify with `ls` if your memory is uncertain):

!`ls ~/.claude/claude-code-docs/docs/ 2>/dev/null | head -30`

### Reading for an answer

1. **Identify the right file(s).** Use `ls` on the docs directory or
   `Grep` for relevant keywords in the docs tree.
2. **Read the file** with the `Read` tool — no summarization shortcuts.
   Read the section that directly addresses the question.
3. **Quote or cite** when the user's question is specific. "Per the
   local mirror of claude-code-docs at `docs/hooks.md:L42`, the TTL
   defaults to..."
4. **Flag drift.** If the local doc says something that contradicts
   your prior answer or the user's assumption, say so plainly — this
   is exactly why the skill exists.

### When the docs don't cover something

The ericbuess mirror tracks the official Anthropic docs but is not
guaranteed to be complete or current. If the answer isn't in the local
copy:

- Check when the last sync happened (`cat ~/.claude/claude-code-docs/.last-sync`)
- Suggest `/sync-claude-docs` to force a fresh pull
- Fall back to WebFetch on `https://docs.anthropic.com/en/docs/claude-code/`
  only after confirming the local copy is current

## Recovery: if a pull fails

Common failure modes and responses:

- **Detached HEAD / divergent branch** — the mirror was rebased or
  force-pushed. Recover with a clean reset:
  ```
  cd ~/.claude/claude-code-docs && git fetch --depth 1 origin && git reset --hard origin/HEAD
  ```
  Record the sync date after recovery.
- **No network / clone fails** — report to the user that the docs
  couldn't refresh. Use the existing local copy with an explicit
  disclaimer ("local copy is N days old, offline"), or fall back to
  answering from training data with a clearer caveat.
- **Disk space / permissions** — report the specific error and stop.
  Do not silently fall back.

## Manual refresh

The user can force a fresh pull at any time with the `/sync-claude-docs`
command. That command always pulls regardless of the 3-day staleness
check — useful when the user knows the upstream just updated or when
they want to verify the local copy is current.

## Quality gates

Before answering a Claude Code question:

- The skill has been triggered and Step 1 has run (local copy exists,
  freshness verified).
- You have actually read the relevant doc file, not just the directory
  listing. A listing proves the file exists; it doesn't prove what it
  says.
- If you cite specific behavior, you've seen it in the doc — no
  paraphrasing from memory when the source is right here.
- If the doc contradicts your prior answer, you've updated the answer
  (not quietly continued with the wrong one).
