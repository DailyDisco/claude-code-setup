#!/bin/bash
# Context Budget Hook
# Event: SessionStart
# Purpose: Analyze project size and suggest context-efficient strategies

set -euo pipefail

PROJECT_DIR="${CLAUDE_WORKING_DIRECTORY:-$(pwd)}"

# Skip if not a code project
[[ ! -d "$PROJECT_DIR" ]] && exit 0

# Count source files by type
count_files() {
    local pattern="$1"
    find "$PROJECT_DIR" -type f -name "$pattern" 2>/dev/null | grep -v node_modules | grep -v vendor | grep -v .git | wc -l
}

ts_count=$(count_files "*.ts" && count_files "*.tsx" | paste -sd+ | bc 2>/dev/null || echo 0)
go_count=$(count_files "*.go")
py_count=$(count_files "*.py")
total=$((ts_count + go_count + py_count))

# Detect monorepo
is_monorepo=false
if [[ -d "$PROJECT_DIR/packages" ]] || [[ -d "$PROJECT_DIR/apps" ]] || [[ -f "$PROJECT_DIR/pnpm-workspace.yaml" ]] || [[ -f "$PROJECT_DIR/lerna.json" ]]; then
    is_monorepo=true
fi

# Output context hints based on size
if [[ $total -gt 1000 ]]; then
    echo ""
    echo "Large codebase detected ($total source files)"
    echo "Context tips:"
    echo "  - Use Task agents for exploration (they don't consume main context)"
    echo "  - Be specific with file paths rather than broad searches"
    echo "  - Consider working on one module/package at a time"
    if $is_monorepo; then
        echo "  - This is a monorepo - focus on specific packages"
    fi
elif [[ $total -gt 300 ]]; then
    echo ""
    echo "Medium codebase ($total source files)"
    if $is_monorepo; then
        echo "  - Monorepo detected - specify package when searching"
    fi
fi

# Check for existing CLAUDE.md with context hints
if [[ -f "$PROJECT_DIR/CLAUDE.md" ]] || [[ -f "$PROJECT_DIR/.claude/CLAUDE.md" ]]; then
    : # Project has instructions, good
elif [[ $total -gt 100 ]]; then
    echo "  - Consider adding CLAUDE.md with architecture overview"
fi

exit 0
