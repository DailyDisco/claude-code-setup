#!/bin/bash
# Workflow State Library
# Provides persistent workflow state management across sessions
# Extends lib/state.sh with workflow-specific functionality

set -euo pipefail

# Source base state library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/state.sh"

# Workflow state directory (persists across sessions)
WORKFLOW_DIR="${HOME}/.claude/workflows"
mkdir -p "$WORKFLOW_DIR"

# Get project identifier from current directory
get_project_id() {
    local dir="${PWD}"
    # Use git root if in a git repo, otherwise use directory name
    if git rev-parse --git-dir &>/dev/null; then
        dir=$(git rev-parse --show-toplevel 2>/dev/null || echo "$dir")
    fi
    # Create safe filename from path
    echo "$dir" | sed 's/[^a-zA-Z0-9]/_/g' | sed 's/__*/_/g'
}

# Workflow state file for current project
get_workflow_file() {
    local project_id
    project_id=$(get_project_id)
    echo "${WORKFLOW_DIR}/${project_id}.json"
}

# Initialize workflow state file
init_workflow() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    if [[ ! -f "$workflow_file" ]]; then
        cat > "$workflow_file" << EOF
{
    "project": "$(pwd)",
    "created_at": "$(date -Iseconds)",
    "workflow": null,
    "step": null,
    "steps_completed": [],
    "steps_skipped": [],
    "artifacts": [],
    "history": []
}
EOF
    fi
}

# Start a new workflow
# Usage: workflow_start "feature" '["Plan", "PRD", "Implement", "Test", "Verify", "Commit", "Review"]'
workflow_start() {
    local workflow_type="$1"
    local steps_json="$2"
    local workflow_file
    workflow_file=$(get_workflow_file)
    init_workflow

    local tmp_file=$(mktemp)
    jq --arg type "$workflow_type" \
       --argjson steps "$steps_json" \
       --arg started "$(date -Iseconds)" \
       '.workflow = $type | .step = 0 | .steps = $steps | .started_at = $started | .steps_completed = [] | .steps_skipped = [] | .artifacts = []' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"

    # Record in history
    workflow_log "Started workflow: $workflow_type"
}

# Get current workflow type
# Usage: workflow_type=$(workflow_get_type)
workflow_get_type() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    [[ -f "$workflow_file" ]] && jq -r '.workflow // empty' "$workflow_file" 2>/dev/null
}

# Get current step index (0-based)
# Usage: step=$(workflow_get_step)
workflow_get_step() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    [[ -f "$workflow_file" ]] && jq -r '.step // empty' "$workflow_file" 2>/dev/null
}

# Get current step name
# Usage: step_name=$(workflow_get_step_name)
workflow_get_step_name() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    local step
    step=$(workflow_get_step)
    [[ -n "$step" ]] && jq -r ".steps[$step] // empty" "$workflow_file" 2>/dev/null
}

# Get all steps
# Usage: steps=$(workflow_get_steps)
workflow_get_steps() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    [[ -f "$workflow_file" ]] && jq -r '.steps // []' "$workflow_file" 2>/dev/null
}

# Get total step count
# Usage: total=$(workflow_get_total_steps)
workflow_get_total_steps() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    [[ -f "$workflow_file" ]] && jq -r '.steps | length' "$workflow_file" 2>/dev/null || echo "0"
}

# Advance to next step
# Usage: workflow_next_step
workflow_next_step() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    local current_step current_name
    current_step=$(workflow_get_step)
    current_name=$(workflow_get_step_name)

    local tmp_file=$(mktemp)
    jq --arg step "$current_name" \
       '.step = (.step + 1) | .steps_completed += [$step]' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"

    workflow_log "Completed step: $current_name"
}

# Skip current step
# Usage: workflow_skip_step "reason"
workflow_skip_step() {
    local reason="${1:-No reason provided}"
    local workflow_file
    workflow_file=$(get_workflow_file)
    local current_name
    current_name=$(workflow_get_step_name)

    local tmp_file=$(mktemp)
    jq --arg step "$current_name" \
       --arg reason "$reason" \
       '.step = (.step + 1) | .steps_skipped += [{"step": $step, "reason": $reason}]' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"

    workflow_log "Skipped step: $current_name ($reason)"
}

# Add artifact
# Usage: workflow_add_artifact "PRD.md"
workflow_add_artifact() {
    local artifact="$1"
    local workflow_file
    workflow_file=$(get_workflow_file)

    local tmp_file=$(mktemp)
    jq --arg artifact "$artifact" \
       '.artifacts += [$artifact]' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"
}

# Check if workflow is active
# Usage: workflow_is_active && echo "Active"
workflow_is_active() {
    local workflow_type
    workflow_type=$(workflow_get_type)
    [[ -n "$workflow_type" ]]
}

# Check if workflow is complete
# Usage: workflow_is_complete && echo "Done"
workflow_is_complete() {
    local step total
    step=$(workflow_get_step)
    total=$(workflow_get_total_steps)
    [[ -n "$step" && -n "$total" && "$step" -ge "$total" ]]
}

# Complete workflow
# Usage: workflow_complete
workflow_complete() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    local workflow_type
    workflow_type=$(workflow_get_type)

    local tmp_file=$(mktemp)
    jq --arg completed "$(date -Iseconds)" \
       '.completed_at = $completed' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"

    workflow_log "Completed workflow: $workflow_type"

    # Archive to history
    workflow_archive
}

# Clear current workflow
# Usage: workflow_clear
workflow_clear() {
    local workflow_file
    workflow_file=$(get_workflow_file)

    local tmp_file=$(mktemp)
    jq '.workflow = null | .step = null | .steps = [] | .steps_completed = [] | .steps_skipped = [] | .artifacts = []' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"
}

# Log workflow event
# Usage: workflow_log "message"
workflow_log() {
    local message="$1"
    local workflow_file
    workflow_file=$(get_workflow_file)

    local tmp_file=$(mktemp)
    jq --arg msg "$message" \
       --arg ts "$(date -Iseconds)" \
       '.history += [{"timestamp": $ts, "message": $msg}]' \
       "$workflow_file" > "$tmp_file" && mv "$tmp_file" "$workflow_file"
}

# Archive completed workflow
workflow_archive() {
    local workflow_file archive_dir archive_file
    workflow_file=$(get_workflow_file)
    archive_dir="${WORKFLOW_DIR}/archive"
    mkdir -p "$archive_dir"

    local project_id workflow_type
    project_id=$(get_project_id)
    workflow_type=$(workflow_get_type)
    archive_file="${archive_dir}/${project_id}_${workflow_type}_$(date +%Y%m%d_%H%M%S).json"

    # Copy current state to archive
    cp "$workflow_file" "$archive_file"

    # Clear current workflow
    workflow_clear
}

# Get workflow summary (for display)
# Usage: workflow_summary
workflow_summary() {
    local workflow_file
    workflow_file=$(get_workflow_file)

    if ! workflow_is_active; then
        echo "No active workflow"
        return 1
    fi

    local workflow_type step step_name total completed skipped
    workflow_type=$(workflow_get_type)
    step=$(workflow_get_step)
    step_name=$(workflow_get_step_name)
    total=$(workflow_get_total_steps)
    completed=$(jq -r '.steps_completed | length' "$workflow_file")
    skipped=$(jq -r '.steps_skipped | length' "$workflow_file")

    cat << EOF
Workflow: $workflow_type
Progress: Step $((step + 1))/$total - $step_name
Completed: $completed | Skipped: $skipped
EOF
}

# Get full workflow state as JSON
# Usage: workflow_get_state
workflow_get_state() {
    local workflow_file
    workflow_file=$(get_workflow_file)
    [[ -f "$workflow_file" ]] && cat "$workflow_file"
}
