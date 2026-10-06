#!/bin/bash
# =============================================================================
# TIER 2: OpenAPI Sync Hook
# =============================================================================
# Event: PostToolUse (Edit|Write on API files)
# Purpose: Reminds to update OpenAPI spec when API routes change
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only check Edit and Write operations
[[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]] && exit 0

# Check if file looks like an API route file
api_patterns="(route|controller|handler|endpoint|api)"
if echo "$file_path" | grep -iqE "$api_patterns"; then
    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

    # Check if OpenAPI spec exists
    openapi_file=""
    for f in "openapi.yaml" "openapi.yml" "openapi.json" "api/openapi.yaml" "docs/openapi.yaml"; do
        if [[ -f "$PROJECT_DIR/$f" ]]; then
            openapi_file="$f"
            break
        fi
    done

    if [[ -n "$openapi_file" ]]; then
        echo "API file modified: $file_path"
        echo "Remember to update: $openapi_file"
        echo ""
        echo "Ensure:"
        echo "  - New endpoints documented"
        echo "  - Request/response schemas accurate"
        echo "  - Auth requirements specified"
        echo "  - Error responses defined"
    fi
fi

exit 0
