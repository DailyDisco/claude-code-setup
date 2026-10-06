#!/bin/bash
# =============================================================================
# TIER 2: PRD Enforcement Hook
# =============================================================================
# Event: UserPromptSubmit
# Purpose: Detects feature requests and enforces PRD-first workflow
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty')

# Keywords indicating a feature/app request
feature_patterns="(build|create|implement|add|develop|make|write).*(feature|app|application|service|api|endpoint|system|module|component|page|view)"

# Check if prompt looks like a feature request
if echo "$prompt" | grep -iqE "$feature_patterns"; then
    # Check if user explicitly wants code
    if echo "$prompt" | grep -iqE "(just|only|directly|immediately).*(code|implement|write)"; then
        exit 0
    fi

    # Check if PRD already exists or is mentioned
    if echo "$prompt" | grep -iqE "(prd|spec|specification|design doc)"; then
        exit 0
    fi

    # Suggest PRD-first approach with skill reference
    cat << 'EOF'
Feature request detected. Consider PRD-first workflow:

**Recommended:** Run `/prd-generator` to create a structured PRD.md with:
- Scope and Non-Goals
- Data models and API contracts
- State management approach
- Edge cases and test strategy
- Migration/rollback plan

**Or:** Run `/workflow feature` for the complete feature development workflow.

To skip this and code directly, include "just code" in your request.
EOF
fi

exit 0
