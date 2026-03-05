---
description: Create a pull request following standards
allowed-tools: Bash(git:*), Bash(gh:*)
---

Current branch state:
!`git log main..HEAD --oneline`

Changes summary:
!`git diff main...HEAD --stat`

Create a PR with:

## Summary
- 1-3 bullet points describing the changes
- Focus on WHAT changed and WHY

Note: No test plan section needed - TDD means tests are already written and passing.

Use `gh pr create` with appropriate title and body.

## After PR Creation: CodeRabbit Review

After creating the PR, wait ~2 minutes for CodeRabbit to review, then address feedback:

1. **Fetch CodeRabbit review:**
   ```bash
   gh pr view <pr-number> --json reviews --jq '.reviews[] | select(.author.login == "coderabbitai")'
   ```

2. **Categorize issues:**
   - **Critical**: Import issues, config validation, security concerns → MUST FIX
   - **Important**: Error handling, type safety, defensive coding → SHOULD FIX
   - **Nitpick**: Style issues, redundant code, documentation → CAN DEFER

3. **Address critical and important issues:**
   - Fix the code
   - Commit and push to PR branch

4. **REQUIRED: Post response comment:**
   ```bash
   gh pr comment <pr-number> --body "## CodeRabbit Review - Response

   ### ✅ Addressed
   - Issue 1: Description of fix
   - Issue 2: Description of fix

   ### ⏭️ Deferred (Lower Priority)
   - Issue 3: Reason for deferring
   - Issue 4: Reason for deferring

   All critical issues affecting functionality have been resolved."
   ```

This keeps PR threads clean and documents decisions for human reviewers.

## PR Independence vs Stacking

**Default Approach: Independent PRs**

By default, ALL PRs should be based on `origin/main` (remote main) and should be independent of each other:

```bash
git fetch origin
git checkout -b pr/N-feature-name origin/main
# ... make changes, commit ...
gh pr create  # Will automatically use main as base
```

**CRITICAL:** Always branch from `origin/main`, NOT local `main`:
- Local `main` may be ahead of remote with unmerged commits from other PRs
- Branching from local `main` will include those unmerged commits in your PR
- This creates false dependencies and bloated PRs with dozens of extra files
- Always use `origin/main` to ensure a clean base

**Benefits of Independent PRs:**
- Can be reviewed and merged in any order
- No merge order dependencies
- Easier to revert individual changes
- Cleaner git history
- No cascade effects if one PR needs changes

**When Stacking IS Appropriate:**

Only stack PRs (base on another PR branch) when there is a TRUE CODE DEPENDENCY:

✅ **Good reasons to stack:**
- PR B literally imports and uses code from PR A
- PR B extends a class/function that only exists in PR A
- PR B tests integration between features in PR A and new code
- PR B is a refactoring that must happen after PR A's structural changes

❌ **Bad reasons to stack:**
- PRs are "related" conceptually but use independent APIs
- PRs work on the same general feature area but don't share code
- You're implementing multiple features sequentially
- PRs could theoretically be merged independently without conflicts

**Example from this project:**
- PR #7 (list violations) and PR #8 (bulk ignore) both work with violations
- BUT: They use independent API endpoints (`/violations` vs `/bulk-ignore`)
- Result: Should be independent PRs based on main
- Each can be merged, tested, and reverted independently

**When you must stack:**
```bash
git checkout pr/A-first-feature
git checkout -b pr/B-dependent-feature
# ... make changes ...
gh pr create --base pr/A-first-feature
```

**General Rule:** If you're unsure whether to stack, default to independent PRs. Independence is almost always better.
