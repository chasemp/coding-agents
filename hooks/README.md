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
| `install.sh` | Setup script (symlinks + settings.json) | One-time |
