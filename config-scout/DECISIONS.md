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
| Agent `permissionMode` field | shanraisshan-full-repo | 1 | 2026-03-13 | Read-only agents could use restrictive modes to prevent accidental writes. Needs testing with subagents. |
| Agent `skills` preloading field | shanraisshan-full-repo | 1 | 2026-03-13 | tdd-guardian could preload testing-anti-patterns, adr could preload effective-design-overview. Makes skill references mechanical instead of advisory prose. |
| Command→Agent→Skill delegation hierarchy | shanraisshan-full-repo | 1 | 2026-03-13 | Hierarchical orchestration where commands invoke agents that preload skills. Different from our pipeline model — solves feature-building, not discipline enforcement. Revisit if scope expands. |
| Workflow commands for agent sequences | shanraisshan-full-repo | 1 | 2026-03-13 | `/tdd-cycle` and `/pr-prep` to automate agent sequences. Deferred because Claude auto-invokes agents from descriptions — the manual orchestration problem doesn't exist in practice. |

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

### 2026-03-13 — shanraisshan-full-repo

**Source**: https://github.com/shanraisshan/claude-code-best-practice
**Report**: `config-scout/2026-03-13_shanraisshan-full-repo.md`
**Catalog**: `config-scout/2026-03-13_shanraisshan-full-repo_catalog.md`

**Adopted:**
- `maxTurns` frontmatter on all 9 agents → agent .md files | Rationale: Hard turn limit prevents runaway execution. Aligns with our "bail on repeated failure" principle. Analysis-only agents get 15, complex-work agents get 20. Source: shanraisshan claude-subagents.md (14 frontmatter fields documented, we used 5).
- `memory: project` on 4 agents (learn, pr-reviewer, refactor-scan, tdd-guardian) → agent .md files + agents.md | Rationale: Agent memory surfaced in every comparison (shanraisshan-rpi as "persistent feature folders," obra-superpowers implicitly, now shanraisshan-full-repo explicitly). Tally of 3 across independent sources. Agents can now accumulate project-specific knowledge across sessions. Source: shanraisshan claude-agent-memory.md.
- Agent vs Command vs Skill decision framework → agents.md "Choosing Your Mechanism" section | Rationale: We had correct classification but no documented criteria. A developer creating something new had no guidance on which primitive to reach for. Source: shanraisshan claude-agent-command-skill.md.
- Context-budget awareness in planning → progress-guardian.md plan review checklist | Rationale: TDD cycles can consume large context chunks. Step sizing guidance referenced TDD cycles but not context window as a resource. Added without an arbitrary threshold — just awareness that steps consuming most remaining context should be broken down. Source: shanraisshan CLAUDE.md workflow practices.

**Deferred:**
- `permissionMode` field → see Deferred Investigations table | Reason: Read-only agents could use restrictive modes, but needs testing to confirm behavior with subagents. Low urgency since we already restrict via tool allowlists.
- `skills` preloading field → see Deferred Investigations table | Reason: Agents reference skills in prose but don't mechanically preload them. Would make the relationship explicit. Low urgency — current prose references work.
- Command→Agent→Skill delegation hierarchy → see Deferred Investigations table | Reason: Different paradigm from our enforcement pipelines. Solves feature-building orchestration, not discipline verification. Revisit if we expand scope beyond enforcement.
- Workflow commands for agent sequences (`/tdd-cycle`, `/pr-prep`) → see Deferred Investigations table | Reason: Claude auto-invokes agents from their descriptions, so the manual orchestration problem these commands would solve doesn't exist in practice. User confirmed they don't manually invoke agent sequences today.

**Rejected:**
- `/compact` at 50% context threshold → CLAUDE.md | Reason: 50% is arbitrary. Added context-budget awareness to progress-guardian's checklist instead, without a fixed threshold. Users can compact at natural milestones (between steps, after commits) rather than hitting a number.
- `disallowedTools` field | Reason: We already restrict via tool allowlists in frontmatter. Adding a deny-list on top is belt-and-suspenders with marginal value.
- `mcpServers`, `hooks`, `background`, `isolation` fields | Reason: No current use case. pr-reviewer already configures MCP tools via the tools list. No agents need background execution or worktree isolation. These solve problems we don't have.
- "Commands for workflows not standalone agents" as a new principle | Reason: Already covered by the decision framework we adopted. Our commands already are workflow orchestrators. The principle was implicit and correct — just needed documenting, not changing.

**Patterns Noticed:**
- *Selection bias*: Third comparison, all from the Claude Code ecosystem. shanraisshan is a documentation/reference hub, not a working agent config — different character from RPI (product workflow) and superpowers (composable skill library). We're getting breadth within the ecosystem but still haven't compared against a non-Claude-Code setup (Cursor rules, copilot-instructions). That should be next.
- *Rejection patterns*: This is the first comparison where we rejected more than we adopted. The source is a reference catalog, not an opinionated setup — most value was in discovering features we weren't using (frontmatter fields) rather than philosophical patterns. We keep rejecting arbitrary thresholds and belt-and-suspenders safety mechanisms, preferring awareness and judgment over hard rules.
- *Adoption lag*: Agent memory was deferred in both previous comparisons (as "persistent feature folders" from RPI and implicitly from superpowers). Tally hit 3 and we adopted. This validates the tally system — recurring signals from independent sources do bubble up to adoption. The deferred investigations table is working as designed.
- *Surprise value*: The biggest surprise was discovering that workflow commands for agent sequences (Finding 5) solve a problem we don't have. Claude's auto-invocation from agent descriptions means the orchestration already happens without explicit user action. This is a good reminder to test assumptions against actual workflow before building solutions.
- *Scope evolution*: This comparison mostly deepened existing infrastructure (frontmatter fields, memory, documentation) rather than adding new capabilities. No new skills or agents. The setup is maturing — additions are infrastructure hardening, not capability expansion. This feels healthy.
- *Emerging consensus*: Agent persistent memory now appears across all three sources. The community is converging on agents-that-learn-over-time. Our adoption here puts us in line with this trend. The decision framework (agent vs command vs skill) also appears to be a community standard — everyone is grappling with when to use which primitive.

---

