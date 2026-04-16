---
description: Force-refresh the local Claude Code docs mirror regardless of staleness; report current commit and last-sync date
allowed-tools: Bash(git:*), Bash(ls:*), Bash(cat:*), Bash(test:*), Bash(date:*), Bash(find:*), Bash(wc:*), Bash(du:*)
---

Force-pull the local mirror of [ericbuess/claude-code-docs](https://github.com/ericbuess/claude-code-docs)
regardless of staleness. The paired `claude-code-docs` skill refreshes
automatically when the local copy is >3 days old — this command is for
when you know the upstream just updated, or you want to verify the
local copy is current before asking questions.

## Step 1: Ensure the mirror directory exists

!`test -d ~/.claude/claude-code-docs/.git && echo "exists" || echo "missing"`

**If "missing":** clone it fresh.

!`git clone --depth 1 https://github.com/ericbuess/claude-code-docs.git ~/.claude/claude-code-docs`

## Step 2: Fetch and fast-forward

!`cd ~/.claude/claude-code-docs && git fetch --depth 1 origin 2>&1 | tail -3`

!`cd ~/.claude/claude-code-docs && git pull --ff-only 2>&1 | tail -5`

## Step 3: Update sync marker

!`date -u +"%Y-%m-%d" > ~/.claude/claude-code-docs/.last-sync`

## Step 4: Report current state

Current commit:

!`cd ~/.claude/claude-code-docs && git log -1 --format='%h %ci %s' 2>/dev/null`

Last sync:

!`cat ~/.claude/claude-code-docs/.last-sync`

Docs directory listing:

!`ls ~/.claude/claude-code-docs/docs/ 2>/dev/null`

File count and size:

!`cd ~/.claude/claude-code-docs && echo "Files: $(find docs -type f | wc -l | tr -d ' ')" && echo "Size: $(du -sh docs | cut -f1)"`

## Recovery: if pull failed

If Step 2 reported divergence, a force-push, or a merge conflict, run:

```
cd ~/.claude/claude-code-docs && git fetch --depth 1 origin && git reset --hard origin/HEAD
```

Then re-run this command. Do not attempt merges or rebases against the
mirror — it's a read-only cache, not a working branch.

## Report back

Summarize to the user:

- Whether this was a fresh clone, a pull, or a no-op (already current)
- The current commit and commit date
- The last-sync date
- File count and total size of `docs/`
- Any warnings (pull conflicts, missing network, disk issues)
