#!/bin/bash
# Workflow Resume Hook
# Event: SessionStart
# Purpose: Detect and offer to resume interrupted workflows from previous sessions

set -euo pipefail

# Source workflow state library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/workflow-state.sh"

# Check if there's an active workflow
if ! workflow_is_active; then
    exit 0
fi

# Check if workflow is complete (shouldn't normally happen, but handle it)
if workflow_is_complete; then
    echo ""
    echo "Previous workflow completed but not archived. Archiving now..."
    workflow_complete
    exit 0
fi

# Get workflow details
workflow_type=$(workflow_get_type)
step=$(workflow_get_step)
step_name=$(workflow_get_step_name)
total=$(workflow_get_total_steps)
started_at=$(jq -r '.started_at // "unknown"' "$(get_workflow_file)")

# Format the start time
if [[ "$started_at" != "unknown" ]]; then
    # Try to format the date nicely
    if date --version &>/dev/null 2>&1; then
        # GNU date
        started_fmt=$(date -d "$started_at" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$started_at")
    else
        # BSD date (macOS)
        started_fmt=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$started_at" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$started_at")
    fi
else
    started_fmt="unknown"
fi

# Get completed and skipped steps
workflow_file=$(get_workflow_file)
completed_steps=$(jq -r '.steps_completed | join(", ")' "$workflow_file" 2>/dev/null || echo "none")
skipped_steps=$(jq -r '.steps_skipped | map(.step) | join(", ")' "$workflow_file" 2>/dev/null || echo "none")

# Display resume prompt
echo ""
echo "========================================"
echo "  INTERRUPTED WORKFLOW DETECTED"
echo "========================================"
echo ""
echo "  Type:     $workflow_type"
echo "  Started:  $started_fmt"
echo "  Progress: Step $((step + 1)) of $total"
echo "  Current:  $step_name"
echo ""
if [[ "$completed_steps" != "none" && -n "$completed_steps" ]]; then
    echo "  Completed: $completed_steps"
fi
if [[ "$skipped_steps" != "none" && -n "$skipped_steps" ]]; then
    echo "  Skipped:   $skipped_steps"
fi
echo ""
echo "  Commands:"
echo "    /workflow resume  - Continue from $step_name"
echo "    /workflow status  - View detailed progress"
echo "    /workflow abort   - Cancel and start fresh"
echo ""
echo "========================================"

exit 0
