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
case "$cmd" in
  *"git checkout"*"--"*|*"git restore"*)   kind="restore-from-HEAD" ;;
  *"git reset --hard"*)                    kind="reset --hard" ;;
  *"git clean"*[!-]f*|*"git clean -f"*)    kind="clean -f" ;;
  *"git stash drop"*|*"git stash clear"*)  kind="stash drop/clear" ;;
esac
[ -z "$kind" ] && exit 0

# Does the working tree actually hold anything the command would destroy?
dirty="$(git status --porcelain 2>/dev/null | head -20)"
[ -z "$dirty" ] && exit 0   # nothing to lose — stay quiet

# stash drop/clear is about the stash list, not the tree.
if [ "$kind" = "stash drop/clear" ]; then
  entries="$(git stash list 2>/dev/null | wc -l | tr -d ' ')"
  [ "${entries:-0}" -eq 0 ] && exit 0
fi

count="$(printf '%s\n' "$dirty" | wc -l | tr -d ' ')"
cat >&2 <<EOF
BLOCKED — destructive git command with uncommitted work present.

  command: ${cmd}
  form:    ${kind}
  tree:    ${count} uncommitted path(s), e.g.
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
