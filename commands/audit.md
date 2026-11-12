---
description: Hygiene audit of this repo's skills, agents, and commands against skill-hygiene.md rules; read-only report, no fixes applied
allowed-tools: Bash(wc:*), Bash(find:*), Bash(ls:*), Bash(head:*), Bash(test:*), Bash(awk:*), Bash(sort:*), Bash(uniq:*), Bash(grep:*), Bash(echo:*), Bash(bash scripts/audit-checks.sh:*), Bash(bash scripts/check-phase-plan.sh:*), Bash(bash scripts/test-check-phase-plan.sh:*), Bash(bash scripts/test-audit-checks.sh:*), Read, Grep, Glob
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

**Exempt:** files under `skills/phase-plan/` (the pass files,
`execute.md`, `walk-through.md`, `CHANGELOG.md`) are loaded on demand by
the main `phase-plan.md` skill, or not at all. Their budget is the skill
itself (they don't count individually against the 500-line rule).

### CLAUDE.md

!`bash scripts/audit-checks.sh claude-size`

### Top-level skills

!`bash scripts/audit-checks.sh skill-sizes`

### Root agents (excluding documentation)

!`bash scripts/audit-checks.sh agent-sizes`

### Files under `skills/phase-plan/` (informational only)

!`bash scripts/audit-checks.sh phase-plan-sizes`

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

!`bash scripts/audit-checks.sh skill-refs`

### Command path references (e.g., `commands/X.md`)

!`bash scripts/audit-checks.sh command-refs`

### Agent name references in backticks

Grep for inline-code agent names and verify the corresponding root
`.md` exists:

!`bash scripts/audit-checks.sh agent-names`

**Interpret:** For each referenced path, verify it exists via
`test -f`. Flag any that don't. Known-good referenced names should
match the files in the root of this repo.

## Check 3: Frontmatter completeness

Skills need `name:` and `description:`. Agents need `name:`,
`description:`, `tools:`, `model:`, `maxTurns:`. Commands need
`description:` and `allowed-tools:`.

### Skills missing `name:` or `description:`

!`bash scripts/audit-checks.sh skill-frontmatter`

### Agents missing required fields

!`bash scripts/audit-checks.sh agent-frontmatter`

### Commands missing required fields

!`bash scripts/audit-checks.sh command-frontmatter`

**Interpret:** Any "MISSING" line is a frontmatter defect.
`allowed-tools:` is not required — commands that don't invoke tools
(like `/s`, which only emits text) don't need it. Claude Code enforces
the tool allowlist at runtime, so an absent field just means "no
tools used."

## Check 4: Color uniqueness on agents

Agent `color:` fields should be unique for visual distinctiveness.

!`bash scripts/audit-checks.sh colors`

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

!`bash scripts/audit-checks.sh orphans`

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

!`grep -qF 'TRACKING: File split (2026-04-16)' skills/phase-plan.md && echo 'OK: split marker in skills/phase-plan.md' || echo 'MISSING: split marker in skills/phase-plan.md'`

**Interpret:** the second line must read OK. The first list alone can
stay green when the main file loses its marker, because
`skills/phase-plan/CHANGELOG.md` and `execute.md` hold TRACKING text too. Per-pass and
execute files do not need TRACKING markers themselves — the main
file's TRACKING is the canonical marker.

## Check 7: Plan docs carry reasoning

Every plan in `plans/*.md` must carry Problem Statement, Approach,
and Reasoning — the WHY, not just the WHAT. Enforced by the
`plan-doc-reasoning` skill. This check is the periodic verification.

Headings from known formats that satisfy the floor:

- `phase-plan` template: `## Problem Statement`, `## Reasoning`
- `external-learn` review: `## Source Summary`, per-candidate `**Rationale:**`
- `ADR` record: `## Context`, `## Decision`, `## Rationale`

The check grep below looks for any reasoning-related heading. Files
with no such heading are flagged for review — they may be pure
change lists with no reasoning trail.

!`bash scripts/audit-checks.sh plan-reasoning`

**Interpret:** Any "MISSING" line means the plan has no heading that
looks like a reasoning or problem record. The plan may still capture
reasoning in prose form, but the absence of a recognizable heading
is a signal — read the file and confirm the three elements are
present. If they are, consider adding an explicit heading to make
the reasoning scannable. If they are not, the plan needs work before
it is useful to a future reader.

**False positives expected:** plans that use non-standard heading
names but still carry reasoning. Treat the check as advisory — the
fix is usually "rename a heading" not "rewrite the plan."

## Check 8: phase-plan structure

`scripts/check-phase-plan.sh` checks the phase-plan skill's wiring: the
loading table and its routes, every `skills/phase-plan/` path and
section reference (a backticked file name, a section sign, a heading), the split marker, anchors for changes
already applied, retired phrases, and line limits.
`scripts/test-check-phase-plan.sh` proves each assertion can fail.

!`bash scripts/check-phase-plan.sh 2>&1 | grep -v '^INFO'`

Then run the fixture test with the Bash tool and an explicit
`timeout: 600000` (it takes about three minutes, over the default limit):

```
bash scripts/test-check-phase-plan.sh && bash scripts/check-phase-plan.sh && bash scripts/test-audit-checks.sh
```

**Interpret:** every `FAIL` line is a flag; the check's last line must
read `0 failed` and the test's must read `0 failed`. A red check means a
reference, route or applied change was lost: fix the edit that caused it,
or update the check's table with the reason.

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

Check 7 — Plan doc reasoning: [pass / N flags]
  <each MISSING line, with a note that these are advisory>

Check 8 — phase-plan structure: [pass / N flags]
  <each FAIL line from the check or the fixture test>

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
