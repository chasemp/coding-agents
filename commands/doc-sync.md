---
description: Check and update AlpheusCEF docs (STATE.md, HUMAN_TEST.md, PLAN.md, FUTURE.md) against recent alph-cli changes
allowed-tools: [Bash, Read, Edit, Glob]
---

Sync AlpheusCEF documentation against recent alph-cli code changes.

## Context

Repos involved:
- `alph-cli` code: `/Users/cpettet/git/chasemp/AlpheusCEF/alph-cli`
- Docs: `/Users/cpettet/git/chasemp/AlpheusCEF/overview`
  - `STATE.md` — architecture decisions, config keys, CLI commands, what's built
  - `HUMAN_TEST.md` — test script and checklist
  - `PLAN.md` — completed implementation items
  - `FUTURE.md` — config examples and deferred work

## Step 1 — Identify the scope of changes

Find what changed in alph-cli since the last version tag:

```bash
cd /Users/cpettet/git/chasemp/AlpheusCEF/alph-cli
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~20")
git log ${LAST_TAG}..HEAD --oneline
git diff ${LAST_TAG}..HEAD -- src/alph/core.py src/alph/cli.py src/alph/remote.py src/alph/mcp_server.py pyproject.toml
```

Focus on behavior-relevant changes. Ignore test-only or formatting changes.

**Signals that docs need updating:**
- New config key added to `AlphConfig` or `RegistryEntry`
- New or changed CLI command, flag, or option
- Changed default values (auto_pull, auto_push, etc.)
- New function exported from `core.py`
- Changed git strategy (pull flags, clone flags)
- New `_VALID_ROOT_KEYS` or `_VALID_REGISTRY_ENTRY_KEYS` entries
- Version bump in `pyproject.toml`

## Step 2 — Read the current docs

Read all four doc files in full so you understand existing coverage before making changes.

## Step 3 — Gap analysis

For each behavior-relevant change found in Step 1, check whether it is already covered in the docs. Be specific:

- **STATE.md**: Does the schema table, decisions list, config hierarchy table, or component descriptions reflect the change?
- **HUMAN_TEST.md**: Is there a test step exercising the new behavior? Is there a checklist item for it?
- **PLAN.md**: Is the completed implementation item marked `[x]` and accurately described?
- **FUTURE.md**: Are any config examples or comments stale?

Report the gaps clearly before making any edits:
```
GAP: <change description>
  STATE.md: <missing / stale / ok>
  HUMAN_TEST.md: <missing / stale / ok>
  PLAN.md: <missing / stale / ok>
  FUTURE.md: <missing / stale / ok>
```

## Step 4 — Apply updates

For each gap, apply the minimal accurate update. Follow these rules:

- **STATE.md**: Add to the relevant section (schema table, decisions list, config table, component description). Do not restructure sections that are not affected.
- **HUMAN_TEST.md**: Add test steps in the correct section (e.g., new config keys belong in section 5 or 6; new remote behavior in sections 9 or 10). Add checklist items in the correct category. Keep section and checklist numbering consistent — new items go at the end of their category, not mid-list.
- **PLAN.md**: Update the implementation item to reflect the actual approach used (e.g., `--rebase` not `--ff-only`). Mark items `[x]` if completed.
- **FUTURE.md**: Update stale config comments or examples.

Do not rewrite sections that are not affected by the change. Do not add commentary about what you changed.

## Step 5 — Consistency check

After edits, verify:
- Version references are consistent across all files (STATE.md "v0.1.x", Homebrew formula version, test count)
- Config key names match exactly between STATE.md and HUMAN_TEST.md
- CLI command names and flags are identical across all mentions
- No stale `--ff-only`, old version numbers, or removed feature references remain

## Step 6 — Report

Summarize what was updated:
```
Updated STATE.md: <bullet list of changes>
Updated HUMAN_TEST.md: <bullet list of changes>
Updated PLAN.md: <bullet list of changes>
Updated FUTURE.md: <bullet list of changes>
No changes needed: <files that were already current>
```

If nothing was stale, say so explicitly. Do not make cosmetic edits to justify a report.
