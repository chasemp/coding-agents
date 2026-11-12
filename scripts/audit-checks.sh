#!/usr/bin/env bash
# The shell commands behind /audit (commands/audit.md), one subcommand per check.
#
# Claude Code refuses a `!` line in a command file that uses a shell variable,
# so each such check lives here and commands/audit.md calls
# `bash scripts/audit-checks.sh <name>`. Commands are moved verbatim; run from
# the repo root. Tested by scripts/test-audit-checks.sh.

case "${1:-}" in
  claude-size)
    wc -l CLAUDE.md | awk '{print $1 " lines (budget: 200)"}' ;;
  skill-sizes)
    for f in skills/*.md; do lines=$(wc -l < "$f"); echo "$lines $f"; done | sort -rn ;;
  agent-sizes)
    for f in *.md; do case "$f" in CLAUDE.md|README.md|agents.md|LICENSE|RTK.md|REFINEMENTS.md|EXTERNAL-LEARNINGS.md) continue;; esac; lines=$(wc -l < "$f"); echo "$lines $f"; done | sort -rn ;;
  phase-plan-sizes)
    for f in skills/phase-plan/*.md; do lines=$(wc -l < "$f"); echo "$lines $f"; done 2>/dev/null | sort -rn ;;
  skill-refs)
    grep -rhoE '(\.claude/)?skills/[a-zA-Z0-9_-]+(/[a-zA-Z0-9_-]+)?\.md' skills/ commands/ *.md 2>/dev/null | grep -vE '^\.claude/|(^|/)X\.md$|/X/|/some-[a-zA-Z0-9_-]+\.md$|<' | sort -u ;;
  command-refs)
    grep -rhoE '(\.claude/)?commands/[a-zA-Z0-9_-]+\.md' skills/ commands/ *.md 2>/dev/null | grep -vE '^\.claude/|(^|/)X\.md$|/some-[a-zA-Z0-9_-]+\.md$|<' | sort -u ;;
  skill-frontmatter)
    for f in skills/*.md; do head -10 "$f" | grep -q '^name:' || echo "MISSING name: $f"; head -10 "$f" | grep -q '^description:' || echo "MISSING description: $f"; done ;;
  agent-frontmatter)
    for f in *.md; do case "$f" in CLAUDE.md|README.md|agents.md|LICENSE|RTK.md|REFINEMENTS.md|EXTERNAL-LEARNINGS.md) continue;; esac; head -60 "$f" | grep -q '^tools:' || continue; for field in name description tools model maxTurns; do head -60 "$f" | grep -q "^$field:" || echo "MISSING $field: $f"; done; done ;;
  command-frontmatter)
    for f in commands/*.md; do head -10 "$f" | grep -q '^description:' || echo "MISSING description: $f"; done ;;
  colors)
    grep -l '^color:' *.md 2>/dev/null | while read f; do color=$(grep '^color:' "$f" | head -1 | awk '{print $2}'); echo "$color $f"; done | sort ;;
  orphans)
    for f in *.md; do case "$f" in CLAUDE.md|README.md|agents.md|LICENSE|RTK.md|REFINEMENTS.md|EXTERNAL-LEARNINGS.md) continue;; esac; head -60 "$f" | grep -q '^tools:' || echo "ORPHAN: $f (no tools: field in first 60 lines, not on docs whitelist)"; done ;;
  plan-reasoning)
    for f in plans/*.md; do grep -qiE '^#{1,4} (problem|reasoning|rationale|why this|source summary|context|decision|approach)' "$f" || echo "MISSING reasoning marker: $f"; done 2>/dev/null ;;
  *)
    echo "usage: bash scripts/audit-checks.sh <claude-size|skill-sizes|agent-sizes|phase-plan-sizes|skill-refs|command-refs|skill-frontmatter|agent-frontmatter|command-frontmatter|colors|orphans|plan-reasoning>" >&2
    exit 2 ;;
esac
