#!/bin/bash
# Project Memory Hook
# Saves key decisions, patterns, and learnings per project
# Triggered on session stop events

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECTS_DIR="${CLAUDE_DIR}/projects"
MEMORY_FILE="memory.json"

# Get project hash from environment or generate from cwd
get_project_hash() {
    local cwd="${CLAUDE_WORKING_DIRECTORY:-$(pwd)}"
    echo -n "$cwd" | sha256sum | cut -c1-16
}

# Get project name from directory
get_project_name() {
    local cwd="${CLAUDE_WORKING_DIRECTORY:-$(pwd)}"
    basename "$cwd"
}

# Initialize memory file if it doesn't exist
init_memory() {
    local project_dir="$1"
    local memory_path="${project_dir}/${MEMORY_FILE}"

    if [[ ! -f "$memory_path" ]]; then
        cat > "$memory_path" << EOF
{
  "project": "$(get_project_name)",
  "path": "${CLAUDE_WORKING_DIRECTORY:-$(pwd)}",
  "created": "$(date -Iseconds)",
  "updated": "$(date -Iseconds)",
  "decisions": [],
  "patterns": [],
  "learnings": [],
  "context": {}
}
EOF
    fi
    echo "$memory_path"
}

# Add an entry to memory
add_memory_entry() {
    local memory_path="$1"
    local category="$2"
    local entry="$3"
    local timestamp
    timestamp="$(date -Iseconds)"

    # Use jq to add entry if available
    if command -v jq &> /dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg cat "$category" \
           --arg entry "$entry" \
           --arg ts "$timestamp" \
           '.[$cat] += [{"content": $entry, "timestamp": $ts}] | .updated = $ts' \
           "$memory_path" > "$tmp" && mv "$tmp" "$memory_path"
    fi
}

# Update context field
update_context() {
    local memory_path="$1"
    local key="$2"
    local value="$3"

    if command -v jq &> /dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg key "$key" \
           --arg val "$value" \
           --arg ts "$(date -Iseconds)" \
           '.context[$key] = $val | .updated = $ts' \
           "$memory_path" > "$tmp" && mv "$tmp" "$memory_path"
    fi
}

# Extract decisions/learnings from session (called by StopSession hook)
extract_session_insights() {
    local project_hash
    project_hash=$(get_project_hash)
    local project_dir="${PROJECTS_DIR}/${project_hash}"

    mkdir -p "$project_dir"

    local memory_path
    memory_path=$(init_memory "$project_dir")

    # Update last accessed timestamp
    if command -v jq &> /dev/null; then
        local tmp
        tmp=$(mktemp)
        jq --arg ts "$(date -Iseconds)" '.updated = $ts' "$memory_path" > "$tmp" && mv "$tmp" "$memory_path"
    fi

    # Log for debugging
    echo "Project memory updated: $memory_path" >&2
}

# Load memory context (called by SessionStart hook)
load_project_memory() {
    local project_hash
    project_hash=$(get_project_hash)
    local project_dir="${PROJECTS_DIR}/${project_hash}"
    local memory_path="${project_dir}/${MEMORY_FILE}"

    if [[ -f "$memory_path" ]] && command -v jq &> /dev/null; then
        # Output memory context for Claude to consume
        echo "## Project Memory"
        echo ""
        echo "**Project:** $(jq -r '.project' "$memory_path")"
        echo "**Last Session:** $(jq -r '.updated' "$memory_path")"
        echo ""

        # Recent decisions
        local decisions
        decisions=$(jq -r '.decisions[-3:] | .[] | "- \(.content)"' "$memory_path" 2>/dev/null || echo "")
        if [[ -n "$decisions" ]]; then
            echo "### Recent Decisions"
            echo "$decisions"
            echo ""
        fi

        # Key patterns
        local patterns
        patterns=$(jq -r '.patterns[-3:] | .[] | "- \(.content)"' "$memory_path" 2>/dev/null || echo "")
        if [[ -n "$patterns" ]]; then
            echo "### Established Patterns"
            echo "$patterns"
            echo ""
        fi

        # Learnings
        local learnings
        learnings=$(jq -r '.learnings[-3:] | .[] | "- \(.content)"' "$memory_path" 2>/dev/null || echo "")
        if [[ -n "$learnings" ]]; then
            echo "### Learnings"
            echo "$learnings"
            echo ""
        fi
    fi
}

# CLI interface
case "${1:-load}" in
    "load")
        load_project_memory
        ;;
    "save")
        extract_session_insights
        ;;
    "add-decision")
        project_hash=$(get_project_hash)
        project_dir="${PROJECTS_DIR}/${project_hash}"
        mkdir -p "$project_dir"
        memory_path=$(init_memory "$project_dir")
        add_memory_entry "$memory_path" "decisions" "${2:-}"
        ;;
    "add-pattern")
        project_hash=$(get_project_hash)
        project_dir="${PROJECTS_DIR}/${project_hash}"
        mkdir -p "$project_dir"
        memory_path=$(init_memory "$project_dir")
        add_memory_entry "$memory_path" "patterns" "${2:-}"
        ;;
    "add-learning")
        project_hash=$(get_project_hash)
        project_dir="${PROJECTS_DIR}/${project_hash}"
        mkdir -p "$project_dir"
        memory_path=$(init_memory "$project_dir")
        add_memory_entry "$memory_path" "learnings" "${2:-}"
        ;;
    "set-context")
        project_hash=$(get_project_hash)
        project_dir="${PROJECTS_DIR}/${project_hash}"
        mkdir -p "$project_dir"
        memory_path=$(init_memory "$project_dir")
        update_context "$memory_path" "${2:-key}" "${3:-value}"
        ;;
    *)
        echo "Usage: $0 {load|save|add-decision|add-pattern|add-learning|set-context}" >&2
        exit 1
        ;;
esac
