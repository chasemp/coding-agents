---
description: Hygiene audit of this repo's skills, agents, and commands against skill-hygiene.md rules; read-only report, no fixes applied
allowed-tools: Bash(wc:*), Bash(find:*), Bash(ls:*), Bash(head:*), Bash(test:*), Bash(awk:*), Bash(sort:*), Bash(uniq:*), Read, Grep, Glob
---

Run a hygiene audit on this coding-agents repo. This command is
read-only — it flags issues but does not fix them. Intended for use:

- Periodically, to catch drift that `skill-hygiene.md` declares but
  doesn't enforce
- After `learn` or `external-learn` writes to the repo, to verify the
  new content integrates cleanly
- Before a commit that touches multiple skills/agents, to catch stale
  cross-references early

The canonical rule source is `skills/skill-hygiene.md`. Check numbers
below map to enforcement of specific sections there.

## Check 1: Size budgets

Budgets from `skill-hygiene.md` § Token Budgeting:
- `CLAUDE.md`: under 200 lines
- Skills (top-level `skills/*.md`): under 500 lines
- Agents (root `.md` with agent frontmatter): under 400 lines
- Commands: no hard limit (but front-load critical instructions)

**Exempt:** `skills/phase-plan/*.md` are per-pass content files loaded
on demand by the main `phase-plan.md` skill. Their budget is the
skill itself (they don't count individually against the 500-line rule).

### CLAUDE.md

!`wc -l CLAUDE.md | awk '{print $1 " lines (budget: 200)"}'`

### Top-level skills

!`for f in skills/*.md; do lines=$(wc -l < "$f"); echo "$lines $f"; done | sort -rn`

### Root agents (excluding documentation)

!`for f in *.md; do case "$f" in CLAUDE.md|README.md|agents.md|LICENSE|RTK.md|REFINEMENTS.md|EXTERNAL-LEARNINGS.md) continue;; esac; lines=$(wc -l < "$f"); echo "$lines $f"; done | sort -rn`

### Per-pass content files (informational only)

!`for f in skills/phase-plan/*.md; do lines=$(wc -l < "$f"); echo "$lines $f"; done 2>/dev/null | sort -rn`

**Interpret:** flag any skill over 500, any agent over 400, any
CLAUDE.md over 200. Per-pass files are informational only.

## Check 2: Stale cross-references

Grep for file-path references in skills, agents, commands, CLAUDE.md,
and agents.md. Verify each referenced path exists.

### Skill path references (e.g., `skills/X.md`, `skills/X/Y.md`)

Filters out obvious template placeholders (`X.md`, `some-*`, `<name>`)
and `.claude/` paths (those refer to consumer projects, not this repo).
The pattern optionally captures `.claude/` prefix so the filter can
see and reject it. See the grep below for the full filter list.

!`grep -rhoE '(\.claude/)?skills/[a-zA-Z0-9_-]+(/[a-zA-Z0-9_-]+)?\.md' skills/ commands/ *.md 2>/dev/null | grep -vE '^\.claude/|(^|/)X\.md$|/X/|/some-[a-zA-Z0-9_-]+\.md$|<' | sort -u`

### Command path references (e.g., `commands/X.md`)

!`grep -rhoE '(\.claude/)?commands/[a-zA-Z0-9_-]+\.md' skills/ commands/ *.md 2>/dev/null | grep -vE '^\.claude/|(^|/)X\.md$|/some-[a-zA-Z0-9_-]+\.md$|<' | sort -u`

### Agent name references in backticks

Grep for inline-code agent names and verify the corresponding root
`.md` exists:

!`grep -rhoE '\`(tdd-guardian|py-enforcer|pr-reviewer|refactor-scan|progress-guardian|adr|docs-guardian|learn|external-learn|use-case-data-patterns)\`' skills/ commands/ *.md 2>/dev/null | sort -u | tr -d '\`'`

**Interpret:** For each referenced path, verify it exists via
`test -f`. Flag any that don't. Known-good referenced names should
match the files in the root of this repo.

## Check 3: Frontmatter completeness

Skills need `name:` and `description:`. Agents need `name:`,
`description:`, `tools:`, `model:`, `maxTurns:`. Commands need
`description:` and `allowed-tools:`.

### Skills missing `name:` or `description:`

!`for f in skills/*.md; do head -10 "$f" | grep -q '^name:' || echo "MISSING name: $f"; head -10 "$f" | grep -q '^description:' || echo "MISSING description: $f"; done`

### Agents missing required fields

!`for f in *.md; do case "$f" in CLAUDE.md|README.md|agents.md|LICENSE|RTK.md|REFINEMENTS.md|EXTERNAL-LEARNINGS.md) continue;; esac; head -60 "$f" | grep -q '^tools:' || continue; for field in name description tools model maxTurns; do head -60 "$f" | grep -q "^$field:" || echo "MISSING $field: $f"; done; done`

### Commands missing required fields

!`for f in commands/*.md; do head -10 "$f" | grep -q '^description:' || echo "MISSING description: $f"; done`

**Interpret:** Any "MISSING" line is a frontmatter defect.
`allowed-tools:` is not required — commands that don't invoke tools
(like `/s`, which only emits text) don't need it. Claude Code enforces
the tool allowlist at runtime, so an absent field just means "no
tools used."

## Check 4: Color uniqueness on agents

Agent `color:` fields should be unique for visual distinctiveness.

!`grep -l '^color:' *.md 2>/dev/null | while read f; do color=$(grep '^color:' "$f" | head -1 | awk '{print $2}'); echo "$color $f"; done | sort`

**Interpret:** Group by color. Any color used by 2+ agents is a
collision. Not a blocker — cosmetic only — but worth fixing when
convenient. **Palette constraint:** the Claude Code frontend supports
an 8-color palette (red, orange, yellow, green, cyan, blue, purple,
pink). With 10 agents, at least 2 collisions are unavoidable. Pair
collisions between agents with orthogonal workflows so they rarely
fire together (current intentional pairings:
`orange` = py-enforcer + use-case-data-patterns;
`purple` = adr + docs-guardian).

## Check 5: Orphan root files

Root `.md` files that are neither on the docs whitelist nor have
agent frontmatter (i.e., no `tools:` field) are orphans. They may be
stale or misplaced.

!`for f in *.md; do case "$f" in CLAUDE.md|README.md|agents.md|LICENSE|RTK.md|REFINEMENTS.md|EXTERNAL-LEARNINGS.md) continue;; esac; head -60 "$f" | grep -q '^tools:' || echo "ORPHAN: $f (no tools: field in first 60 lines, not on docs whitelist)"; done`

**Interpret:** Any "ORPHAN" line warrants attention. Either the file
belongs on the docs whitelist (add to the `case` patterns in these
checks and to `agents.md` § File reference) or it should be deleted
or moved. The 60-line head covers agents with sprawling frontmatter
descriptions (`use-case-data-patterns.md`, for instance, has a
description that spans ~40 lines of inline examples).

## Check 6: TRACKING markers for load-bearing redundancy

Per `skill-hygiene.md` § Named exceptions to the deduplication rule,
load-bearing redundancy must be marked with a TRACKING comment.
The main case is `phase-plan` — its split files repeat execution
guardrails on purpose.

!`grep -l 'TRACKING:' skills/phase-plan.md skills/phase-plan/*.md 2>/dev/null`

**Interpret:** Verify the main `phase-plan.md` retains at least one
TRACKING comment referencing the split (2026-04-16). Per-pass and
execute files do not need TRACKING markers themselves — the main
file's TRACKING is the canonical marker.

## Output

Present findings grouped by check number. Use this summary structure:

```
Audit summary (2026-MM-DD)

Check 1 — Size budgets: [pass / N flags]
  <details of any file over budget>

Check 2 — Stale cross-references: [pass / N flags]
  <each flagged reference>

Check 3 — Frontmatter completeness: [pass / N flags]
  <each MISSING line>

Check 4 — Color uniqueness: [pass / N collisions]
  <each colliding pair>

Check 5 — Orphan root files: [pass / N flags]
  <each ORPHAN line>

Check 6 — TRACKING markers: [pass / issue]
  <if issue, what>

Overall: <N> flags across <M> checks.
```

If all checks pass, say so and stop. Do not propose fixes unless the
user asks — this command is for diagnosis only.

## Scope (current)

This command audits **this repo's own content** (Scope A):
- `CLAUDE.md`, `agents.md`, `README.md`
- `skills/*.md` and `skills/phase-plan/*.md`
- Root agent `.md` files
- `commands/*.md`

Scope B — auditing a consumer project's local `.claude/` directory —
is not implemented yet. See `REFINEMENTS.md` for the parked proposal.
