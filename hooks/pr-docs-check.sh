#!/bin/bash
# pr-docs-check.sh — PreToolUse hook for Bash(gh pr:*)
# Checks if significant code changes lack corresponding doc updates.
# Outputs a reminder if README, CLAUDE.md, or docs/ are stale.

set -euo pipefail

input=$(cat)
TOOL_INPUT=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Only trigger on pr create commands
if ! echo "$TOOL_INPUT" | grep -qE 'gh pr create|gh pr ready'; then
    exit 0
fi

# Determine base branch
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Get changed files vs base
CHANGED_FILES=$(git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null || git diff --name-only HEAD~5 2>/dev/null || echo "")

if [[ -z "$CHANGED_FILES" ]]; then
    exit 0
fi

# Count code vs doc changes
CODE_CHANGES=$(echo "$CHANGED_FILES" | grep -cE '\.(ts|tsx|js|jsx|go|py|rs|swift|gd)$' || echo "0")
DOC_CHANGES=$(echo "$CHANGED_FILES" | grep -ciE '(readme|changelog|\.md$|docs/|\.claude/)' || echo "0")

# Check for specific high-impact changes
API_CHANGES=$(echo "$CHANGED_FILES" | grep -ciE '(api/|routes|handler|controller|endpoint|openapi|swagger)' || echo "0")
SCHEMA_CHANGES=$(echo "$CHANGED_FILES" | grep -ciE '(migration|schema|\.sql|prisma/|models/)' || echo "0")
CONFIG_CHANGES=$(echo "$CHANGED_FILES" | grep -ciE '(docker|compose|caddy|nginx|\.env\.example|package\.json|go\.mod)' || echo "0")
NEW_FILES=$(git diff --diff-filter=A --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null | wc -l || echo "0")

# Check for project-level CLAUDE.md
HAS_PROJECT_CLAUDE=false
if [[ -f ".claude/CLAUDE.md" ]]; then
    HAS_PROJECT_CLAUDE=true
fi

# Build reminder if docs seem stale
WARNINGS=()

if (( CODE_CHANGES > 5 && DOC_CHANGES == 0 )); then
    WARNINGS+=("${CODE_CHANGES} code files changed but no documentation updated")
fi

if (( API_CHANGES > 0 )); then
    API_DOCS_UPDATED=$(echo "$CHANGED_FILES" | grep -ciE '(api.*\.md|openapi|swagger|docs.*api)' || echo "0")
    if (( API_DOCS_UPDATED == 0 )); then
        WARNINGS+=("API routes/handlers changed — consider updating API docs")
    fi
fi

if (( SCHEMA_CHANGES > 0 )); then
    WARNINGS+=("Database schema/migrations changed — consider documenting in README or CLAUDE.md")
fi

if (( CONFIG_CHANGES > 0 )); then
    WARNINGS+=("Config/infra files changed — verify README setup instructions are current")
fi

if (( NEW_FILES > 3 )); then
    WARNINGS+=("${NEW_FILES} new files added — consider updating project structure docs")
fi

# Check if README exists and was last updated a while ago
if [[ -f "README.md" ]]; then
    README_IN_DIFF=$(echo "$CHANGED_FILES" | grep -c "^README.md$" || echo "0")
    if (( README_IN_DIFF == 0 && CODE_CHANGES > 3 )); then
        WARNINGS+=("README.md not updated in this branch")
    fi
fi

# Check project CLAUDE.md staleness
if [[ "$HAS_PROJECT_CLAUDE" == true ]]; then
    CLAUDE_IN_DIFF=$(echo "$CHANGED_FILES" | grep -c "^\.claude/CLAUDE\.md$" || echo "0")
    if (( CLAUDE_IN_DIFF == 0 && CODE_CHANGES > 5 )); then
        WARNINGS+=(".claude/CLAUDE.md not updated — may need refresh for new patterns/structure")
    fi
fi

# Output warnings if any
if (( ${#WARNINGS[@]} > 0 )); then
    echo "Documentation Review Reminder"
    echo "Before creating this PR, consider updating docs:"
    for w in "${WARNINGS[@]}"; do
        echo "  - $w"
    done
    echo ""
    echo "Files to check: README.md, .claude/CLAUDE.md, docs/"
    echo "If docs are already current, proceed with the PR."
fi

exit 0
