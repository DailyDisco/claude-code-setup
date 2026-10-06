#!/bin/bash
# Stale Branch Warning Hook
# Event: SessionStart
# Purpose: Warn if current branch is significantly behind main/master
# Industry standard: Keep branches up-to-date to avoid merge conflicts

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Only run in git repositories
if [[ ! -d "$PROJECT_DIR/.git" ]]; then
    exit 0
fi

cd "$PROJECT_DIR"

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
[[ -z "$CURRENT_BRANCH" ]] && exit 0

# Skip if on main/master/develop (nothing to compare against)
case "$CURRENT_BRANCH" in
    main|master|develop|development)
        exit 0
        ;;
esac

# Determine the default branch
DEFAULT_BRANCH=""
if git show-ref --verify --quiet refs/heads/main; then
    DEFAULT_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
    DEFAULT_BRANCH="master"
elif git show-ref --verify --quiet refs/heads/develop; then
    DEFAULT_BRANCH="develop"
else
    exit 0
fi

# Fetch silently to get latest remote state (with timeout)
timeout 5 git fetch origin "$DEFAULT_BRANCH" --quiet 2>/dev/null || true

# Count commits behind
COMMITS_BEHIND=$(git rev-list --count "HEAD..origin/$DEFAULT_BRANCH" 2>/dev/null || echo "0")

# Thresholds
WARN_THRESHOLD=10
CRITICAL_THRESHOLD=50

# Strongest signal: the branch is already fully contained in the default branch
# (its PR has merged) yet the default branch has moved on. New work here builds on
# a dead, drifting base — the exact setup that causes stale-base conflict messes.
ALREADY_MERGED=0
if [[ "$COMMITS_BEHIND" -gt 0 ]] && git merge-base --is-ancestor HEAD "origin/$DEFAULT_BRANCH" 2>/dev/null; then
    ALREADY_MERGED=1
fi

if [[ "$ALREADY_MERGED" -eq 1 ]]; then
    echo ""
    echo "🛑 **Branch \`$CURRENT_BRANCH\` is already merged into \`$DEFAULT_BRANCH\`** (and $COMMITS_BEHIND commits behind)."
    echo "   New work here builds on a dead branch. Start fresh off the latest default branch:"
    echo "   \`git fetch origin && git switch -c <new-branch> origin/$DEFAULT_BRANCH\`"
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
        echo "   ⚠️  Uncommitted changes present — snapshot them first so the switch can't lose work:"
        echo "      \`git switch -c wip/snapshot && git add -A && git commit -m wip && git switch -\`"
    fi
    echo ""
elif [[ "$COMMITS_BEHIND" -ge "$CRITICAL_THRESHOLD" ]]; then
    echo ""
    echo "⚠️  **Branch significantly behind**: \`$CURRENT_BRANCH\` is $COMMITS_BEHIND commits behind \`$DEFAULT_BRANCH\`"
    echo "   Consider rebasing: \`git rebase origin/$DEFAULT_BRANCH\` or merging to avoid conflicts."
    echo ""
elif [[ "$COMMITS_BEHIND" -ge "$WARN_THRESHOLD" ]]; then
    echo ""
    echo "📌 Branch \`$CURRENT_BRANCH\` is $COMMITS_BEHIND commits behind \`$DEFAULT_BRANCH\`. Consider syncing soon."
    echo ""
fi

# Also check for stale branch (no commits in X days)
LAST_COMMIT_DATE=$(git log -1 --format=%ct 2>/dev/null || echo "0")
NOW=$(date +%s)
DAYS_STALE=$(( (NOW - LAST_COMMIT_DATE) / 86400 ))

if [[ "$DAYS_STALE" -ge 14 ]]; then
    echo "⏰ Branch \`$CURRENT_BRANCH\` has no commits in $DAYS_STALE days. Is this branch still active?"
fi

exit 0
