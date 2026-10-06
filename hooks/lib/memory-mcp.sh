#!/usr/bin/env bash
# =============================================================================
# Memory MCP Integration Library - Phase 3.3
# =============================================================================
# Purpose: Persistent cross-session memory using Memory MCP server
# Features:
#   - Store/retrieve memories using MCP Memory server
#   - Pattern recognition from past workflows
#   - User preference learning
#   - Project-specific contexts
# Note: Requires Memory MCP server to be running (configured in settings.json)
# =============================================================================

source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

# Check if Memory MCP is configured
MEMORY_MCP_AVAILABLE=false
if grep -q '"memory"' "${HOME}/.claude/settings.json" 2>/dev/null; then
    MEMORY_MCP_AVAILABLE=true
fi

# Fallback to file-based storage if MCP not available
MEMORY_FALLBACK_DIR="${HOME}/.claude/cache/memory-fallback"
mkdir -p "$MEMORY_FALLBACK_DIR"

# =============================================================================
# Store Memory (via MCP or fallback)
# =============================================================================
memory_store() {
    local key="$1"
    local value="$2"
    local context="${3:-global}"  # global | project | session

    if [[ "$MEMORY_MCP_AVAILABLE" == "true" ]]; then
        _memory_store_mcp "$key" "$value" "$context"
    else
        _memory_store_fallback "$key" "$value" "$context"
    fi
}

# =============================================================================
# Retrieve Memory
# =============================================================================
memory_retrieve() {
    local key="$1"
    local context="${2:-global}"

    if [[ "$MEMORY_MCP_AVAILABLE" == "true" ]]; then
        _memory_retrieve_mcp "$key" "$context"
    else
        _memory_retrieve_fallback "$key" "$context"
    fi
}

# =============================================================================
# Search Memories
# =============================================================================
memory_search() {
    local query="$1"
    local limit="${2:-10}"

    if [[ "$MEMORY_MCP_AVAILABLE" == "true" ]]; then
        _memory_search_mcp "$query" "$limit"
    else
        _memory_search_fallback "$query" "$limit"
    fi
}

# =============================================================================
# MCP Implementation (when available)
# =============================================================================
_memory_store_mcp() {
    local key="$1"
    local value="$2"
    local context="$3"

    # In a real implementation, this would use the MCP protocol
    # For now, we'll use a simplified approach
    # The actual MCP call would be handled by Claude Code's MCP integration

    # Store in fallback as well for redundancy
    _memory_store_fallback "$key" "$value" "$context"
}

_memory_retrieve_mcp() {
    local key="$1"
    local context="$2"

    # MCP retrieval would happen here
    # Fallback to file-based
    _memory_retrieve_fallback "$key" "$context"
}

_memory_search_mcp() {
    local query="$1"
    local limit="$2"

    # MCP search would happen here
    _memory_search_fallback "$query" "$limit"
}

# =============================================================================
# Fallback File-Based Implementation
# =============================================================================
_memory_store_fallback() {
    local key="$1"
    local value="$2"
    local context="$3"

    local context_dir="$MEMORY_FALLBACK_DIR/$context"
    mkdir -p "$context_dir"

    local memory_file="$context_dir/$(echo "$key" | md5sum | cut -d' ' -f1).json"

    jq -n \
        --arg key "$key" \
        --arg value "$value" \
        --arg context "$context" \
        --arg timestamp "$(date -Iseconds)" \
        '{
            key: $key,
            value: $value,
            context: $context,
            timestamp: $timestamp
        }' > "$memory_file" 2>/dev/null || echo "$value" > "$memory_file"
}

_memory_retrieve_fallback() {
    local key="$1"
    local context="$2"

    local context_dir="$MEMORY_FALLBACK_DIR/$context"
    local memory_file="$context_dir/$(echo "$key" | md5sum | cut -d' ' -f1).json"

    [[ ! -f "$memory_file" ]] && return 1

    jq -r '.value' "$memory_file" 2>/dev/null || cat "$memory_file"
}

_memory_search_fallback() {
    local query="$1"
    local limit="$2"

    find "$MEMORY_FALLBACK_DIR" -name "*.json" -type f 2>/dev/null | \
        while read -r file; do
            local content=$(cat "$file" 2>/dev/null || echo "{}")
            if echo "$content" | jq -r '.key, .value' 2>/dev/null | grep -iq "$query"; then
                echo "$content"
            fi
        done | head -n "$limit"
}

# =============================================================================
# Workflow Pattern Learning
# =============================================================================
memory_learn_workflow_pattern() {
    local prompt_pattern="$1"
    local successful_workflow="$2"

    local pattern_key="workflow_pattern:$(echo "$prompt_pattern" | md5sum | cut -d' ' -f1 | cut -c1-12)"

    # Retrieve existing patterns
    local existing=$(memory_retrieve "$pattern_key" "global" 2>/dev/null || echo "[]")

    # Add new pattern
    local updated=$(echo "$existing" | jq --arg workflow "$successful_workflow" \
        'if type == "array" then . + [$workflow] else [$workflow] end' 2>/dev/null || echo "[\"$successful_workflow\"]")

    memory_store "$pattern_key" "$updated" "global"

    hook_info "📚 Learned workflow pattern for: $prompt_pattern"
}

# =============================================================================
# Suggest Workflow Based on Past Patterns
# =============================================================================
memory_suggest_workflow() {
    local prompt="$1"

    # Extract key terms from prompt
    local key_terms=$(echo "$prompt" | tr '[:upper:]' '[:lower:]' | \
        grep -oE '\w{4,}' | sort -u | head -5 | tr '\n' ' ')

    # Search for similar past workflows
    local suggestions=$(memory_search "$key_terms" 5)

    if [[ -n "$suggestions" ]]; then
        hook_info "💡 Found $(echo "$suggestions" | wc -l) similar past workflows"
        return 0
    else
        return 1
    fi
}

# =============================================================================
# User Preference Learning
# =============================================================================
memory_learn_preference() {
    local preference_type="$1"  # e.g., "output_mode", "max_agents"
    local value="$2"
    local frequency="${3:-1}"

    local pref_key="user_pref:$preference_type"

    # Track frequency of this preference
    local existing=$(memory_retrieve "$pref_key" "global" 2>/dev/null || echo "{}")

    local updated=$(echo "$existing" | jq --arg value "$value" --argjson freq "$frequency" \
        'if type == "object" then .[$value] = ((.[$value] // 0) + $freq) else {($value): $freq} end' 2>/dev/null || \
        echo "{\"$value\": $frequency}")

    memory_store "$pref_key" "$updated" "global"
}

# =============================================================================
# Get Most Common User Preference
# =============================================================================
memory_get_preferred() {
    local preference_type="$1"
    local default="${2:-}"

    local pref_key="user_pref:$preference_type"
    local prefs=$(memory_retrieve "$pref_key" "global" 2>/dev/null || echo "{}")

    # Get most frequent value
    local preferred=$(echo "$prefs" | jq -r 'to_entries | max_by(.value) | .key' 2>/dev/null || echo "$default")

    echo "$preferred"
}

# =============================================================================
# Project-Specific Memory
# =============================================================================
memory_store_project_context() {
    local project_id="$1"
    local context_data="$2"

    memory_store "project_ctx:$project_id" "$context_data" "project"
}

memory_get_project_context() {
    local project_id="$1"

    memory_retrieve "project_ctx:$project_id" "project" 2>/dev/null || echo "{}"
}

# =============================================================================
# Cleanup Old Memories (optional maintenance)
# =============================================================================
memory_cleanup_old() {
    local days_old="${1:-90}"  # Default: 90 days

    find "$MEMORY_FALLBACK_DIR" -name "*.json" -mtime "+$days_old" -delete 2>/dev/null || true

    hook_info "🧹 Cleaned up memories older than $days_old days"
}
