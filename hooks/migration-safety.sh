#!/bin/bash
# =============================================================================
# BONUS: Migration Safety Hook
# =============================================================================
# Event: PostToolUse (Write on migration files)
# Purpose: Ensures database migrations are safe and reversible
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
content=$(echo "$input" | jq -r '.tool_input.content // empty')

[[ "$tool_name" != "Write" ]] && exit 0

# Check if this is a migration file
if echo "$file_path" | grep -qiE '(migration|migrate)'; then
    echo "Database migration created: $file_path"
    echo ""
    echo "Migration safety checklist:"
    echo "  [ ] Reversible (has down/rollback)?"
    echo "  [ ] Safe for production (no table locks on large tables)?"
    echo "  [ ] Backward compatible with current code?"
    echo "  [ ] Data backfill strategy if needed?"
    echo "  [ ] Tested on copy of prod data?"
    echo ""

    # Check for dangerous operations
    if echo "$content" | grep -qiE '(DROP|TRUNCATE|DELETE FROM.*WHERE|ALTER.*DROP)'; then
        echo "WARNING: Destructive operation detected!"
        echo "  - Ensure backup exists"
        echo "  - Consider soft-delete instead"
    fi

    if echo "$content" | grep -qiE 'NOT NULL(?!.*DEFAULT)'; then
        echo "WARNING: Adding NOT NULL without DEFAULT"
        echo "  - May fail on existing rows"
        echo "  - Consider: ADD COLUMN ... DEFAULT ... then ALTER"
    fi
fi

exit 0
