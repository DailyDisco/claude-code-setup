#!/usr/bin/env bash
# =============================================================================
# Agent Memory Library (Cache-Based)
# =============================================================================
# Purpose: Share agent results across invocations within a session
# Storage: File-based cache (24h TTL)
# Future: Can migrate to Memory MCP server
# =============================================================================

AGENT_MEMORY_DIR="${HOME}/.claude/cache/agent-memory"
AGENT_MEMORY_TTL="${CLAUDE_AGENT_MEMORY_TTL:-86400}"  # 24 hours

# Initialize cache directory
mkdir -p "$AGENT_MEMORY_DIR"

# =============================================================================
# Store agent result
# =============================================================================
agent_memory_store() {
    local agent_name="$1"
    local result="$2"
    local session_id="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"
    local timestamp=$(date +%s)

    local key="${session_id}:${agent_name}:${timestamp}"
    local cache_file="$AGENT_MEMORY_DIR/${key}.json"

    # Store with metadata
    jq -n \
        --arg agent "$agent_name" \
        --arg session "$session_id" \
        --arg timestamp "$timestamp" \
        --arg result "$result" \
        '{agent: $agent, session: $session, timestamp: $timestamp, result: $result}' \
        > "$cache_file" 2>/dev/null || echo "$result" > "$cache_file"

    # Cleanup old entries on write
    _agent_memory_cleanup
}

# =============================================================================
# Retrieve all results from current session
# =============================================================================
agent_memory_retrieve() {
    local session_id="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"
    local agent_filter="${1:-*}"  # Optional: filter by agent name

    find "$AGENT_MEMORY_DIR" -name "${session_id}:${agent_filter}:*.json" \
        -type f -mtime -1 2>/dev/null | \
        while read -r file; do
            cat "$file" 2>/dev/null || true
        done
}

# =============================================================================
# Retrieve result from specific agent in current session
# =============================================================================
agent_memory_get() {
    local agent_name="$1"
    local session_id="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"

    # Get most recent result from this agent in this session
    find "$AGENT_MEMORY_DIR" -name "${session_id}:${agent_name}:*.json" \
        -type f -mtime -1 2>/dev/null | \
        sort -r | head -1 | xargs cat 2>/dev/null || true
}

# =============================================================================
# Check if agent has run in current session
# =============================================================================
agent_memory_exists() {
    local agent_name="$1"
    local session_id="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"

    [[ -n $(find "$AGENT_MEMORY_DIR" -name "${session_id}:${agent_name}:*.json" \
        -type f -mtime -1 2>/dev/null | head -1) ]]
}

# =============================================================================
# Clear all agent memory for current session
# =============================================================================
agent_memory_clear_session() {
    local session_id="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"
    find "$AGENT_MEMORY_DIR" -name "${session_id}:*.json" -delete 2>/dev/null || true
}

# =============================================================================
# Cleanup old entries (older than TTL)
# =============================================================================
_agent_memory_cleanup() {
    local now=$(date +%s)
    local cutoff=$((now - AGENT_MEMORY_TTL))

    find "$AGENT_MEMORY_DIR" -name "*.json" -type f 2>/dev/null | \
        while read -r file; do
            # Extract timestamp from filename (format: session:agent:timestamp.json)
            timestamp=$(basename "$file" .json | cut -d: -f3)
            if [[ -n "$timestamp" ]] && [[ "$timestamp" =~ ^[0-9]+$ ]]; then
                if [[ $timestamp -lt $cutoff ]]; then
                    rm -f "$file" 2>/dev/null || true
                fi
            fi
        done
}

# =============================================================================
# Get session summary (how many agents have run)
# =============================================================================
agent_memory_session_summary() {
    local session_id="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"

    find "$AGENT_MEMORY_DIR" -name "${session_id}:*.json" -type f 2>/dev/null | \
        while read -r file; do
            basename "$file" | cut -d: -f2
        done | sort -u | wc -l
}

# =============================================================================
# User Preference Storage (Phase 3.1)
# =============================================================================
PREFS_FILE="${HOME}/.claude/cache/user-prefs.json"

# Store user preference
user_pref_set() {
    local key="$1"
    local value="$2"

    # Create or update preferences file
    if [[ -f "$PREFS_FILE" ]]; then
        jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$PREFS_FILE" > "${PREFS_FILE}.tmp" 2>/dev/null && \
        mv "${PREFS_FILE}.tmp" "$PREFS_FILE"
    else
        jq -n --arg key "$key" --arg value "$value" '{($key): $value}' > "$PREFS_FILE" 2>/dev/null
    fi
}

# Get user preference
user_pref_get() {
    local key="$1"
    local default="${2:-}"

    if [[ -f "$PREFS_FILE" ]]; then
        jq -r --arg key "$key" --arg default "$default" \
            'if .[$key] then .[$key] else $default end' "$PREFS_FILE" 2>/dev/null || echo "$default"
    else
        echo "$default"
    fi
}

# Check if preference exists
user_pref_exists() {
    local key="$1"

    [[ -f "$PREFS_FILE" ]] && jq -e --arg key "$key" 'has($key)' "$PREFS_FILE" >/dev/null 2>&1
}

# List all preferences
user_pref_list() {
    [[ -f "$PREFS_FILE" ]] && jq -r 'to_entries[] | "\(.key)=\(.value)"' "$PREFS_FILE" 2>/dev/null || true
}

# Delete preference
user_pref_delete() {
    local key="$1"

    if [[ -f "$PREFS_FILE" ]]; then
        jq --arg key "$key" 'del(.[$key])' "$PREFS_FILE" > "${PREFS_FILE}.tmp" 2>/dev/null && \
        mv "${PREFS_FILE}.tmp" "$PREFS_FILE"
    fi
}

# Export functions (bash compatibility)
if [[ -n "${BASH_VERSION:-}" ]]; then
    export -f agent_memory_store
    export -f agent_memory_retrieve
    export -f agent_memory_get
    export -f agent_memory_exists
    export -f agent_memory_clear_session
    export -f agent_memory_session_summary
    export -f user_pref_set
    export -f user_pref_get
    export -f user_pref_exists
    export -f user_pref_list
    export -f user_pref_delete
fi
