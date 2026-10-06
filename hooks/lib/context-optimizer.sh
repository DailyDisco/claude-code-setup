#!/usr/bin/env bash
# =============================================================================
# Context Optimizer Library (Phase 3.1)
# =============================================================================
# Purpose: Smart context filtering based on prompt relevance
# Features:
#   - Prompt analysis for relevant keywords
#   - Priority-based context scoring
#   - Intelligent truncation to reduce token usage
#   - Works with output-filter.sh for layered optimization
# =============================================================================

# Import output-filter if available
source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

# =============================================================================
# Analyze user prompt for context relevance
# =============================================================================
analyze_prompt_context() {
    local prompt="${1:-}"

    # Return early if no prompt
    [[ -z "$prompt" ]] && echo "general" && return

    # Convert to lowercase for matching
    local prompt_lower=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')

    # Detect primary context areas
    local contexts=()

    # Database/Backend
    if [[ "$prompt_lower" =~ (database|migration|schema|sql|query|prisma|postgres|mysql) ]]; then
        contexts+=("database")
    fi

    # Frontend/UI
    if [[ "$prompt_lower" =~ (react|component|ui|frontend|css|tailwind|accessibility|a11y) ]]; then
        contexts+=("frontend")
    fi

    # API/Backend
    if [[ "$prompt_lower" =~ (api|endpoint|rest|graphql|route|controller|service) ]]; then
        contexts+=("api")
    fi

    # Infrastructure
    if [[ "$prompt_lower" =~ (docker|kubernetes|deploy|infra|terraform|aws|gcp|azure) ]]; then
        contexts+=("infrastructure")
    fi

    # Security
    if [[ "$prompt_lower" =~ (security|auth|vulnerability|owasp|encrypt|token|jwt) ]]; then
        contexts+=("security")
    fi

    # Testing
    if [[ "$prompt_lower" =~ (test|spec|jest|vitest|playwright|cypress) ]]; then
        contexts+=("testing")
    fi

    # Performance
    if [[ "$prompt_lower" =~ (performance|optimize|slow|latency|cache|speed) ]]; then
        contexts+=("performance")
    fi

    # Return contexts (comma-separated)
    if [[ ${#contexts[@]} -eq 0 ]]; then
        echo "general"
    else
        echo "${contexts[*]}" | tr ' ' ','
    fi
}

# =============================================================================
# Score context relevance (0-100)
# =============================================================================
score_context_relevance() {
    local context_type="$1"     # e.g., "database", "frontend"
    local detected_contexts="$2" # comma-separated list from analyze_prompt_context

    # Default score
    local score=50

    # Boost score if context matches
    if echo "$detected_contexts" | grep -q "$context_type"; then
        score=100
    elif [[ "$detected_contexts" == "general" ]]; then
        score=70  # Show general context when prompt is unclear
    else
        score=20  # De-prioritize unrelated context
    fi

    echo "$score"
}

# =============================================================================
# Determine if context should be shown based on relevance
# =============================================================================
should_show_context() {
    local context_type="$1"
    local detected_contexts="$2"
    local threshold="${3:-40}"  # Default threshold: 40/100

    local score=$(score_context_relevance "$context_type" "$detected_contexts")

    [[ $score -ge $threshold ]]
}

# =============================================================================
# Get optimized context priority
# Returns: "critical" | "high" | "medium" | "low"
# =============================================================================
get_context_priority() {
    local context_type="$1"
    local detected_contexts="$2"

    local score=$(score_context_relevance "$context_type" "$detected_contexts")

    if [[ $score -ge 90 ]]; then
        echo "critical"
    elif [[ $score -ge 70 ]]; then
        echo "high"
    elif [[ $score -ge 50 ]]; then
        echo "medium"
    else
        echo "low"
    fi
}

# =============================================================================
# Smart truncation for long output
# =============================================================================
truncate_context() {
    local input="$1"
    local max_lines="${2:-50}"  # Default: 50 lines
    local priority="${3:-medium}"

    # Adjust max_lines based on priority
    case "$priority" in
        critical) max_lines=$((max_lines * 2)) ;;
        high)     max_lines=$((max_lines + 20)) ;;
        medium)   max_lines=$max_lines ;;
        low)      max_lines=$((max_lines / 2)) ;;
    esac

    # Count lines
    local line_count=$(echo "$input" | wc -l)

    if [[ $line_count -le $max_lines ]]; then
        # No truncation needed
        echo "$input"
    else
        # Truncate with indicator
        echo "$input" | head -n "$max_lines"
        hook_info "[Context truncated: showing $max_lines of $line_count lines]"
    fi
}

# =============================================================================
# Get context optimization mode
# Returns: "aggressive" | "balanced" | "conservative"
# =============================================================================
get_optimization_mode() {
    local mode="${CLAUDE_CONTEXT_OPTIMIZATION:-balanced}"

    case "$mode" in
        aggressive|balanced|conservative)
            echo "$mode"
            ;;
        *)
            echo "balanced"
            ;;
    esac
}

# =============================================================================
# Calculate threshold based on optimization mode
# =============================================================================
get_relevance_threshold() {
    local mode=$(get_optimization_mode)

    case "$mode" in
        aggressive)   echo "60" ;;  # Only show highly relevant context
        balanced)     echo "40" ;;  # Show moderately relevant context
        conservative) echo "20" ;;  # Show most context (less filtering)
    esac
}

# =============================================================================
# Example usage function (for testing)
# =============================================================================
test_context_optimizer() {
    local test_prompt="$1"

    echo "Testing context optimizer with prompt: '$test_prompt'"
    echo ""

    local contexts=$(analyze_prompt_context "$test_prompt")
    echo "Detected contexts: $contexts"
    echo ""

    for ctx in database frontend api infrastructure security testing performance; do
        local score=$(score_context_relevance "$ctx" "$contexts")
        local priority=$(get_context_priority "$ctx" "$contexts")
        local threshold=$(get_relevance_threshold)

        if should_show_context "$ctx" "$contexts" "$threshold"; then
            echo "✅ $ctx - Score: $score, Priority: $priority (SHOW)"
        else
            echo "❌ $ctx - Score: $score, Priority: $priority (HIDE)"
        fi
    done
}

# Functions are available after sourcing this file
# No explicit export needed - sourcing makes them available in the current shell
