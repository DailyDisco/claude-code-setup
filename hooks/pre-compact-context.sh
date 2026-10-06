#!/bin/bash
# pre-compact-context.sh — PreCompact hook
# Re-injects critical context before conversation compaction discards it.
# Outputs key state so Claude retains it in the compacted summary.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
output=""

# 1. Current branch and recent work
branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [[ "$branch" != "unknown" ]]; then
    recent_commits=$(git -C "$PROJECT_DIR" log --oneline -5 2>/dev/null || echo "")
    dirty_files=$(git -C "$PROJECT_DIR" diff --name-only 2>/dev/null | head -10)
    staged_files=$(git -C "$PROJECT_DIR" diff --cached --name-only 2>/dev/null | head -10)

    output+="Context Preservation (pre-compaction)"
    output+=$'\n'"Branch: $branch"

    if [[ -n "$recent_commits" ]]; then
        output+=$'\n'"Recent commits:"
        while IFS= read -r line; do
            output+=$'\n'"  $line"
        done <<< "$recent_commits"
    fi

    if [[ -n "$dirty_files" ]]; then
        output+=$'\n'"Uncommitted changes:"
        while IFS= read -r line; do
            output+=$'\n'"  $line"
        done <<< "$dirty_files"
    fi

    if [[ -n "$staged_files" ]]; then
        output+=$'\n'"Staged files:"
        while IFS= read -r line; do
            output+=$'\n'"  $line"
        done <<< "$staged_files"
    fi
fi

# 2. Active project CLAUDE.md (key instructions that must survive)
if [[ -f "$PROJECT_DIR/.claude/CLAUDE.md" ]]; then
    # Extract first 20 lines as project summary
    project_summary=$(head -20 "$PROJECT_DIR/.claude/CLAUDE.md" 2>/dev/null || echo "")
    if [[ -n "$project_summary" ]]; then
        output+=$'\n\n'"Project CLAUDE.md (first 20 lines):"
        output+=$'\n'"$project_summary"
    fi
fi

# 3. Tech stack detection (so Claude doesn't re-discover)
stack=""
[[ -f "$PROJECT_DIR/package.json" ]] && stack+="Node/JS "
[[ -f "$PROJECT_DIR/tsconfig.json" ]] && stack+="TypeScript "
[[ -f "$PROJECT_DIR/go.mod" ]] && stack+="Go "
[[ -f "$PROJECT_DIR/Cargo.toml" ]] && stack+="Rust "
[[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/requirements.txt" ]] && stack+="Python "
[[ -f "$PROJECT_DIR/next.config.js" || -f "$PROJECT_DIR/next.config.mjs" || -f "$PROJECT_DIR/next.config.ts" ]] && stack+="Next.js "
[[ -f "$PROJECT_DIR/Dockerfile" ]] && stack+="Docker "
[[ -d "$PROJECT_DIR/prisma" ]] && stack+="Prisma "

if [[ -n "$stack" ]]; then
    output+=$'\n\n'"Detected stack: $stack"
fi

# 4. Changelog draft (what was done this session)
CHANGELOG="${HOME}/.claude/state/changelog-draft.md"
if [[ -f "$CHANGELOG" ]]; then
    today=$(date +"%Y-%m-%d")
    today_changes=$(sed -n "/^## $today/,/^## /p" "$CHANGELOG" 2>/dev/null | head -15)
    if [[ -n "$today_changes" ]]; then
        output+=$'\n\n'"Today's changes:"
        output+=$'\n'"$today_changes"
    fi
fi

# Only output if we have something meaningful
if [[ -n "$output" ]]; then
    echo "$output"
fi

exit 0
