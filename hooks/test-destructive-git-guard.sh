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
  local want="$1" desc="$2" cmd="$3" got
  got="$(cd "$TMP/ws" && printf '%s' "$cmd" |
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

echo "must ALLOW — no work at risk, or not destructive:"
check 0 "same repo, a path that is CLEAN"         'git -C child checkout HEAD -- other.txt'
check 0 "harmless command in a dirty repo"        'git -C child status'
check 0 "harmless diff in a dirty repo"           'git -C child diff'
check 0 "non-git command mentioning checkout"     'echo "git checkout HEAD -- x"'
clean
check 0 "destructive, but the tree is clean"      'git -C child checkout HEAD -- tracked.txt'
check 0 "reset --hard on a clean tree"            'git -C child reset --hard'

echo
if [ "$FAIL" -eq 0 ]; then echo "PASS: $PASS/$((PASS+FAIL))"; exit 0; fi
echo "FAIL: $FAIL of $((PASS+FAIL)) cases"; exit 1
