#!/bin/bash
# test-destructive-git-guard.sh — fixtures for the destructive-git guard.
#
# WHY THIS EXISTS: the guard shipped "validated" twice and was wrong both times, because
# the fixtures tested the shape I imagined instead of the shape agents actually type.
#   - v1 checked `git status` in the CWD, so `git -C <repo> checkout HEAD -- f` from a
#     parent directory inspected the wrong tree and allowed the delete.
#   - v2 matched the literal string "git checkout", so `git -C <repo> checkout` was never
#     classified as destructive at all — it exited before any safety check ran.
# Both are the dominant form in a workspace of nested repos. A guard that only handles the
# textbook invocation is not a guard.
#
# THE RULE THIS ENCODES: every case below is a command shape harvested from real
# transcripts or real repo layout — never invented. Add a case when you see a new shape in
# the wild, not when you think of one.
#
# Usage: bash hooks/test-destructive-git-guard.sh   (exit 0 = all pass)

set -u
GUARD="$(cd "$(dirname "$0")" && pwd)/destructive-git-guard.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0

# A nested-repo workspace: parent repo that ignores its children, like the real one.
mkdir -p "$TMP/ws/child"
git -C "$TMP/ws" init -q 2>/dev/null
printf 'child/\n' > "$TMP/ws/.gitignore"
git -C "$TMP/ws" add .gitignore && git -C "$TMP/ws" commit -qm init
git -C "$TMP/ws/child" init -q 2>/dev/null
printf 'committed\n' > "$TMP/ws/child/tracked.txt"
printf 'committed\n' > "$TMP/ws/child/other.txt"
git -C "$TMP/ws/child" add . && git -C "$TMP/ws/child" commit -qm init

dirty()  { printf 'UNCOMMITTED WORK\n' >> "$TMP/ws/child/tracked.txt"; }
clean()  { git -C "$TMP/ws/child" checkout -- tracked.txt 2>/dev/null; }

# want=2 means "must block", want=0 means "must stay out of the way"
check() {
  local want="$1" desc="$2" cmd="$3" wd="${4:-$TMP/ws}" got
  got="$(cd "$wd" && printf '%s' "$cmd" |
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.stdin.read()}}))' |
    bash "$GUARD" >/dev/null 2>&1; echo $?)"
  if [ "$got" = "$want" ]; then PASS=$((PASS+1)); printf '  ok    %s\n' "$desc"
  else FAIL=$((FAIL+1)); printf '  FAIL  %s (want %s, got %s)\n    cmd: %s\n' "$desc" "$want" "$got" "$cmd"; fi
}

echo "must BLOCK — real work at risk, in the shapes agents actually type:"
dirty
check 2 "git -C <repo> checkout HEAD -- <file>"   'git -C child checkout HEAD -- tracked.txt'
check 2 "git -C <repo> restore <file>"            'git -C child restore tracked.txt'
check 2 "cd <repo> && git checkout HEAD -- <file>" 'cd child && git checkout HEAD -- tracked.txt'
check 2 "git -C <repo> checkout -- <file>"        'git -C child checkout -- tracked.txt'
check 2 "git -C <repo> reset --hard"              'git -C child reset --hard'
check 2 "compound: build && git -C <repo> reset --hard" 'npm run build && git -C child reset --hard'
# The command that actually destroyed work (croftc-e2, 2026-08-26): the BARE form, run
# with the CWD already inside the right repo. Nothing about its shape or location marks
# it destructive — only the working-tree state at that instant does, which is why the
# guard must RUN the status check rather than pattern-match the invocation.
check 2 "bare form, CWD inside the repo, file dirty" 'git checkout HEAD -- tracked.txt' "$TMP/ws/child"

echo "must ALLOW — no work at risk, or not destructive:"
check 0 "same repo, a path that is CLEAN"         'git -C child checkout HEAD -- other.txt'
check 0 "harmless command in a dirty repo"        'git -C child status'
check 0 "harmless diff in a dirty repo"           'git -C child diff'
# NOTE (2026-08-27): this used to name `x`, a path that does not exist — so it passed because the
# status check found nothing, not because the guard recognised an `echo`. It now names the DIRTY
# file, which is the only version that tests the classifier rather than the filesystem.
check 0 "non-git command mentioning checkout"     'echo "git checkout HEAD -- tracked.txt"' "$TMP/ws/child"
clean
check 0 "destructive, but the tree is clean"      'git -C child checkout HEAD -- tracked.txt'
check 0 "reset --hard on a clean tree"            'git -C child reset --hard'
# Same command, same repo, same CWD as the blocking case above — benign purely because
# the tree is clean. This pair is the whole argument for a state check over a shape check.
check 0 "bare form, CWD inside the repo, file clean" 'git checkout HEAD -- tracked.txt' "$TMP/ws/child"


# ---- QUOTED DATA IS NOT A COMMAND (all harvested from udm, 2026-08-27) ----------------------
#
# Four sessions in a row, an agent was blocked for writing ABOUT a destructive command: the
# classifier globs the whole command string, so prose in a heredoc body or a commit message
# matches as readily as an invocation. The agent learned within two blocks to route around the
# guard by writing messages to a file — which is the failure this guard's own header warns
# about: "a guard that fires on safe uses teaches everyone to ignore it".
dirty
check 0 "python heredoc whose BODY mentions the phrase" 'python3 - <<EOF
# git checkout HEAD -- tracked.txt
EOF' "$TMP/ws/child"
check 0 "commit message quoting the phrase" 'git commit -m "explain why git checkout HEAD -- tracked.txt is unsafe"' "$TMP/ws/child"
check 0 "commit message body via -F, mentioning it" 'git commit -q -F msg.txt' "$TMP/ws/child"
# The `clean -f` glob is the loosest of the four: "clean" anywhere after "git", then ANY hyphen,
# then ANY "f". Ordinary prose satisfies it. This is the exact shape that blocked a commit.
check 0 "prose with clean + a hyphen + an f, downstream of a git token" 'git add -A && echo "cleanup save; three field-specific runs, 0 failures"' "$TMP/ws/child"

# ---- BUT A REAL COMMAND INSIDE A SHELL HEREDOC STILL EXECUTES --------------------------------
# So the body may only be discarded when the receiving command is NOT a shell. Stripping heredocs
# wholesale would fix the four cases above and silently regress this one, which the guard catches
# today. Verified 2026-08-27 before changing anything.
check 2 "bash heredoc whose body IS a destructive command" 'bash <<EOF
git checkout HEAD -- tracked.txt
EOF' "$TMP/ws/child"
check 2 "sh -c with a destructive command in the string" 'sh -c "git checkout HEAD -- tracked.txt"' "$TMP/ws/child"

# ---- FAIL CLOSED ON AN UNPARSEABLE PATH LIST ------------------------------------------------
# The dangerous direction. `except ValueError: paths = <raw>` turns an unparseable list into a
# bogus path; `git status --porcelain -- <bogus>` is empty; the guard exits 0 and the delete
# proceeds. An unparseable path list must widen to the whole tree, never narrow to nothing.
check 2 "unbalanced quote in the path list must not disarm the check" 'git checkout HEAD -- "tracked.txt' "$TMP/ws/child"

# A `;` inside a commit message is punctuation, not a separator. The first version of the v4 fix
# split into segments BEFORE stripping quotes, so this message tore apart and its tail looked like
# its own git invocation. Caught by probing the real shapes rather than by the fixtures — which is
# why it is a fixture now.
check 0 "commit message containing a semicolon before the phrase" 'git commit -m "the restore put it back wrong; git checkout HEAD -- tracked.txt"' "$TMP/ws/child"

# Wrapper prefixes agents actually type. `command git` is the workspace default (it bypasses the
# rtk rewrite hook), so a guard that misses it misses nearly everything.
check 2 "command-prefixed"                        'command git checkout HEAD -- tracked.txt' "$TMP/ws/child"
check 2 "env-prefixed"                            'env FOO=1 git checkout HEAD -- tracked.txt' "$TMP/ws/child"
check 2 "clean --force (long flag)"               'git clean --force' "$TMP/ws/child"

# stash drop/clear is about the STASH LIST, not the working tree — so it must stay quiet when there
# is nothing to drop, and fire when there is. Both halves, because only the pair proves the check.
check 0 "stash drop with an EMPTY stash list"     'git stash drop' "$TMP/ws/child"
git -C "$TMP/ws/child" stash push -q -m fixture >/dev/null 2>&1
dirty
check 2 "stash drop with a stash present"         'git stash drop' "$TMP/ws/child"
git -C "$TMP/ws/child" stash drop -q >/dev/null 2>&1

echo
if [ "$FAIL" -eq 0 ]; then echo "PASS: $PASS/$((PASS+FAIL))"; exit 0; fi
echo "FAIL: $FAIL of $((PASS+FAIL)) cases"; exit 1
