#!/bin/bash
# =============================================================================
# Breaking Change Detection Hook
# =============================================================================
# Event: PostToolUse (Edit|Write on API/schema files)
# Purpose: Warns about potential breaking changes in API surfaces
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only check Edit and Write operations
[[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]] && exit 0
[[ -z "$file_path" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Normalize file path
if [[ "$file_path" != /* ]]; then
    file_path="$PROJECT_DIR/$file_path"
fi

# Get relative path for pattern matching
rel_path="${file_path#$PROJECT_DIR/}"

# =============================================================================
# Detect Breaking Change Patterns
# =============================================================================

warnings=""

# API Route Files
if echo "$rel_path" | grep -qE '(api|routes|endpoints)/.*\.(ts|js|go|py)$'; then
    warnings+="API route file modified: $rel_path\n"
    warnings+="  → Verify backward compatibility\n"
    warnings+="  → Check if clients depend on removed/renamed endpoints\n"
fi

# OpenAPI/Swagger specs
if echo "$rel_path" | grep -qiE '(openapi|swagger)\.(yaml|yml|json)$'; then
    warnings+="OpenAPI spec modified: $rel_path\n"
    warnings+="  → Verify no required fields removed\n"
    warnings+="  → Check response schema changes\n"
    warnings+="  → Update API version if breaking\n"
fi

# GraphQL schemas
if echo "$rel_path" | grep -qE '\.graphql$|schema\.(ts|js)$'; then
    warnings+="GraphQL schema modified: $rel_path\n"
    warnings+="  → Check for removed fields (breaking)\n"
    warnings+="  → Deprecate before removing\n"
    warnings+="  → Verify resolver compatibility\n"
fi

# TypeScript type definitions (public API)
if echo "$rel_path" | grep -qE '(types|interfaces|models)/.*\.ts$|\.d\.ts$'; then
    warnings+="Type definitions modified: $rel_path\n"
    warnings+="  → Check if exported types changed\n"
    warnings+="  → Verify downstream consumers\n"
fi

# Database migrations
if echo "$rel_path" | grep -qiE 'migrations?/.*\.(sql|ts|js)$'; then
    warnings+="Database migration added/modified: $rel_path\n"
    warnings+="  → Verify migration is backward compatible\n"
    warnings+="  → Check for column removals or renames\n"
    warnings+="  → Test rollback procedure\n"
fi

# Protobuf definitions
if echo "$rel_path" | grep -qE '\.proto$'; then
    warnings+="Protobuf definition modified: $rel_path\n"
    warnings+="  → Never change field numbers\n"
    warnings+="  → Only add fields, don't remove\n"
    warnings+="  → Regenerate client code\n"
fi

# Package exports (package.json exports field)
if echo "$rel_path" | grep -qE 'package\.json$'; then
    # Check if exports field was modified
    if [[ -f "$file_path" ]] && git diff --cached -- "$file_path" 2>/dev/null | grep -qE '^\+.*"exports"'; then
        warnings+="Package exports modified: $rel_path\n"
        warnings+="  → Check for removed entry points\n"
        warnings+="  → Verify import paths still work\n"
    fi
fi

# Go interface changes
if echo "$rel_path" | grep -qE '\.go$'; then
    if git diff --cached -- "$file_path" 2>/dev/null | grep -qE '^-.*type.*interface'; then
        warnings+="Go interface modified: $rel_path\n"
        warnings+="  → Adding methods breaks implementers\n"
        warnings+="  → Consider interface segregation\n"
    fi
fi

# =============================================================================
# Output warnings if any
# =============================================================================

if [[ -n "$warnings" ]]; then
    echo ""
    echo "⚠️  POTENTIAL BREAKING CHANGE DETECTED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$warnings"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "This is a warning only. Proceeding with change."
    echo ""
fi

# Always exit 0 - this is advisory, not blocking
exit 0
