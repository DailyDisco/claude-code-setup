#!/usr/bin/env bash
# =============================================================================
# Commit Size Warning Hook
# =============================================================================
# Event: PreToolUse (Bash - git commit)
# Purpose: Warn about large commits that should be split
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only run for git commit
[[ "$tool_name" != "Bash" ]] && exit 0
echo "$command" | grep -qE 'git\s+commit' || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Configuration (could be read from settings)
MAX_LINES_WARNING=500
MAX_LINES_BLOCK=2000
MAX_FILES_WARNING=20
MAX_FILES_BLOCK=50

# Get staged changes stats
STATS=$(git diff --cached --stat 2>/dev/null | tail -1 || echo "0 files changed")

# Parse stats
FILES_CHANGED=$(echo "$STATS" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo "0")
INSERTIONS=$(echo "$STATS" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
DELETIONS=$(echo "$STATS" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")

TOTAL_LINES=$((INSERTIONS + DELETIONS))

# Get staged files for analysis
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)

# Check for specific patterns that warrant warnings
large_files=()
generated_files=()
test_files=()

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Count lines changed in this file
    file_changes=$(git diff --cached --numstat "$file" 2>/dev/null | awk '{print $1 + $2}' || echo "0")

    # Large single file
    if [[ "$file_changes" -gt 300 ]]; then
        large_files+=("$file (+$file_changes)")
    fi

    # Generated files
    if [[ "$file" =~ (\.generated\.|\.min\.|package-lock\.json|yarn\.lock|pnpm-lock\.yaml|go\.sum) ]]; then
        generated_files+=("$file")
    fi

    # Test files
    if [[ "$file" =~ (test|spec|_test\.go|\.test\.) ]]; then
        test_files+=("$file")
    fi
done <<< "$STAGED_FILES"

# =============================================================================
# Output warnings
# =============================================================================
warnings=()

# Check total lines
if [[ "$TOTAL_LINES" -gt "$MAX_LINES_BLOCK" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚫 Commit Too Large (BLOCKING)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This commit has $TOTAL_LINES lines changed across $FILES_CHANGED files."
    echo "Maximum allowed: $MAX_LINES_BLOCK lines"
    echo ""
    echo "Large commits are hard to review and increase merge conflict risk."
    echo ""
    echo "Suggestions:"
    echo "  1. Split into multiple focused commits"
    echo "  2. Separate refactoring from feature changes"
    echo "  3. Commit tests separately from implementation"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 2
elif [[ "$TOTAL_LINES" -gt "$MAX_LINES_WARNING" ]]; then
    warnings+=("📏 Large commit: $TOTAL_LINES lines changed (recommend <$MAX_LINES_WARNING)")
fi

# Check file count
if [[ "$FILES_CHANGED" -gt "$MAX_FILES_BLOCK" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚫 Too Many Files Changed (BLOCKING)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This commit touches $FILES_CHANGED files."
    echo "Maximum allowed: $MAX_FILES_BLOCK files"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 2
elif [[ "$FILES_CHANGED" -gt "$MAX_FILES_WARNING" ]]; then
    warnings+=("📁 Many files: $FILES_CHANGED files changed (recommend <$MAX_FILES_WARNING)")
fi

# Large individual files
if [[ ${#large_files[@]} -gt 0 ]]; then
    warnings+=("📄 Large file changes:")
    for f in "${large_files[@]}"; do
        warnings+=("   - $f")
    done
fi

# Generated files warning
if [[ ${#generated_files[@]} -gt 0 ]]; then
    warnings+=("🔧 Generated/lock files included (verify these are intentional):")
    for f in "${generated_files[@]}"; do
        warnings+=("   - $f")
    done
fi

# Mixed commit warning
if [[ ${#test_files[@]} -gt 0 ]] && [[ ${#test_files[@]} -lt "$FILES_CHANGED" ]]; then
    test_ratio=$(( ${#test_files[@]} * 100 / FILES_CHANGED ))
    if [[ "$test_ratio" -lt 30 ]] && [[ "$TOTAL_LINES" -gt 200 ]]; then
        warnings+=("🧪 Low test coverage in commit: ${#test_files[@]}/$FILES_CHANGED files are tests")
    fi
fi

# Output warnings (non-blocking)
if [[ ${#warnings[@]} -gt 0 ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  Commit Size Warnings"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for warning in "${warnings[@]}"; do
        echo "$warning"
    done
    echo ""
    echo "Stats: $FILES_CHANGED files | +$INSERTIONS -$DELETIONS lines"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

exit 0
