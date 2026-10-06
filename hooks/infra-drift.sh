#!/bin/bash
# =============================================================================
# TIER 3: Infrastructure Drift Hook
# =============================================================================
# Event: PostToolUse (Edit|Write on infra files)
# Purpose: Ensures dev/prod parity and documents infra changes
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]] && exit 0

# Infrastructure file patterns
infra_patterns="(dockerfile|docker-compose|\.tf$|cdk|cloudformation|kubernetes|k8s|helm|\.yaml$|\.yml$)"
infra_dirs="(infra|infrastructure|deploy|cdk|terraform|k8s|kubernetes|helm|charts)"

is_infra=false

if echo "$file_path" | grep -iqE "$infra_patterns"; then
    is_infra=true
fi

if echo "$file_path" | grep -iqE "$infra_dirs"; then
    is_infra=true
fi

if [[ "$is_infra" == "true" ]]; then
    echo "Infrastructure file modified: $file_path"
    echo ""
    echo "Infra checklist:"
    echo "  [ ] Dev/prod parity maintained"
    echo "  [ ] Environment variables documented"
    echo "  [ ] Secrets use proper secret management"
    echo "  [ ] Ports not accidentally exposed"
    echo "  [ ] Resource limits defined"
    echo "  [ ] Health checks configured"
    echo "  [ ] Volumes/persistence accounted for"
    echo "  [ ] Rollback plan exists"
    echo ""

    PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

    # Check for env documentation
    if [[ ! -f "$PROJECT_DIR/.env.example" ]]; then
        echo "Warning: No .env.example found. Document required env vars."
    fi

    # Check for docker-compose override
    if [[ -f "$PROJECT_DIR/docker-compose.yml" ]] && [[ ! -f "$PROJECT_DIR/docker-compose.override.yml" ]]; then
        echo "Tip: Consider docker-compose.override.yml for local dev settings."
    fi
fi

exit 0
