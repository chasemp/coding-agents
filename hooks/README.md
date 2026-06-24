# TDD Enforcement Hooks

Three tiers of programmatic defense against TDD violations, from lightest to
strictest. The edit guard and stop guard are Claude Code hooks (global,
automatic). The pre-commit guard is a git hook (per-repo, opt-in).

```
┌─────────────────────────────────────────────────────────────────┐
│  Edit guard (real-time nudge)                       [global]    │
│  Prompts for confirmation when editing production code without  │
│  any test file changes in the working tree. Debounced.          │
├─────────────────────────────────────────────────────────────────┤
│  Stop guard (session gate)                          [global]    │
│  Blocks Claude from ending a session with untested production   │
│  changes in the working tree.                                   │
├─────────────────────────────────────────────────────────────────┤
│  Pre-commit guard (commit gate)                     [per-repo]  │
│  Rejects commits with production changes but no test changes.   │
│  Optionally runs the test suite. Applies to everyone.           │
└─────────────────────────────────────────────────────────────────┘
```

## How this wires together (`settings.json` ↔ this repo)

Two pieces in two places:

- **The logic** lives here, in `hooks/*.sh` (version-controlled).
- **The wiring** lives in `~/.claude/settings.json` (per-machine, **not**
  version-controlled). It holds no logic — it just *registers* the Claude Code
  hooks by pointing at the symlinked scripts. `install.sh` symlinks the scripts
  into `~/.claude/hooks/` and adds entries like:

  ```json
  "PreToolUse": [{ "matcher": "Edit|Write",
                   "hooks": [{ "type": "command",
                               "command": "/Users/<you>/.claude/hooks/tdd-edit-guard.sh" }] }],
  "Stop":       [{ "hooks": [{ "type": "command",
                               "command": "/Users/<you>/.claude/hooks/tdd-stop-guard.sh" }] }]
  ```

Consequences worth remembering:

- **Per-machine.** `settings.json` is in no repo, so a new machine needs
  `install.sh` re-run (or the entries re-added) to get the real-time guards. The
  pre-commit guard is the opposite — wired *per-repo* in `.git/hooks/`.
- **Editing the wiring is how you toggle layers.** The Claude Code hooks
  (edit/stop) turn on/off by adding/removing their `settings.json` entries; the
  git hook (pre-commit) turns on/off by installing/removing `.git/hooks/pre-commit`.
  See the two models below.
- **Stop-hook output schema (gotcha).** A Stop hook signals a block with the
  TOP-LEVEL shape `{"decision":"block","reason":"…"}`. The `hookSpecificOutput`
  envelope is only for events that carry a `hookEventName` (PreToolUse etc.) and
  is rejected by the schema for Stop. (This bit us once — the guard errored
  instead of blocking cleanly.)

## Two enforcement models

The three tiers support two coherent setups. Pick one per machine/preference;
switching is purely editing the wiring above.

### A. Real-time (the `install.sh` default)

Edit guard + stop guard active (Layers 1–2); pre-commit optional. TDD is nudged
*as you work*: editing prod without test changes prompts, and ending a session
with untested prod blocks.

- Set up: `./hooks/install.sh`
- Trade-off: catches violations early, but interrupts mid-flow — the edit guard
  "asks" even when `Edit`/`Write` are allowlisted, because a hook "ask"
  overrides the permission allow. (`--dangerously-skip-permissions` does **not**
  silence it; hooks run regardless of the permission system.)

### B. Commit-gate (free editing, gate at commit)

Edit + stop guards **off**; the pre-commit guard is the single gate and runs the
test suite. You work uninterrupted; a commit is rejected unless tests are staged
with prod **and** the suite passes.

- Set up (one command, run from the repo you want gated):

  ```bash
  ./hooks/install.sh --commit-gate
  ```

  This removes the edit/stop entries from `~/.claude/settings.json` (keeping any
  non-TDD hooks) and installs a pre-commit gate with `TDD_GUARD_RUN_TESTS=1`
  into that repo's `.git/hooks/`. Restart Claude Code so the removal takes
  effect. (Multi-workspace repo with no root manifest? Swap the installed
  pre-commit for the per-workspace wrapper below.)
- Trade-off: zero mid-work friction; the gate is later (commit time) and relies
  on the author following RED→GREEN, with the suite as the backstop.

## Quick start — edit guard + stop guard

Run from the repo root:

```bash
./hooks/install.sh
```

This symlinks all hook scripts into `~/.claude/hooks/` and registers the edit
guard and stop guard in `~/.claude/settings.json`. Restart Claude Code after
installing.

To uninstall:

```bash
./hooks/install.sh --uninstall
```

## Pre-commit guard (per-repo, opt-in)

The pre-commit guard is the strictest tier. It lives in each consuming repo's
`.git/hooks/pre-commit` and applies to all commits (Claude or human).

### Install in a consuming repo

Option A — symlink (stays in sync with upstream):

```bash
ln -sf ~/.claude/hooks/pre-commit-tdd-guard.sh .git/hooks/pre-commit
```

Option B — copy (standalone, no dependency):

```bash
cp ~/.claude/hooks/pre-commit-tdd-guard.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Both options work because `install.sh` symlinks all three scripts into
`~/.claude/hooks/`, including `pre-commit-tdd-guard.sh`.

### Configuration

The pre-commit guard is controlled via environment variables. Set them in your
shell profile or per-invocation:

| Variable | Default | Effect |
|----------|---------|--------|
| `TDD_GUARD_RUN_TESTS` | `0` | Set to `1` to run the test suite before each commit |
| `TDD_GUARD_TEST_CMD` | auto-detect | Custom test command (e.g., `pytest -x -q`) |
| `TDD_GUARD_STRICT` | `0` | Set to `1` to require test:prod file ratio >= 1:1 |
| `TDD_GUARD_SKIP_DIRS` | (none) | Colon-separated dirs to exclude (e.g., `migrations:scripts`) |

Auto-detection checks for `pyproject.toml` (pytest), `package.json` (npm test),
`go.mod` (go test), or `Cargo.toml` (cargo test).

### Example: maximum strictness

```bash
export TDD_GUARD_RUN_TESTS=1
export TDD_GUARD_STRICT=1
export TDD_GUARD_TEST_CMD="python -m pytest --tb=short -q"
```

### Repos with multiple workspaces (no root manifest)

`TDD_GUARD_RUN_TESTS=1` auto-detects **one** test command from a root manifest.
A repo with several sub-workspaces (each its own `Cargo.toml`, no root one)
needs a thin wrapper that scopes `cargo test` to the changed workspace(s). Put
this in `.git/hooks/pre-commit` instead of a bare symlink:

```bash
#!/bin/bash
# Run the shared guard AND test each sub-workspace that has staged changes.
set -euo pipefail
ROOT=$(git rev-parse --show-toplevel)
CMD=""
for d in $(git diff --cached --name-only --diff-filter=ACM | cut -d/ -f1 | sort -u); do
  [[ -f "$ROOT/$d/Cargo.toml" ]] && \
    CMD="${CMD}cargo test --manifest-path \"$ROOT/$d/Cargo.toml\" && "
done
[[ -n "$CMD" ]] && export TDD_GUARD_RUN_TESTS=1 TDD_GUARD_TEST_CMD="${CMD}true"
exec "$HOME/.claude/hooks/pre-commit-tdd-guard.sh" "$@"
```

Bash 3.2-safe (no `mapfile`). Live example: the `CroftCommunity/experiments`
repo, where `croft-group/`, `iroh/`, etc. are separate workspaces.

## Emergency bypass

All three tiers have an escape hatch when you genuinely need it:

- **Edit guard**: Answer "yes" to the prompt to proceed
- **Stop guard**: Commit or revert production changes before stopping
- **Pre-commit guard**: `git commit --no-verify`

## How detection works

All three tiers use the same heuristic: if files matching "production code"
patterns changed, files matching "test code" patterns must also have changed.

**Production code** — files in `src/`, `lib/`, `app/`, `pkg/`, `cmd/`, or
`internal/` with extensions `.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.go`, `.rs`.

**Test code** — files in `tests/`, `test/`, `__tests__/`, or matching naming
conventions `_test.*`, `.test.*`, `.spec.*`, `test_*.py`, `conftest.py`.

**Rust inline tests (content-based)** — the path patterns above can't see Rust's
idiomatic unit-test location: an inline `#[cfg(test)] mod tests { … }` at the
bottom of the same `src/*.rs` file as the code it tests. So all three tiers also
look *inside* changed/staged `.rs` files: one containing `#[cfg(test)]` or
`#[test]` counts as a test change. Without this, a crate whose tests are inline
would trip "no tests changed" on every commit.

## Opting out per repo

Drop a `.notdd` file in any repo root to disable all three tiers for that repo:

```bash
touch .notdd
```

Add it to `.gitignore` if you do not want it tracked. All hook scripts check for
this file immediately after confirming they are in a git repo — zero overhead
when the file is absent.

## Limitations

- Does not verify that tests actually cover the production changes (that
  requires coverage tooling, not a hook)
- Does not distinguish "writing code to pass a test" from "writing code without
  a test" within a single edit — the debounce and working-tree check handle this
  at a coarser granularity
- Repos with non-standard source layouts may need `TDD_GUARD_SKIP_DIRS`

## Files

| File | Hook type | Scope |
|------|-----------|-------|
| `tdd-edit-guard.sh` | Claude Code PreToolUse (Edit\|Write) | Global |
| `tdd-stop-guard.sh` | Claude Code Stop | Global |
| `pre-commit-tdd-guard.sh` | git pre-commit | Per-repo |
| `install.sh` | Setup script (model A default; `--commit-gate` for model B; `--uninstall`) | One-time |
| `test-install.sh` | Sandboxed test for `install.sh` (temp HOME + temp repo) | Dev |
