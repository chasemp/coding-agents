# Development Guidelines for Claude

> **About this file (v3.0.0):** Lean version optimized for context efficiency. Core principles here; detailed patterns loaded on-demand via skills.
>
> **Architecture:**
> - **CLAUDE.md** (this file): Core philosophy + quick reference (~100 lines, always loaded)
> - **Skills**: Detailed patterns loaded on-demand (testing-anti-patterns, effective-design-overview, hexagonal-architecture, systematic-debugging, cli-distribution, skill-hygiene)
> - **Agents**: Specialized subprocesses for verification and analysis
>
> **Previous versions:**
> - v2.0.0: Modular with @docs/ imports (~3000+ lines always loaded)
> - v1.0.0: Single monolithic file (1,818 lines)

## Core Philosophy

**TEST-DRIVEN DEVELOPMENT IS NON-NEGOTIABLE.** Every single line of production code must be written in response to a failing test. No exceptions. This is not a suggestion or a preference - it is the fundamental practice that enables all other principles in this document.

I follow Test-Driven Development (TDD) with a strong emphasis on behavior-driven testing and functional programming principles. All work should be done in small, incremental changes that maintain a working state throughout development.

## Backwards Compatibility

For pre-1.0 projects, backwards compatibility is **not the default**. No deprecation layers, migration paths, re-exports, or aliases — just change it. If you think something needs backwards compat, ask first.

## Quick Reference

**Key Principles:**

- Write tests first (TDD)
- Test behavior, not implementation
- Strict type safety (no `any`, `typing.Any`, or `interface{}` without justification)
- Immutable data only
- Small, pure functions
- Use real schemas/types in tests, never redefine them
- Fail loud, fail early — no silent fallbacks or swallowed errors

**Supported Languages:**

- **TypeScript**: Strict mode, Jest/Vitest, React Testing Library
- **Python**: Type hints with mypy, pytest, no mutable defaults
- **Go**: Strict compilation, table-driven tests, explicit errors
- **Rust**: `cargo test`, `clippy::pedantic`, `Result<T, E>` always, no `unwrap()` in production, `#[derive(Debug)]` on public types, `Zeroize` for secret material

Choose the language that best fits the domain - TypeScript for web/frontend, Python for data/ML/scripting, Go or Rust for systems/performance (Rust when you need memory safety guarantees, sub-runtime determinism, or tight crypto/FFI; Go when goroutine concurrency or stdlib breadth matters more than fine-grained control).

## Testing Principles

**Core principle**: Test behavior, not implementation. 100% coverage through business behavior.

**Quick reference:**
- Write tests first (TDD non-negotiable)
- **Watch the test fail** — if you didn't see it fail, you don't know if it tests the right thing
- Test through public API exclusively
- Use factory functions for test data (no mutable setup in `beforeEach`/fixtures)
- Tests must document expected business behavior
- No 1:1 mapping between test files and implementation files

**Testing Tools by Language:**
- **TypeScript**: Jest, Vitest, React Testing Library
- **Python**: pytest (with fixtures for immutable setup), unittest
- **Go**: standard `testing` package, table-driven tests
- **Rust**: built-in `cargo test`. **Inline unit tests** in `#[cfg(test)] mod tests { ... }` blocks at the bottom of the source file (idiomatic for library crates). **Integration tests** in `tests/` directory (one file per scenario). Table-driven via `#[test_case::test_case]` or `rstest` parameterized tests. Property tests via `proptest` for parsers/crypto round-trips. The `mockall` crate for behavior-mocking interfaces (use sparingly — prefer real types).

**Mutation testing — the check on the check.** RED-first proves a test fails *once*, against the one stub you happened to write. It does not prove the test still fails against the bug you'll actually introduce later. Mutation testing does: it perturbs production code one line at a time and reports every mutation the suite still passes. **Expected on any non-trivial module, and the expectation rises with complexity** — rules engines, encoders/decoders, search, parsers, and state machines are where a green suite most easily hides a hole.

- **When**: after a module goes green, before you call the phase done. Not per-commit — it is a periodic audit, not a gate. Re-run it when you change the logic it covered.
- **Tools**: Rust `cargo mutants` · TypeScript `stryker` · Python `mutmut` or `cosmic-ray` · Go `go-mutesting`.
- **Read the survivors, don't chase the score.** Every run produces **equivalent mutants** — mutations that provably cannot change behaviour, so no test can kill them. Real examples: `(row + col) % 2` → `(row - col) % 2` (same parity), `a | b` → `a ^ b` on disjoint bit fields, `2 * dr` → `2 / dr` where `dr` is `±1`. Triage each survivor into *equivalent* or *real gap*, and say which in the write-up. A repo chasing 100% adds assertions that pin implementation detail — the exact anti-pattern the rest of this file is about.
- **A timeout is a kill.** A mutation that makes the suite hang has been detected; it just failed slowly.
- **Commit before you mutate — before EVERY round, not just the first.** That is the whole rule. Mutation testing deliberately edits *working* code, so the restore path must be as trustworthy as the mutation itself. A tool (`cargo mutants`, `mutmut`) handles this for you; a **hand-run** mutation does not. Two traps, both observed in one session:
  - `cp file /tmp/f.bak` — a stale backup from an earlier refactor silently restores the *wrong* version, so you have "restored" a regression into a green suite. Only a compile error caught it; a version that still compiled would have shipped.
  - **`git stash push` + `git checkout -- <path>` + `git stash drop`** — this looks like the disciplined fix and is worse. `stash push` resets the index to `HEAD`, so the later `checkout` restores **HEAD**, not your pre-mutation state, and `drop` then discards the only copy. Recoverable via `git fsck --unreachable` + `git checkout <dangling-sha> -- <paths>`, but only if you notice.
  
  **The reliable pattern: commit the green state first, mutate, then `git checkout HEAD -- <path>`** — and note the ORDER is the rule, not the command. `git checkout HEAD -- <path>` is a restore only when the state you want back is already in HEAD; run it on a file with uncommitted work and it is a delete. See "Destructive git operations" below. Uncommitted work is not a restore point, and a phase's worth of work should never be the thing standing between a mutation and its undo. Re-run the *full* suite after every restore, not just the mutated test — a bad restore shows up in the tests you weren't looking at. *The observed failure mode is round two:* the green state was committed correctly before the first mutation, then a later round ran against fixes not yet committed and reused the same restore command from muscle memory (2026-08-26). Knowing the rule did not help; the restore command is identical either way, and only `git status --porcelain <path>` at that instant distinguishes a restore from a delete.
- **What survivors usually mean.** Three patterns dominate: an API added for convenience with no caller in a test; a trait/interface impl that only delegates, where every test calls the underlying function directly; and an unreachable defensive branch. The first two are cheap to close. For the third, extract the policy into a function a test can reach — if a branch cannot be reached from any real input, it cannot be verified in place, and "unreachable" is a claim worth a test of its own.

For testing anti-patterns and how to fix them, load the `testing-anti-patterns` skill.

## Type Safety Guidelines

**Core principle**: Strict typing always. Schema-first at trust boundaries, types for internal logic.

**TypeScript:**
- No `any` types - use `unknown` if type truly unknown
- Prefer `type` over `interface` for data structures
- Define schemas first, derive types (Zod/Standard Schema)

**Python:**
- Always use type hints (PEP 484)
- No `typing.Any` - use `object` or `typing.Protocol` if needed
- Use Pydantic/dataclasses for schemas at boundaries
- Run mypy in strict mode

**Go:**
- No `interface{}` without clear justification - use generics (Go 1.18+)
- Explicit error handling (never ignore errors)
- Use struct tags for validation/serialization

**Rust:**
- No `unsafe` blocks without a `// SAFETY:` comment justifying why the invariants hold and what the caller must uphold
- No `unwrap()` or `expect()` in production code paths — only in tests and in truly-impossible-error paths (with `expect("not possible because <reason>")`)
- Every public item carries a doc comment (`#![warn(missing_docs)]`)
- `Result<T, E>` for fallible operations; never panic from library code; reserve panics for `unreachable!()`-shaped invariant violations
- Define error types with `thiserror`; do not return raw strings
- Use newtype wrappers (`pub struct UserId(pub u64);`) at semantic boundaries; do not pass primitives where domain types belong
- Derive `Debug` on all public types unless secrecy demands manual implementation (e.g., key material — see `Zeroize` below)
- Secret material (keys, passwords, derived secrets) lives in newtype wrappers that derive `Zeroize` + `ZeroizeOnDrop`; never log, never `Debug`-print, never serialize without an explicit "I-know-what-I'm-doing" wrapper
- `clippy::pedantic` clean (with explicit `#[allow(clippy::name)]` and a comment for justified exceptions)
- `cargo fmt --check` clean; no skipped formatting

For Python type patterns, use built-in type system with runtime validation at boundaries.
For Go patterns, follow standard library conventions.
For Rust patterns, see `rust-enforcer.md` for the full discipline doc.

## Code Style

**Core principle**: Functional programming with immutable data. Self-documenting code.

**Quick reference:**
- **Fail loud, fail early** - no silent fallbacks or degraded modes. If a dependency, library, or operation fails, raise/throw immediately. Never silently fall back to an alternative approach unless the user has explicitly defined fallback behavior for that case.
- No data mutation - immutable data structures only
- Pure functions wherever possible
- No nested if/else - use early returns or composition
- Prefer simple, self-documenting code. Comments explaining WHY (not WHAT) are welcome when needed. If WHAT needs explanation, the code may be too complex or clever.
- Prefer options objects/dicts over positional parameters
- Use functional patterns:
  - **TypeScript/Python**: `map`, `filter`, `reduce` over loops
  - **Go**: prefer explicit loops with clear intent, avoid mutation
  - **Python**: list comprehensions, generator expressions
  - **TypeScript**: avoid `for...in`, use `for...of` or array methods
  - **Rust**: iterator adapters (`.map()`, `.filter()`, `.fold()`, `.collect()`) over loops where it doesn't sacrifice readability; prefer `Option`/`Result` combinators (`.map_err`, `.and_then`, `.ok_or`) over `match` for simple flows; use `?` for error propagation; prefer pattern matching with `match` (not `if let` chains) when handling multiple variants

## Development Workflow

**Core principle**: RED-GREEN-REFACTOR in small, known-good increments. TDD is the fundamental practice.

**Quick reference:**
- RED: Write failing test first (NO production code without failing test)
- GREEN: Write MINIMUM code to pass test
- REFACTOR: Assess improvement opportunities (only refactor if adds value)
- **No category of production code is exempt from TDD** — data definitions, schemas, configs, constants, and mappings all require a failing test first. The thought "this is too simple/mechanical/data-only to need a test" is the signal to stop and write the test. This rationalization is how untested code accumulates.
- **Wait for commit approval** before every commit
- Each increment leaves codebase in working state
- Capture learnings as they occur, merge at end
- **Destructive git operations discard uncommitted work — check before, not after.**
  `git checkout HEAD -- <path>`, `git restore <path>`, `git stash drop`, `git reset
  --hard`, and `git clean` all silently destroy anything not committed. Before any of
  them, run `git status --porcelain <path>`: if it prints, that content exists nowhere
  else and the command is a delete, not a restore. Commit or stash first (and if you
  stash, remember `stash push` resets the index to HEAD — the classic
  stash/checkout/drop sequence restores HEAD, not your pre-change state, then discards
  the only copy). *Why this is a top-level rule and not a testing footnote:* agents
  have hit it while simply reverting a bad edit, and reported afterwards "I hit the
  exact trap CLAUDE.md warns about" — knowing the rule at session start does not stop
  it; checking `git status` at the moment of the command does. Recovery if you already
  ran it: `git fsck --unreachable` may still hold the blob.
- **Bail on repeated failure**: If an approach fails twice, stop and reassess with the user before trying alternatives. Do not spin on a failing strategy.
- **Validation must be CONCURRENT with the completion claim.** Before asserting success, run the proving command, read complete output and exit code, confirm it supports the claim. "Should work" or "probably" without a run is not acceptable, and confidence from a previous run does not count — unverified claims are indistinguishable from hallucinations. But "fresh" is not the test, because *fresh enough?* has no answer. **Concurrent** does: nothing may have changed between the validation and the claim, in any of three ways.
  - **Concurrent in TIME** — the state you validated is the state you are claiming about. A check that was *true when it ran* and was invalidated by a rebase, a peer's commit, or your own later edit is worse than no check: it leaves justified confidence. Re-evaluate against the tree you are actually committing. *(Observed: a registry scanned for duplicate ids returned a clean answer, then the same id was allocated from a newer base — the scan was correct and had expired.)*
  - **Concurrent in EXTENT** — the evidence must cover the whole claim, not its first screen. A piped `head`/`tail`/`grep -c` must never back the word "verified"; read `--stat` first to learn the size, then the full output. *(Observed: `git show <sha> | head -8` showed an unrelated change and missed the fix below the fold; "verified independently" then travelled to a third party as a wrong conclusion.)*
  - **Concurrent in SUBJECT** — the evidence must support *this* claim, not an adjacent one. A mechanism that FITS the evidence is not the evidence. Capture the actual failure before naming a cause, and when a fix changes two things, say which one was the fix or the visible one takes the credit. *(Observed: a visible `sleep` was blamed by three sessions for a failure actually caused by an invisible repaint race.)*

  **None of the three is caught by running the check more often** — that is what separates them from carelessness, and why "check more carefully" is the wrong remedy.
- **Plans record the why, not just the what.** Any plan in `plans/` (or the project's equivalent location) must carry **Problem Statement**, **Approach**, and **Reasoning** — not just a change list. If a future reader cannot reconstruct *why* the change was proposed from the plan alone, the plan is incomplete. Format is flexible; presence of these three semantic elements is not. The `plan-doc-reasoning` skill enforces the floor; `phase-plan` prescribes the full template for complex changes.

## External APIs

**Core principle**: Never guess or infer API endpoints, payload shapes, or field names. Always verify against a source of truth before writing any code.

**Required sources (in priority order):**
1. OpenAPI/Swagger specs in the repo (e.g., `docs/api/openapi.json`)
2. Confirmed response samples from actually running a probe request
3. Official API documentation

**Rules:**
- If an endpoint or field name is not confirmed by one of the above, stop and ask — do not write code against it
- Do not write "likely follows this pattern" stubs — leave a TODO and get confirmation first
- For any new API integration: write a minimal probe script first, print the raw response, confirm field names before building logic on top of it
- Never trust field names inferred from other parts of the codebase or documentation that says "likely" or "expected"

## Working with Claude

**Core principle**: Think deeply, follow TDD strictly, capture learnings while context is fresh.

**Quick reference:**
- ALWAYS FOLLOW TDD - no production code without failing test
- Assess refactoring after every green (but only if adds value)
- Update CLAUDE.md when introducing meaningful changes
- Ask "What do I wish I'd known at the start?" after significant changes
- Document gotchas, patterns, decisions, edge cases while context is fresh

## Homebrew Workflow

- Always use `brew install` or `brew reinstall` from the tap — never use `pip install` or `--build-from-source`
- Always `git push` to remote before running `brew install` so the formula can fetch the latest tarball
- When updating formulas, bump the version AND verify the SHA256 matches the actual release asset (prefer uploaded release assets over GitHub auto-generated tarballs for deterministic hashes)
- Before using `git checkout --orphan` or any destructive git operation, stash or commit all tracked modifications first. Verify working tree is clean after branch operations.
- **Rust-compiled Python extensions (.so) and dylib relocation:** Homebrew's `fix_dynamic_linkage` step runs `ruby-macho` on every Mach-O file in the cellar between `install` and `post_install`. Rust extensions (cryptography, jiter, pydantic-core) have compact headers that fail rewriting. Fix: build the venv in `var/<name>-staging` during `install` (outside the cellar), then move it to `libexec/` in `post_install` after relocation completes. Rewrite shebangs and `pyvenv.cfg` after the move. See `cli-distribution` skill for the full pattern.

## Resources and References

**TypeScript:**
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [Testing Library Principles](https://testing-library.com/docs/guiding-principles)
- [Kent C. Dodds Testing JavaScript](https://testingjavascript.com/)

**Python:**
- [Python Type Hints (PEP 484)](https://peps.python.org/pep-0484/)
- [pytest Documentation](https://docs.pytest.org/)
- [Effective Python](https://effectivepython.com/)

**Go:**
- [Effective Go](https://go.dev/doc/effective_go)
- [Go Testing Package](https://pkg.go.dev/testing)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)

**Rust:**
- [The Rust Programming Language ("the book")](https://doc.rust-lang.org/book/)
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Clippy Lints](https://rust-lang.github.io/rust-clippy/master/)
- [The Rustonomicon](https://doc.rust-lang.org/nomicon/) (when `unsafe` is unavoidable)
- [Effective Rust](https://www.lurklurk.org/effective-rust/) (Brett Slatkin-shape Item-based guide)

## Summary

The key is to write clean, testable, functional code that evolves through small, safe increments. Every change should be driven by a test that describes the desired behavior, and the implementation should be the simplest thing that makes that test pass. When in doubt, favor simplicity and readability over cleverness.
