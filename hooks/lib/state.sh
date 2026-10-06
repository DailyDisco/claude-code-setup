#!/bin/bash
# Cross-Hook State Library
# Provides shared state management for hooks within a session

# State file location - uses session ID if available, otherwise temp
STATE_DIR="${CLAUDE_STATE_DIR:-/tmp/claude-hooks}"
SESSION_ID="${CLAUDE_SESSION_ID:-default}"
STATE_FILE="${STATE_DIR}/session-${SESSION_ID}.json"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Initialize state file if it doesn't exist
init_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo '{"created_at": "'$(date -Iseconds)'", "session_id": "'"$SESSION_ID"'"}' > "$STATE_FILE"
    fi
}

# Set a state value
# Usage: set_state "key" "value"
set_state() {
    local key="$1"
    local value="$2"
    init_state

    local tmp_file=$(mktemp)
    jq --arg k "$key" --arg v "$value" '.[$k] = $v | .updated_at = now | tostring' "$STATE_FILE" > "$tmp_file" 2>/dev/null || \
    jq -n --arg k "$key" --arg v "$value" '{($k): $v}' > "$tmp_file"
    mv "$tmp_file" "$STATE_FILE"
}

# Get a state value
# Usage: get_state "key" [default_value]
get_state() {
    local key="$1"
    local default="${2:-}"
    init_state

    local value
    value=$(jq -r ".$key // empty" "$STATE_FILE" 2>/dev/null)

    if [[ -z "$value" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Check if a state key exists
# Usage: has_state "key" && echo "exists"
has_state() {
    local key="$1"
    init_state

    jq -e "has(\"$key\")" "$STATE_FILE" > /dev/null 2>&1
}

# Delete a state key
# Usage: del_state "key"
del_state() {
    local key="$1"
    init_state

    local tmp_file=$(mktemp)
    jq "del(.$key)" "$STATE_FILE" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$STATE_FILE"
}

# Increment a counter
# Usage: inc_state "counter_name"
inc_state() {
    local key="$1"
    local current
    current=$(get_state "$key" "0")
    set_state "$key" "$((current + 1))"
}

# Append to an array
# Usage: append_state "array_key" "value"
append_state() {
    local key="$1"
    local value="$2"
    init_state

    local tmp_file=$(mktemp)
    jq --arg k "$key" --arg v "$value" \
        'if .[$k] then .[$k] += [$v] else .[$k] = [$v] end' \
        "$STATE_FILE" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$STATE_FILE"
}

# Get all state as JSON
# Usage: get_all_state
get_all_state() {
    init_state
    cat "$STATE_FILE"
}

# Clear all state for current session
# Usage: clear_state
clear_state() {
    rm -f "$STATE_FILE"
}

# Clean up old state files (older than 24 hours)
# Usage: cleanup_old_state
cleanup_old_state() {
    find "$STATE_DIR" -name "session-*.json" -mtime +1 -delete 2>/dev/null || true
}

# Common state keys used by hooks:
# - last_build_status: "pass" | "fail"
# - last_test_status: "pass" | "fail"
# - last_typecheck_status: "pass" | "fail"
# - files_changed: array of file paths
# - commit_count: number of commits this session
# - skills_suggested: array of skills suggested
# - workflow_step: current step in workflow
# - workflow_type: current workflow type
