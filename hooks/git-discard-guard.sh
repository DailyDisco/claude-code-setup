#!/usr/bin/env bash
# =============================================================================
# Git Discard Guard - PreToolUse Hook
# =============================================================================
# Blocks git commands that discard uncommitted working directory changes.
# Prevents accidental loss of work from broad checkout/restore/clean commands.
#
# Blocked commands:
#   git checkout -- .          (discard all unstaged changes)
#   git checkout .             (same)
#   git checkout -- <file>     (allowed - targeted is fine)
#   git restore .              (discard all changes)
#   git restore --staged .     (allowed - unstaging is safe)
#   git clean -f               (delete untracked files)
#   git stash drop             (warned)
#
# Exit codes:
#   0 = allow
#   2 = block
# =============================================================================
set -euo pipefail

TOOL_INPUT=""
if [[ ! -t 0 ]]; then
  TOOL_INPUT="$(cat)"
fi

command="$(echo "$TOOL_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[[ -z "$command" ]] && exit 0

block() {
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","reason":"$1"}}
EOF
  exit 2
}

# ── Block: git checkout that discards all changes ──
# "git checkout -- ." or "git checkout ." (with optional flags)
if echo "$command" | grep -qP 'git\s+checkout\s+.*--\s+\.\s*($|[;&|])'; then
  block "BLOCKED: 'git checkout -- .' discards ALL uncommitted changes. Use 'git checkout -- <specific-file>' instead."
fi
if echo "$command" | grep -qP 'git\s+checkout\s+\.\s*($|[;&|])'; then
  block "BLOCKED: 'git checkout .' discards ALL uncommitted changes. Use 'git checkout -- <specific-file>' instead."
fi

# ── Block: git restore that discards all changes ──
# "git restore ." but NOT "git restore --staged ."
if echo "$command" | grep -qP 'git\s+restore\s+\.\s*($|[;&|])' && ! echo "$command" | grep -qP 'git\s+restore\s+--staged'; then
  block "BLOCKED: 'git restore .' discards ALL uncommitted changes. Use 'git restore <specific-file>' instead."
fi

# ── Block: git clean -f (deletes untracked files) ──
if echo "$command" | grep -qP 'git\s+clean\s+-[a-zA-Z]*f'; then
  block "BLOCKED: 'git clean -f' permanently deletes untracked files. Review with 'git clean -n' first."
fi

# ── Block: git reset --hard (already in deny list, belt-and-suspenders) ──
if echo "$command" | grep -qP 'git\s+reset\s+--hard'; then
  block "BLOCKED: 'git reset --hard' discards all uncommitted changes and resets staging area."
fi

exit 0
