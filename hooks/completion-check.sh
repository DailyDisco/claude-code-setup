#!/bin/bash
# =============================================================================
# Context-Aware Completion Check Hook
# =============================================================================
# Event: Stop
# Purpose: Only blocks session end when an active workflow has incomplete steps
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/workflow-state.sh"

# Default: allow stop
allow_stop() {
    echo '{"ok": true}'
    exit 0
}

block_stop() {
    local reason="$1"
    echo "{\"ok\": false, \"reason\": \"$reason\"}"
    exit 0
}

# Check 1: Is there an active workflow?
if ! workflow_is_active; then
    # No workflow = casual conversation, allow stop
    allow_stop
fi

# Check 2: Is the workflow complete?
if workflow_is_complete; then
    allow_stop
fi

# Workflow is active but incomplete - block with context
workflow_type=$(workflow_get_type)
step_name=$(workflow_get_step_name)
step=$(workflow_get_step)
total=$(workflow_get_total_steps)

block_stop "Active workflow '$workflow_type' incomplete: step $((step + 1))/$total ($step_name). Run /workflow-clear to abandon."
