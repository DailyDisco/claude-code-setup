#!/usr/bin/env bash
# =============================================================================
# Hook Aggregator Library
# =============================================================================
# Source this in hooks to collect and aggregate findings across multiple hooks.
# Provides unified reporting and deduplication of suggestions/warnings.
#
# Usage:
#   source "${HOME}/.claude/hooks/lib/aggregator.sh"
#   add_finding "warning" "Security" "Potential SQL injection in user.go:45"
#   add_suggestion "Use /security-auditor for full security scan"
#   output_findings
# =============================================================================

set -euo pipefail

# Aggregator state directory
AGGREGATOR_DIR="${HOME}/.claude/state/aggregator"
AGGREGATOR_SESSION="${SESSION_ID:-$(date +%s)}"
AGGREGATOR_FILE="${AGGREGATOR_DIR}/${AGGREGATOR_SESSION}.json"

# Ensure directory exists
mkdir -p "$AGGREGATOR_DIR"

# Initialize aggregator file if needed
_init_aggregator() {
    if [[ ! -f "$AGGREGATOR_FILE" ]]; then
        echo '{"findings":[],"suggestions":[],"blocks":[],"metadata":{"started":"'$(date -Iseconds)'","hooks_run":[]}}' > "$AGGREGATOR_FILE"
    fi
}

# Add a finding (warning, error, info)
# Usage: add_finding <severity> <category> <message> [file:line]
add_finding() {
    local severity="${1:-info}"
    local category="${2:-General}"
    local message="${3:-}"
    local location="${4:-}"
    local hook_name="${METRICS_HOOK_NAME:-$(basename "${BASH_SOURCE[1]:-unknown}" .sh)}"

    _init_aggregator

    local finding=$(jq -n \
        --arg sev "$severity" \
        --arg cat "$category" \
        --arg msg "$message" \
        --arg loc "$location" \
        --arg hook "$hook_name" \
        --arg ts "$(date -Iseconds)" \
        '{severity: $sev, category: $cat, message: $msg, location: $loc, hook: $hook, timestamp: $ts}')

    # Append finding (with deduplication by message)
    local temp=$(mktemp)
    jq --argjson finding "$finding" '
        if (.findings | map(.message) | index($finding.message)) then .
        else .findings += [$finding]
        end
    ' "$AGGREGATOR_FILE" > "$temp" && mv "$temp" "$AGGREGATOR_FILE"
}

# Add a suggestion (skill recommendation, improvement hint)
# Usage: add_suggestion <message> [priority]
add_suggestion() {
    local message="${1:-}"
    local priority="${2:-medium}"
    local hook_name="${METRICS_HOOK_NAME:-$(basename "${BASH_SOURCE[1]:-unknown}" .sh)}"

    _init_aggregator

    local suggestion=$(jq -n \
        --arg msg "$message" \
        --arg pri "$priority" \
        --arg hook "$hook_name" \
        '{message: $msg, priority: $pri, hook: $hook}')

    # Append suggestion (with deduplication)
    local temp=$(mktemp)
    jq --argjson suggestion "$suggestion" '
        if (.suggestions | map(.message) | index($suggestion.message)) then .
        else .suggestions += [$suggestion]
        end
    ' "$AGGREGATOR_FILE" > "$temp" && mv "$temp" "$AGGREGATOR_FILE"
}

# Add a blocking issue (prevents operation from proceeding)
# Usage: add_block <reason> [category]
add_block() {
    local reason="${1:-}"
    local category="${2:-General}"
    local hook_name="${METRICS_HOOK_NAME:-$(basename "${BASH_SOURCE[1]:-unknown}" .sh)}"

    _init_aggregator

    local block=$(jq -n \
        --arg reason "$reason" \
        --arg cat "$category" \
        --arg hook "$hook_name" \
        '{reason: $reason, category: $cat, hook: $hook}')

    local temp=$(mktemp)
    jq --argjson block "$block" '.blocks += [$block]' "$AGGREGATOR_FILE" > "$temp" && mv "$temp" "$AGGREGATOR_FILE"
}

# Record that a hook has run
# Usage: record_hook_run
record_hook_run() {
    local hook_name="${METRICS_HOOK_NAME:-$(basename "${BASH_SOURCE[1]:-unknown}" .sh)}"

    _init_aggregator

    local temp=$(mktemp)
    jq --arg hook "$hook_name" '
        .metadata.hooks_run += [$hook] | .metadata.hooks_run |= unique
    ' "$AGGREGATOR_FILE" > "$temp" && mv "$temp" "$AGGREGATOR_FILE"
}

# Output aggregated findings in a formatted way
# Usage: output_findings [format]
# Formats: text (default), json, summary
output_findings() {
    local format="${1:-text}"

    [[ ! -f "$AGGREGATOR_FILE" ]] && return 0

    local data=$(cat "$AGGREGATOR_FILE")
    local finding_count=$(echo "$data" | jq '.findings | length')
    local suggestion_count=$(echo "$data" | jq '.suggestions | length')
    local block_count=$(echo "$data" | jq '.blocks | length')

    # Nothing to report
    [[ "$finding_count" -eq 0 && "$suggestion_count" -eq 0 && "$block_count" -eq 0 ]] && return 0

    case "$format" in
        json)
            echo "$data"
            ;;
        summary)
            echo "Findings: $finding_count | Suggestions: $suggestion_count | Blocks: $block_count"
            ;;
        text|*)
            echo ""
            echo "═══════════════════════════════════════════════════════════════"
            echo "                    Hook Analysis Summary                       "
            echo "═══════════════════════════════════════════════════════════════"

            # Blocks first (most important)
            if [[ "$block_count" -gt 0 ]]; then
                echo ""
                echo "🚫 BLOCKING ISSUES ($block_count):"
                echo "$data" | jq -r '.blocks[] | "   [\(.category)] \(.reason) (from \(.hook))"'
            fi

            # Critical/High findings
            local critical_findings=$(echo "$data" | jq '[.findings[] | select(.severity == "critical" or .severity == "high")] | length')
            if [[ "$critical_findings" -gt 0 ]]; then
                echo ""
                echo "⚠️  CRITICAL/HIGH FINDINGS ($critical_findings):"
                echo "$data" | jq -r '.findings[] | select(.severity == "critical" or .severity == "high") | "   [\(.severity | ascii_upcase)] \(.category): \(.message)\(if .location != "" then " @ \(.location)" else "" end)"'
            fi

            # Medium/Low findings
            local other_findings=$(echo "$data" | jq '[.findings[] | select(.severity != "critical" and .severity != "high")] | length')
            if [[ "$other_findings" -gt 0 ]]; then
                echo ""
                echo "📋 OTHER FINDINGS ($other_findings):"
                echo "$data" | jq -r '.findings[] | select(.severity != "critical" and .severity != "high") | "   [\(.severity)] \(.category): \(.message)"'
            fi

            # Suggestions
            if [[ "$suggestion_count" -gt 0 ]]; then
                echo ""
                echo "💡 SUGGESTIONS ($suggestion_count):"
                echo "$data" | jq -r '.suggestions | sort_by(.priority) | reverse | .[] | "   - \(.message)"'
            fi

            echo ""
            echo "═══════════════════════════════════════════════════════════════"
            ;;
    esac
}

# Check if there are any blocking issues
# Usage: has_blocks && exit 2
has_blocks() {
    [[ ! -f "$AGGREGATOR_FILE" ]] && return 1
    local block_count=$(jq '.blocks | length' "$AGGREGATOR_FILE")
    [[ "$block_count" -gt 0 ]]
}

# Get count of findings by severity
# Usage: count_findings [severity]
count_findings() {
    local severity="${1:-}"
    [[ ! -f "$AGGREGATOR_FILE" ]] && echo 0 && return

    if [[ -z "$severity" ]]; then
        jq '.findings | length' "$AGGREGATOR_FILE"
    else
        jq --arg sev "$severity" '[.findings[] | select(.severity == $sev)] | length' "$AGGREGATOR_FILE"
    fi
}

# Clear aggregator state (call at end of hook chain)
# Usage: clear_aggregator
clear_aggregator() {
    rm -f "$AGGREGATOR_FILE"
}

# Clean old aggregator files (older than 1 hour)
# Usage: cleanup_old_aggregators
cleanup_old_aggregators() {
    find "$AGGREGATOR_DIR" -name "*.json" -mmin +60 -delete 2>/dev/null || true
}

# Auto-cleanup on source
cleanup_old_aggregators
