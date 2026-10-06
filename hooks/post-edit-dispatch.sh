#!/bin/bash
# Post-Edit Dispatcher
# Event: PostToolUse (Edit|Write)
# Purpose: Smart routing to relevant hooks based on file type/path
# Replaces multiple individual hooks with a single dispatcher for lower latency

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

# Get the file from tool input
input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
tool=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)

# Skip if no file context
[[ -z "$file" ]] && exit 0

HOOKS_DIR="${HOME}/.claude/hooks"
hooks_to_run=()

# =============================================================================
# File-Type Based Routing
# =============================================================================

case "$file" in
    # TypeScript/JavaScript
    *.ts|*.tsx|*.js|*.jsx)
        hooks_to_run+=("type-check.sh")
        ;;

    # SQL/Migrations
    *.sql|*migration*|*migrate*)
        hooks_to_run+=("migration-safety.sh")
        ;;

    # Infrastructure
    *.tf|*.tfvars|*terraform*|*.yaml|*.yml)
        if [[ "$file" =~ (deploy|k8s|kubernetes|helm|docker-compose|infrastructure) ]]; then
            hooks_to_run+=("infra-drift.sh")
        fi
        ;;

    # Internationalization
    *i18n*|*locale*|*translation*|*lang/*)
        hooks_to_run+=("i18n-check.sh")
        ;;
esac

# =============================================================================
# Path-Pattern Based Routing
# =============================================================================

# API/Route changes -> OpenAPI sync
if [[ "$file" =~ (api|route|endpoint|controller|handler) ]]; then
    hooks_to_run+=("openapi-sync.sh")
fi

# Security-sensitive files
if [[ "$file" =~ (auth|security|password|token|credential|secret|crypto|permission) ]]; then
    hooks_to_run+=("security-check.sh")
fi

# Test file edits don't need test-gen prompt
if [[ ! "$file" =~ (test|spec|__tests__|_test\.) ]]; then
    hooks_to_run+=("test-gen-prompt.sh")
fi

# Breaking change detection for exports/public APIs
if [[ "$file" =~ (index\.|exports\.|public|api/v[0-9]) ]]; then
    hooks_to_run+=("breaking-change.sh")
fi

# =============================================================================
# Run Hooks in Parallel
# =============================================================================

# Deduplicate hooks
declare -A seen
unique_hooks=()
for hook in "${hooks_to_run[@]}"; do
    if [[ -z "${seen[$hook]:-}" ]]; then
        seen[$hook]=1
        unique_hooks+=("$hook")
    fi
done

# Run in parallel, capture outputs
pids=()
outputs=()
for hook in "${unique_hooks[@]}"; do
    hook_path="${HOOKS_DIR}/${hook}"
    if [[ -x "$hook_path" ]]; then
        # Run in background, capture output
        output_file=$(mktemp)
        echo "$input" | bash "$hook_path" > "$output_file" 2>&1 &
        pids+=($!)
        outputs+=("$output_file")
    fi
done

# Wait for all hooks and collect outputs
combined_output=""
for i in "${!pids[@]}"; do
    wait "${pids[$i]}" 2>/dev/null || true
    if [[ -s "${outputs[$i]}" ]]; then
        combined_output+=$(cat "${outputs[$i]}")
        combined_output+=$'\n'
    fi
    rm -f "${outputs[$i]}"
done

# Output combined results (non-empty only)
[[ -n "$combined_output" ]] && echo "$combined_output"

exit 0
