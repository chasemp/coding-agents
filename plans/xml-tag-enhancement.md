# XML Tag Enhancement for Prompt Files

## Problem Statement

The coding-agents repo contains 22 markdown files (agents, skills, commands)
that serve as prompts for Claude. These files mix multiple content types —
instructions, examples, rules, templates, checklists, response patterns,
anti-patterns — using only markdown headers and formatting to distinguish them.

Anthropic's prompting best practices explicitly recommend XML tags for this
situation: *"XML tags help Claude parse complex prompts unambiguously,
especially when your prompt mixes instructions, context, examples, and
variable inputs."* Specifically, examples should be wrapped in `<example>`
tags, and different content types should use consistent, descriptive tag names.

The goal is to add semantic XML tags to the prompt files that benefit most,
improving Claude's parsing and instruction compliance without degrading human
readability.

## Reasoning

**Why XML tags on top of markdown, not instead of:**
Markdown headers and formatting serve human readers (scanning, navigation).
XML tags serve Claude (semantic boundaries between content types). The two
are complementary. We keep all existing markdown structure and layer XML
tags on top for content-type disambiguation.

**Why not all files:**
Files that are primarily one content type (knowledge/reference skills,
short commands) don't benefit from XML tags — there's no content type
ambiguity to resolve. The best practices doc says tags help "especially
when your prompt mixes instructions, context, examples, and variable
inputs." Files that don't mix these types don't need tags.

**What the best practices doc specifically recommends:**
1. Wrap examples in `<example>` / `<examples>` tags so Claude distinguishes
   them from instructions
2. Use consistent, descriptive tag names across prompts
3. Nest tags when content has a natural hierarchy

**Alternatives considered:**
- *Full XML restructuring (replacing markdown with XML):* Rejected — would
  harm human readability and break existing tooling that renders markdown.
- *XML tags in all files regardless of benefit:* Rejected — adds token
  overhead to files that don't need disambiguation. The skills that are
  purely knowledge (effective-design-overview, hexagonal-architecture,
  cli-distribution) don't mix content types.
- *Only `<example>` tags:* Considered — this is the single highest-impact
  change. But since we're already touching the files, adding `<rules>`,
  `<output_format>`, and `<gate>` tags is low incremental effort with
  meaningful benefit for enforcement agents.

## Verified Assumptions

1. **Claude Code preserves XML tags in skill/agent markdown files.**
   Verified: `use-case-data-patterns.md` already uses `<example>` and
   `<commentary>` tags in its description field (lines 7-37). This is
   existing precedent in this repo.

2. **XML tags don't interfere with markdown rendering.**
   Verified: Markdown renderers pass through unknown HTML/XML tags. Code
   blocks inside XML tags render normally. GitHub's markdown renderer
   will show the tags as-is (not rendered as HTML), which is acceptable
   since these files are prompts, not documentation.

3. **The Anthropic best practices doc recommends this approach.**
   Verified: Fetched and read the full page at
   `platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices`.
   Relevant quote: "Wrap each type of content in its own tag (e.g.
   `<instructions>`, `<context>`, `<input>`) reduces misinterpretation."
   Also: "Wrap examples in `<example>` tags (multiple examples in
   `<examples>` tags) so Claude can distinguish them from instructions."

4. **Existing code block language identifiers are inconsistent.**
   Verified: Multiple files have response patterns or output examples in
   code blocks tagged with wrong languages (```bash, ```typescript,
   ```yaml for plain text content). These will be fixed as part of this
   work since they affect Claude's parsing of the content.

## Tag Vocabulary

Consistent tag names used across all files:

| Tag | Semantics | When to use |
|-----|-----------|-------------|
| `<examples>` | Container for multiple examples | Wraps a set of related examples |
| `<example>` | Single complete example | Good/bad code patterns, usage examples, sample sessions |
| `<rules>` | Non-negotiable constraints | Iron Laws, Sacred Rules, Quality Gates, Guardrails |
| `<output_format>` | Report/output templates | Structured report formats the agent must produce |
| `<gate>` | Decision procedures | Gate functions, decision trees that must be followed step-by-step |
| `<anti-pattern>` | Violation + diagnosis + fix | Named anti-patterns with explanation and remedy |
| `<template>` | Document templates | Plan doc, ADR, PLAN.md/WIP.md/LEARNINGS.md templates |
| `<checklist>` | Ordered verification lists | Quality gates, phase completion, review checklists |

**Nesting rules:**
- `<examples>` contains one or more `<example>` children
- Other tags are standalone (not nested)
- Tags wrap existing markdown content — headers, code blocks, lists stay inside

**Attribute conventions:**
- `<example type="good">` or `<example type="bad">` for good/bad patterns
- `<example label="...">` for a short description
- `<anti-pattern name="...">` for named anti-patterns
- `<gate name="...">` for named decision gates

## File Inventory and Scope

### In scope (10 files, HIGH/MEDIUM-HIGH benefit)

| File | Lines | Key content types mixed | Phase |
|------|-------|------------------------|-------|
| tdd-guardian.md | 426 | Rules, examples, response patterns, report template, gate | 1 |
| testing-anti-patterns.md | 283 | Anti-patterns, gate functions, rules, examples | 1 |
| py-enforcer.md | 632 | Rules, examples, response patterns, report template | 1 |
| pr-reviewer.md | 750 | Rules, detection commands, report template, response patterns | 2 |
| refactor-scan.md | 524 | Rules, examples, response patterns, report template | 2 |
| phase-plan.md | 794 | Rules, templates, checklists, usage patterns, anti-patterns | 3 |
| progress-guardian.md | 380 | Templates, response patterns, anti-patterns | 3 |
| learn.md | 422 | Discovery questions, response patterns, templates | 3 |
| adr.md | 894 | Decision framework, examples (5 full ADRs), templates, anti-patterns | 4 |
| docs-guardian.md | 799 | Checklists, templates (3), response patterns | 4 |

### Out of scope (12 files, LOW benefit — not worth the token overhead)

| File | Lines | Reason to skip |
|------|-------|---------------|
| effective-design-overview.md | 290 | Pure knowledge/reference, no content type mixing |
| hexagonal-architecture.md | 365 | Pure knowledge/reference |
| cli-distribution.md | 493 | Pure knowledge/reference |
| skill-hygiene.md | 203 | Pure knowledge/reference |
| structured-output-schema-design.md | 244 | Pure knowledge/reference |
| systematic-debugging.md | 118 | Short, already well-structured by phases |
| use-case-data-patterns.md | 187 | Already uses `<example>` tags, focused |
| commands/pr.md | 113 | Short, single content type |
| commands/generate-pr-review.md | 356 | Analysis steps, not enforcement |
| commands/s.md | 13 | Trivial |
| commands/skills.md | 20 | Trivial |
| CLAUDE.md | 171 | Project config, rules already clear |

## Phases

### Phase 1: Enforcement Agents

**Goal:** Add XML tags to the three enforcement agents that have the highest
compliance requirements. These agents tell Claude what it MUST do — clear
semantic boundaries between rules, examples, and output formats matter most here.

**Changes:**
- [ ] `tdd-guardian.md` — Wrap Sacred Cycle in `<rules>`, code examples in
  `<examples>`/`<example>`, Mock Decision Gate in `<gate>`, response patterns
  in `<example>`, report template in `<output_format>`, Quality Gates in
  `<checklist>`. Fix code block language identifiers (```bash → ```text for
  text response patterns, ```markdown → ```text where appropriate).
- [ ] `testing-anti-patterns.md` — Wrap Iron Laws in `<rules>`, each anti-pattern
  in `<anti-pattern>`, each gate function in `<gate>`, Quick Reference table
  stays as-is (already clear).
- [ ] `py-enforcer.md` — Wrap Critical Violations in `<rules>`, code examples
  in `<examples>`/`<example>`, response patterns in `<example>`, report
  template in `<output_format>`, Quality Gates in `<checklist>`, validation
  boundary examples in `<examples>`.

**Call chain:** Not applicable — these are prompt files, not code. The "entry
point" is Claude loading the agent definition when the agent is invoked.

**Wiring test:** Not applicable in the traditional sense. Validation is manual:
invoke each agent after changes and confirm it follows the tagged instructions
correctly. Since this is a documentation-level change, the wiring test equivalent
is the consistency check described in Validation.

**Depends on:** Nothing.

**Risks:**
- XML tags inside markdown code blocks could be confusing if not careful about
  escaping. Mitigation: XML tags wrap the code block, not go inside it.
- Token overhead increases file sizes. Mitigation: tags are short (<30 chars
  each), total overhead per file is ~200-400 tokens — negligible vs. file sizes
  of 3000-7000 tokens.

**Done when:**
1. **Behavioral:** All three files have consistent XML tags wrapping examples,
   rules, output formats, gates, and anti-patterns. Code block language
   identifiers are correct. Files are still readable as markdown.
2. **Verification:** Manual review — open each file, confirm tags are
   well-formed, consistent with vocabulary, and don't break markdown structure.
   Grep for the tag vocabulary to confirm usage: `grep -c '<rules>\|<example>\|<output_format>\|<gate>' tdd-guardian.md testing-anti-patterns.md py-enforcer.md`

**Validation:** Narrow scope (internal documentation change). Manual review of
each file for tag consistency and markdown integrity is sufficient. No need to
run the agents — the change is additive and doesn't alter any instruction content.

---

### Phase 2: Review Agents

**Goal:** Add XML tags to the two review agents. These produce structured
reports and have detection commands mixed with output format templates —
clear tagging helps Claude distinguish "run these commands" from "produce
output in this format."

**Changes:**
- [ ] `pr-reviewer.md` — Wrap review criteria per category in consistent
  structure, detection commands stay as code blocks (they're already clear),
  report template in `<output_format>`, response patterns in `<example>`,
  Quality Gates in `<checklist>`, Quick Reference rules in `<rules>`.
  Fix code block language identifiers.
- [ ] `refactor-scan.md` — Wrap Sacred Rules in `<rules>`, semantic vs
  structural examples in `<examples>`/`<example>`, DRY examples in
  `<examples>`, report template in `<output_format>`, response patterns
  in `<example>`, Quality Gates in `<checklist>`, refactoring pattern
  examples in `<examples>`.

**Call chain:** Same as Phase 1 — prompt files loaded by Claude on agent invocation.

**Wiring test:** Same as Phase 1 — manual consistency review.

**Depends on:** Phase 1 (establishes the tag vocabulary and conventions; Phase 2
follows the same patterns for consistency).

**Risks:** Same as Phase 1.

**Done when:**
1. **Behavioral:** Both files have consistent XML tags. Tag vocabulary matches
   Phase 1 conventions. Code block languages are correct.
2. **Verification:** `grep -c '<rules>\|<example>\|<output_format>\|<checklist>' pr-reviewer.md refactor-scan.md`

**Validation:** Narrow. Manual review sufficient.

---

### Phase 3: Planning and Progress Agents

**Goal:** Add XML tags to the planning skill and progress tracking agents.
These are template-heavy files where `<template>`, `<checklist>`, and `<rules>`
tags help Claude distinguish "this is the format to follow" from "this is
context about why."

**Changes:**
- [ ] `skills/phase-plan.md` — Wrap plan doc template in `<template>`,
  phase completion checklist in `<checklist>`, execution rules in `<rules>`,
  guardrails in `<rules>`, Isolation Trap anti-pattern in `<anti-pattern>`,
  usage pattern examples in `<examples>`. The Phase 0 and Phase N templates
  stay inside the main `<template>` as nested markdown.
- [ ] `progress-guardian.md` — Wrap PLAN.md, WIP.md, LEARNINGS.md templates
  in `<template>`, anti-patterns in `<anti-pattern>` or `<rules>`, example
  session in `<example>`. Fix code block language identifiers.
- [ ] `learn.md` — Wrap documentation proposal format in `<output_format>`,
  example learning integration in `<example>`, response patterns in
  `<example>`, Quality Gates in `<checklist>`. Fix code block language
  identifiers.

**Call chain:** Prompt files loaded by Claude on skill/agent invocation.

**Wiring test:** Manual consistency review.

**Depends on:** Phases 1-2 (established conventions).

**Risks:**
- phase-plan.md is the most complex file (794 lines, many section types).
  The plan doc template section already contains markdown code blocks which
  contain template content — wrapping this in `<template>` requires care to
  not create ambiguity between "this is the template" and "this is a code
  block showing the template." Mitigation: the `<template>` tag wraps the
  entire section including the code block, making it clear that everything
  inside is template content.

**Done when:**
1. **Behavioral:** All three files have consistent XML tags. Template sections
   are clearly demarcated. Checklists, rules, and examples are tagged.
2. **Verification:** `grep -c '<template>\|<rules>\|<checklist>\|<example>\|<output_format>' skills/phase-plan.md progress-guardian.md learn.md`

**Validation:** Moderate scope (phase-plan.md is a high-use file). After
tagging, re-read the phase-plan execution rules and checklist sections to
confirm the tags enhance rather than obscure the instructions. This is the
file most likely to surface issues since it's the most complex.

---

### Phase 4: Documentation Agents

**Goal:** Add XML tags to the two documentation agents. These are the largest
files (894 and 799 lines) and are example-heavy — adr.md has 5 complete ADR
examples that currently look identical to the instructions surrounding them.

**Changes:**
- [ ] `adr.md` — Wrap ADR format in `<template>`, each of the 5 example ADRs
  in `<example>`, decision framework in `<gate>`, anti-patterns in
  `<anti-pattern>`. Fix code block language identifiers (several examples
  end with wrong language tags).
- [ ] `docs-guardian.md` — Wrap 7 Pillars in `<rules>`, anti-patterns to avoid
  in `<rules>`, three documentation templates (README, Concept Guide, API
  Reference) in `<template>`, Quality Gates checklist in `<checklist>`,
  response patterns in `<example>`. Fix code block language identifiers.

**Call chain:** Prompt files loaded by Claude on agent invocation.

**Wiring test:** Manual consistency review.

**Depends on:** Phases 1-3 (established conventions).

**Risks:**
- adr.md has the most examples (5 full ADR documents). These are long
  (50-100 lines each) and already in code blocks. Wrapping the entire
  code block in `<example>` is straightforward but increases nesting depth.
  Mitigation: `<example>` wraps the code block — the code block content
  stays unchanged.
- docs-guardian.md has 3 full document templates. Same approach as adr.md.

**Done when:**
1. **Behavioral:** Both files have consistent XML tags. The 5 ADR examples
   in adr.md are clearly demarcated from instructions. The 3 templates in
   docs-guardian.md are clearly demarcated. Code block languages are correct.
2. **Verification:** `grep -c '<template>\|<example>\|<rules>\|<anti-pattern>\|<gate>\|<checklist>' adr.md docs-guardian.md`

**Validation:** Moderate (these are large files). After tagging, scan the
examples in adr.md to confirm the `<example>` boundary is clear — the main
risk is Claude treating an example ADR as an instruction.

---

## Open Questions

- [RECOMMENDED: ADVISORY] **Should we add a tag vocabulary reference to
  CLAUDE.md or agents.md?** A short section documenting the tag vocabulary
  would help future contributors maintain consistency when adding new agents
  or skills. *Rationale: this is a nice-to-have that can be done after the
  main work. The vocabulary is documented in this plan and will be evident
  from the files themselves.*

- [RECOMMENDED: ADVISORY] **Should code block language identifier fixes be
  tracked separately?** Several files have response patterns in code blocks
  tagged ```bash or ```typescript when the content is plain text. These fixes
  are bundled into each phase since they're small and closely related to the
  parsing improvement goal. *Rationale: bundling is simpler and the fixes
  are small. Tracking separately would add overhead without benefit.*

- [RECOMMENDED: ADVISORY] **Should we measure the impact?** We could compare
  agent compliance before and after by running the same prompt through an
  agent pre- and post-tagging. *Rationale: measurement would be interesting
  but expensive (requires controlled testing). The Anthropic recommendation
  is evidence enough to proceed. We can monitor qualitatively during normal
  use.*

## Review Log

(To be filled by subsequent passes)
