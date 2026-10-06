#!/bin/bash
# Uncommitted Changes Warning Hook
# Event: Stop
# Purpose: Remind user about uncommitted changes before ending session
# Industry standard: Never leave work uncommitted

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Only run in git repositories
if [[ ! -d "$PROJECT_DIR/.git" ]]; then
    exit 0
fi

cd "$PROJECT_DIR"

# Check for uncommitted changes
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l)
UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

TOTAL=$((STAGED + UNSTAGED + UNTRACKED))

if [[ "$TOTAL" -eq 0 ]]; then
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 **Uncommitted changes detected**"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$STAGED" -gt 0 ]]; then
    echo "   ✅ Staged:    $STAGED file(s) ready to commit"
fi

if [[ "$UNSTAGED" -gt 0 ]]; then
    echo "   📝 Modified:  $UNSTAGED file(s) with unsaved changes"
fi

if [[ "$UNTRACKED" -gt 0 ]]; then
    echo "   ❓ Untracked: $UNTRACKED new file(s)"
fi

echo ""

# Provide helpful commands
if [[ "$STAGED" -gt 0 ]]; then
    echo "   → Commit staged: \`git commit -m \"your message\"\`"
fi

if [[ "$UNSTAGED" -gt 0 || "$UNTRACKED" -gt 0 ]]; then
    echo "   → Stage all: \`git add -A\`"
    echo "   → Review changes: \`git diff\`"
fi

# Check if there's a meaningful amount of work
if [[ "$TOTAL" -ge 5 ]]; then
    echo ""
    echo "   💡 Consider committing before ending your session."
fi

# Show branch info for context
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
echo ""
echo "   Current branch: \`$BRANCH\`"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
