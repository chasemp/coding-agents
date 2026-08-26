#!/bin/bash
# destructive-git-guard.sh — PreToolUse(Bash) guard for git commands that DELETE
# uncommitted work.
#
# Why a hook and not a doc: the rule is in CLAUDE.md and agents still hit it, then
# report "I hit the exact trap CLAUDE.md warns about". Knowing a rule at session start
# does not stop a command typed twenty turns later; a check at the moment of the command
# does. This reads the ACTING layer (`git status --porcelain <path>`), not intent.
#
# Behavior: if the command is destructive AND the target actually has uncommitted
# content, emit a blocking message explaining what would be lost. Otherwise stay silent
# — a restore of a clean path is exactly what the command is for, and a guard that fires
# on safe uses teaches everyone to ignore it.
#
# Install: ./hooks/install.sh (registers PreToolUse|Bash). Opt out per repo with .notdd.

set -u

payload="$(cat)"
cmd="$(printf '%s' "$payload" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)"

[ -z "$cmd" ] && exit 0
case "$cmd" in *git*) : ;; *) exit 0 ;; esac

# Repo opt-out, matching the other guards.
[ -f .notdd ] && exit 0

# Which destructive form is this? Empty = not destructive.
kind=""
# NOTE the wildcards between `git` and the subcommand: flags legitimately sit there
# (`git -C <repo> checkout ...`, `git --git-dir=… restore …`). An earlier version matched
# the literal "git checkout" and so never classified the workspace's most common shape as
# destructive at all — it exited before any safety check ran (found 2026-08-26).
case "$cmd" in
  *git*checkout*" -- "*|*git*restore*)     kind="restore-from-HEAD" ;;
  *git*"reset --hard"*)                    kind="reset --hard" ;;
  *git*clean*-*f*)                         kind="clean -f" ;;
  *git*"stash drop"*|*git*"stash clear"*)  kind="stash drop/clear" ;;
esac
[ -z "$kind" ] && exit 0

# WHICH repo, and WHICH paths? A command is rarely run against the cwd in a workspace of
# nested repos — `git -C <repo> ...` and `cd <repo> && git ...` are the common shapes, and
# checking the cwd there inspects the wrong tree entirely (verified 2026-08-26: this guard
# missed `git -C forage checkout HEAD -- sw.js` run from the meta-repo root, because the
# meta-repo was clean and nested repos are gitignored). Read the repo the command names.
target="$(printf '%s' "$cmd" | python3 -c '
import re, shlex, sys
c = sys.stdin.read()
d = "."
m = re.search(r"(?:^|[;&|]\s*)cd\s+([^\s;&|]+)", c)
if m: d = m.group(1)
m = re.search(r"git\s+(?:-C|--git-dir=?)\s*([^\s]+)", c)
if m: d = m.group(1)
paths = ""
if " -- " in c:
    try: paths = " ".join(shlex.split(c.split(" -- ", 1)[1]))
    except ValueError: paths = c.split(" -- ", 1)[1]
print(d + "\t" + paths)' 2>/dev/null)"
repo_dir="${target%%$(printf '\t')*}"; paths="${target#*$(printf '\t')}"
[ -d "$repo_dir" ] || repo_dir="."

# Does that tree actually hold anything the command would destroy? Scope to the named
# paths when the command names them — a whole-tree check would block on unrelated dirt.
if [ -n "$paths" ]; then
  # shellcheck disable=SC2086
  dirty="$(git -C "$repo_dir" status --porcelain -- $paths 2>/dev/null | head -20)"
else
  dirty="$(git -C "$repo_dir" status --porcelain 2>/dev/null | head -20)"
fi
[ -z "$dirty" ] && exit 0   # nothing to lose — stay quiet

# stash drop/clear is about the stash list, not the tree.
if [ "$kind" = "stash drop/clear" ]; then
  entries="$(git -C "$repo_dir" stash list 2>/dev/null | wc -l | tr -d ' ')"
  [ "${entries:-0}" -eq 0 ] && exit 0
fi

count="$(printf '%s\n' "$dirty" | wc -l | tr -d ' ')"
cat >&2 <<EOF
BLOCKED — destructive git command with uncommitted work present.

  command: ${cmd}
  form:    ${kind}
  repo:    ${repo_dir}
  tree:    ${count} uncommitted path(s) in scope, e.g.
$(printf '%s\n' "$dirty" | head -5 | sed 's/^/           /')

Anything listed above exists ONLY in the working tree. This command deletes it —
it is a restore only for paths already committed.

Before re-running:
  1. git status --porcelain <the exact path>   # is YOUR target dirty?
  2. commit or stash the work you want to keep (note: 'stash push' resets the index
     to HEAD, so stash/checkout/drop restores HEAD, not your pre-change state)
  3. then re-run, scoped to the specific path

Already ran something like this? 'git fsck --unreachable' may still hold the blob.
Rule + why: coding-agents/CLAUDE.md, "Destructive git operations".
EOF
exit 2
