#!/bin/bash
# Persist Learnings Hook
# Event: Stop (after main Stop hook)
# Purpose: Extract learnings from Claude's response and persist to project memory

set -euo pipefail

# The response JSON is passed via environment or stdin
response="${CLAUDE_RESPONSE:-}"

# If no response in env, try reading from the hook context
if [[ -z "$response" ]]; then
    exit 0
fi

# Check if jq is available
command -v jq &>/dev/null || exit 0

# Extract learnings array from response
learnings=$(echo "$response" | jq -r '.learnings[]? // empty' 2>/dev/null || true)

# Skip if no learnings
[[ -z "$learnings" ]] && exit 0

# Persist each learning to project memory
MEMORY_SCRIPT="${HOME}/.claude/hooks/project-memory.sh"

if [[ -x "$MEMORY_SCRIPT" ]]; then
    while IFS= read -r learning; do
        [[ -n "$learning" ]] && bash "$MEMORY_SCRIPT" add-learning "$learning"
    done <<< "$learnings"

    # Log that learnings were persisted
    count=$(echo "$learnings" | wc -l)
    echo "Persisted $count learning(s) to project memory" >&2
fi

exit 0
