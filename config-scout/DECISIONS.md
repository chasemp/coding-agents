# Config Scout Decision Journal

Cumulative record of what we adopted, deferred, and rejected from external
configurations — and the patterns that emerge across those decisions over time.

---

## Deferred Investigations

Items that surfaced across comparisons but haven't been implemented yet. When
the same idea appears from multiple independent sources, it gets a tally mark.
High-tally items should be revisited — recurring signals from the community are
stronger than any single source.

| Item | Sources | Tally | First Seen | Notes |
|------|---------|-------|------------|-------|
| Research/feasibility gate before coding | shanraisshan-rpi | 1 | 2026-03-13 | Lightweight "should we build this?" check. Not full waterfall — just a structured pause. |
| Persistent feature folders for multi-session work | shanraisshan-rpi | 1 | 2026-03-13 | Extend progress-guardian's PLAN/WIP/LEARNINGS to persist across sessions. |
| Multi-perspective pre-implementation review | shanraisshan-rpi | 1 | 2026-03-13 | Examine feature from 2+ angles before coding. Lighter than full PM/UX/eng split. |
| Feature lifecycle documentation template | shanraisshan-rpi | 1 | 2026-03-13 | Capture full arc: motivation → research → decisions → implementation → outcomes. |
| Model tier optimization across agents | shanraisshan-rpi, obra-superpowers | 2 | 2026-03-13 | Evaluate which agents benefit from opus vs sonnet. Superpowers uses model selection by task complexity. |
| Receiving code review skill | obra-superpowers | 1 | 2026-03-13 | How to evaluate review feedback with rigor, not performative agreement. Novel angle we don't cover. |
| Session-start hooks | obra-superpowers | 1 | 2026-03-13 | Auto-load context at session begin. Our @import system partially covers this. |

---

## Entries

### 2026-03-13 — shanraisshan-rpi-workflow

**Source**: https://github.com/shanraisshan/claude-code-best-practice
**Report**: `config-scout/2026-03-13_shanraisshan-rpi-workflow.md`

**Adopted:**
- Retry/bail limits for agents → CLAUDE.md development workflow section | Rationale: Prevents agents from spinning on failing approaches. Simple guardrail with high value. Sourced from RPI's implement.md "two unsuccessful attempts" pattern.

**Deferred:**
- Research/feasibility gate → see Deferred Investigations table | Reason: Valuable concept but needs design work to fit TDD-first philosophy. Don't want to add waterfall overhead.
- Persistent feature folders → see Deferred Investigations table | Reason: Current PLAN/WIP/LEARNINGS works within sessions. Need to feel the pain of multi-session work more before designing a solution.
- Model tier hints across agents → see Deferred Investigations table | Reason: All agents already on sonnet. Need benchmarking data on where opus makes a measurable difference before changing.

**Rejected:**
- Role-based agent personas (PM, CTO, UX) | Reason: Conflicts with discipline-verification philosophy. Role-play agents carry generic context; our discipline-based agents are more focused and testable. Strategic thinking is covered by effective-design-overview and ADR.
- Heavyweight waterfall planning pipeline | Reason: Directly conflicts with TDD-first, small-increment core philosophy. The overhead would slow the RED-GREEN-REFACTOR cycle.
- Agent color/theme metadata | Reason: Cosmetic. No functional value in CLI context. (Our agents already have `color:` in frontmatter for display purposes, which is sufficient.)

**Patterns Noticed:**
- *Selection bias*: This is our first comparison, so no bias pattern yet. RPI comes from a product-feature perspective (startup building user-facing apps) while AlpheusCEF is developer-tooling focused. Future comparisons should include at least one source from a similar domain (CLI tools, developer infrastructure).
- *Complementary niches*: RPI is strong where we're weak (upstream "should we build it?" decisions) and weak where we're strong (code quality discipline during implementation). This suggests our next growth area is the pre-implementation decision space, not deeper code quality enforcement.
- *Surprise value*: The biggest surprise was how little overlap there was. Two comprehensive Claude Code setups with almost entirely different focus areas. This suggests the space is still immature — people are solving the problems they personally feel, not converging on a shared understanding of what matters.
- *Scope evolution*: Adding the bail limit is coherent — it's a workflow guardrail that fits our existing philosophy. The deferred items (research gate, feature folders) would expand our scope from "how to code well" toward "how to decide what to code." That's a deliberate scope expansion worth monitoring.
- *Adoption lag*: First entry, so no lag data yet. Will track going forward.

---

### 2026-03-13 — obra-superpowers

**Source**: https://github.com/obra/superpowers
**Report**: `config-scout/2026-03-13_obra-superpowers.md`
**Catalog**: `config-scout/2026-03-13_obra-superpowers_catalog.md`

**Adopted:**
- Verification before completion → CLAUDE.md development workflow | Rationale: Fills a real gap — no rule against claiming success without evidence. Source: superpowers verification-before-completion skill.
- Systematic debugging skill → skills/systematic-debugging.md (new) | Rationale: Zero debugging guidance was a genuine gap. Four-phase framework adapted with TDD handoff and test-verification step. Source: superpowers systematic-debugging skill.
- TDD 5-step sacred cycle → tdd-guardian.md | Rationale: Making VERIFY RED and VERIFY GREEN explicit steps promotes them from prose to gates. Source: superpowers test-driven-development skill.
- TDD scope definition → tdd-guardian.md | Rationale: Removes ambiguity about when TDD applies and what exceptions exist. Source: superpowers test-driven-development skill.
- "Spirit over ritual" rationalization → tdd-guardian.md | Rationale: Closes escape hatch where intent substitutes for execution. Source: superpowers test-driven-development skill.
- Delete-and-restart mandate → tdd-guardian.md | Rationale: "Comment out" leaves temptation to uncomment. "Delete and restart from RED" is unambiguous. Source: superpowers test-driven-development skill.
- Plan alignment in PR review → pr-reviewer.md Category 0 | Rationale: Reviewers should check "is this what we planned?" not just "is this good code?" Source: superpowers code-reviewer agent.
- Agent orchestration sequences → agents.md | Rationale: 9 agents with no coordination guidance meant orchestration lived in operator's head. Source: superpowers subagent-driven-development skill (adapted from executor to enforcer model).
- Task granularity and step specificity → progress-guardian.md | Rationale: Plan steps were too abstract. File paths, specific test names, and verify commands make plans actionable. Source: superpowers writing-plans skill.
- Skill hygiene discipline → skills/skill-hygiene.md (new) | Rationale: As we incorporate external ideas, we need refactoring discipline for the instruction set itself. Source: superpowers writing-skills skill + Anthropic's official skill authoring best practices.

**Deferred:**
- Model tier optimization → see Deferred Investigations table (tally now 2) | Reason: Superpowers reinforces this with explicit model selection strategy. Worth investigating after more data.
- Receiving code review skill → see Deferred Investigations table | Reason: Interesting angle on evaluating feedback rigor, but not an active pain point yet.
- Session-start hooks → see Deferred Investigations table | Reason: Our @import system covers the core need.

**Rejected:**
- Plugin/marketplace distribution model | Reason: Different scope. We share via symlinks across a monorepo, not via public marketplace.
- Brainstorming skill | Reason: Covered by effective-design-overview skill from a different (DDD) angle.
- Git worktree management | Reason: Operational tooling, not philosophical guidance.
- Subagent-as-executor pattern | Reason: Our agents are discipline enforcers, not task executors. Adopted the orchestration patterns but adapted the paradigm.

**Patterns Noticed:**
- *Selection bias*: Second comparison, both from the Claude Code ecosystem. Superpowers is closer to our domain (developer tooling) than RPI was (product features). Good to have one of each, but next comparison should be from outside the Claude Code world — a Cursor rules setup, or a team's .github/copilot-instructions.
- *Rejection patterns*: We keep rejecting role-based agents (PM/CTO in RPI, now subagent-as-executor in superpowers). This is principled, not a blind spot — our discipline-enforcer model is verifiable and focused. But the *strategic thinking* these role agents provide is worth noting. We get it through skills (effective-design-overview) rather than agents.
- *Adoption lag*: Zero lag on this comparison — all recommendations were decided in-session. This is the benefit of having a structured decision process (config-scout → catalog → deep dive → one-at-a-time review).
- *Surprise value*: The biggest surprise was verification-before-completion. We enforce test-first rigorously but had no rule against the simpler failure mode of just saying "Done." without evidence. The gap was hiding in plain sight because we assumed TDD covered it — it does not.
- *Scope evolution*: This batch added two new skills (systematic-debugging, skill-hygiene), enhanced three existing agents (tdd-guardian, pr-reviewer, progress-guardian), and defined orchestration patterns. The additions are coherent — debugging and verification are quality disciplines, skill-hygiene is meta-quality, orchestration is infrastructure. All serve the core philosophy. No scope creep detected.
- *Emerging consensus*: TDD-as-non-negotiable now appears in all three sources we've analyzed (our own, RPI, superpowers). Verification-before-completion appears in superpowers and aligns with our existing "watched-it-fail" principle. The community is converging on "prove it, don't claim it."

---

