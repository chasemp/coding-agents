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
#
# PRECISION IS A SAFETY PROPERTY HERE, not a nicety. v3 globbed the whole command string and so
# blocked an agent four times in one session for writing ABOUT a destructive command — prose in a
# heredoc body or a commit message matched as readily as an invocation. Within two blocks the agent
# had learned to route around the guard by writing its commit messages to a file. A false positive
# on a safety mechanism does not just annoy; it teaches evasion, which is strictly worse than no
# mechanism. Every change to the classifier belongs in hooks/test-destructive-git-guard.sh first.

set -u

payload="$(cat)"
cmd="$(printf '%s' "$payload" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)"

[ -z "$cmd" ] && exit 0
case "$cmd" in *git*) : ;; *) exit 0 ;; esac

# Repo opt-out, matching the other guards.
[ -f .notdd ] && exit 0

# CLASSIFY THE TEXT THAT WILL EXECUTE — NOT THE TEXT THAT WILL BE WRITTEN DOWN.
#
# v3 globbed the whole command string, so an agent was blocked four times in one session for
# writing ABOUT a destructive command: prose in a heredoc body or a commit message matched as
# readily as an invocation. `*git*clean*-*f*` needed only "clean" somewhere after "git", then any
# hyphen, then any "f" — which ordinary English satisfies. The agent then learned to route around
# the guard by writing messages to a file, which is the failure this header warns about: a guard
# that fires on safe uses teaches everyone to ignore it. (udm, 2026-08-27.)
#
# So the reduction below removes what cannot execute, and ONLY that:
#   - heredoc bodies, UNLESS the receiving command is a shell — `bash <<EOF ... EOF` really does
#     run its body, and discarding it wholesale would silently regress a case this guard already
#     catches. Verified before changing anything.
#   - quoted strings, UNLESS the segment's command is a shell — `sh -c "git checkout -- f"` runs
#     what is inside the quotes. (v3 missed that one entirely.)
# Then each `&&`/`||`/`;`/`|`/newline segment is classified on its own, so a `git` in one segment
# can no longer pair with a trigger word in another, and the destructive token must be the
# segment's own subcommand rather than a word that happens to appear downstream.
classify="$(printf '%s' "$cmd" | python3 -c '
import re, shlex, sys

SHELLS   = {"sh", "bash", "zsh", "dash", "ash", "ksh", "eval"}
WRAPPERS = {"command", "env", "sudo", "time", "nice", "nohup", "exec", "xargs", "\\\\git"}
SPLIT    = re.compile(r"\|\||&&|[;|\n]")   # heredoc-header scan only; real splitting is quote-aware

def segments(text):
    """Split on && || ; | and newline, but NEVER inside quotes.
    A `;` inside a commit message is punctuation, not a separator — splitting first and
    unquoting second tore the message apart and left the tail looking like its own git
    invocation. Found by probing the real shapes after the first version of this fix."""
    out, cur, quote, i, n = [], "", None, 0, len(text)
    while i < n:
        c = text[i]
        if quote:
            cur += c
            if c == quote:
                quote = None
        elif c in "\x27\"":
            quote = c
            cur += c
        elif c in ";|&\n":
            if c in "|&" and i + 1 < n and text[i + 1] == c:
                i += 1
            out.append(cur)
            cur = ""
        else:
            cur += c
        i += 1
    out.append(cur)
    return out

def lead(text):
    """The command a segment actually runs, past any wrappers and VAR=val prefixes."""
    toks = text.strip().split()
    while toks and (toks[0] in WRAPPERS or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*=.*", toks[0])):
        toks = toks[1:]
    return toks[0].lstrip("\\\\") if toks else ""

def strip_heredocs(c):
    """Drop heredoc bodies. Heredocs are line-oriented, so this is a line walk, not a regex."""
    lines, out, i = c.split("\n"), [], 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = re.search(r"<<-?\s*[\x27\"]?([A-Za-z_][A-Za-z0-9_]*)[\x27\"]?", line)
        if m:
            delim = m.group(1)
            keep = lead(SPLIT.split(line[:m.start()])[-1]) in SHELLS
            i += 1
            while i < len(lines) and lines[i].strip() != delim:
                if keep:
                    out.append(lines[i])
                i += 1
            if i < len(lines):
                out.append(lines[i])
        i += 1
    return "\n".join(out)

def unquote(text):
    """Remove quoted runs. A commit message is data; so is an echoed sentence."""
    return re.sub(r"\x27[^\x27]*\x27|\"[^\"]*\"", " ", text)

FORMS = [
    ("restore-from-HEAD", (r"\bcheckout\b", r"\s--\s")),
    ("restore-from-HEAD", (r"\brestore\b",)),
    ("reset --hard",      (r"\breset\b", r"--hard\b")),
    ("clean -f",          (r"\bclean\b", r"(?:\s-[A-Za-z]*f|--force\b)")),
    ("stash drop/clear",  (r"\bstash\s+(?:drop|clear)\b",)),
]

raw = sys.stdin.read()
for seg in segments(strip_heredocs(raw)):
    text = seg if lead(seg) in SHELLS else unquote(seg)
    # The segment must itself be a git invocation. `echo git checkout -- x` is not one.
    if lead(text) != "git" and lead(seg) not in SHELLS:
        continue
    if not re.search(r"\bgit\b", text):
        continue
    for kind, pats in FORMS:
        if all(re.search(pat, text) for pat in pats):
            print(kind)
            sys.exit(0)
print("")' 2>/dev/null)"
kind="$classify"
[ -z "$kind" ] && exit 0

# WHICH repo, and WHICH paths? A command is rarely run against the cwd in a workspace of
# nested repos — `git -C <repo> ...` and `cd <repo> && git ...` are the common shapes, and
# checking the cwd there inspects the wrong tree entirely (verified 2026-08-26: this guard
# missed `git -C forage checkout HEAD -- sw.js` run from the meta-repo root, because the
# meta-repo was clean and nested repos are gitignored). Read the repo the command names.
target="$(printf '%s' "$cmd" | python3 -c '
import os, re, shlex, sys
c = sys.stdin.read()

# RESOLVE THE TARGET THE WAY THE SHELL WILL, NOT AS TYPED. Live-fired 2026-09-14:
# `S=/abs/path; ... git -C "$S" checkout HEAD -- f` against a dirty tree was classified
# correctly and then allowed, because the target read as the literal characters `"$S"`,
# no such directory existed, and the check fell back to the (clean) cwd. Shell state does
# not persist between an agent'"'"'s Bash calls, so assign-then-use inside one command is
# the dominant shape for any path an agent computes. Same-command assignments are applied
# left to right, then the environment, `~`, and surrounding quotes.
env = dict(os.environ)
def expand(s):
    s = re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)",
               lambda m: env.get(m.group(1) or m.group(2), ""), s)
    if len(s) >= 2 and s[0] in "\x27\"" and s[-1] == s[0]:
        s = s[1:-1]
    return os.path.expanduser(s)
for m in re.finditer(r"(?:^|[;&|\n]\s*)(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(\"[^\"]*\"|\x27[^\x27]*\x27|[^\s;&|]*)", c):
    env[m.group(1)] = expand(m.group(2))

d = "."
m = re.search(r"(?:^|[;&|]\s*)cd\s+(\"[^\"]*\"|\x27[^\x27]*\x27|[^\s;&|]+)", c)
if m: d = expand(m.group(1))
m = re.search(r"git\s+(?:-C|--git-dir=?)\s*(\"[^\"]*\"|\x27[^\x27]*\x27|[^\s]+)", c)
if m: d = expand(m.group(1))
paths = ""
if " -- " in c:
    tail = c.split(" -- ", 1)[1]
    # FAIL CLOSED. v3 did `except ValueError: paths = <raw>`, which turned an unparseable list
    # into a bogus path — `git status --porcelain -- <bogus>` comes back empty and the guard
    # exits 0, allowing the delete. An unparseable path list must widen to the whole tree, never
    # narrow to nothing. (udm, 2026-08-27: the more dangerous half of the same bug.)
    try: paths = " ".join(expand(p) for p in shlex.split(tail))
    except ValueError: paths = ""
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
