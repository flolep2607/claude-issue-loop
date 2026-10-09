#!/usr/bin/env bash
# Declare the issue-loop plugin in a repo's committed Claude Code settings, so
# anyone who opens it is offered the tooling. Idempotent — safe to re-run.
# Usage: add-issue-loop.sh [repo-dir]   (default: current directory)
set -euo pipefail

dir="${1:-.}"
f="$dir/.claude/settings.json"
mkdir -p "$dir/.claude"
[ -s "$f" ] || echo '{}' > "$f"

tmp=$(mktemp)
jq '
  .extraKnownMarketplaces["claude-issue-loop"] =
    { source: { source: "github", repo: "flolep2607/claude-issue-loop" } }
  | .enabledPlugins["issue-loop@claude-issue-loop"] = true
' "$f" > "$tmp" && mv "$tmp" "$f"

echo "issue-loop declared in $f — commit it, then run /issue-loop:setup in the repo."
