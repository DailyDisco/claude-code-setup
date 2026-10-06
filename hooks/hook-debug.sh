#!/usr/bin/env bash
# =============================================================================
# Hook Debug Mode
# =============================================================================
# Run this to enable/disable hook debugging and view hook execution traces.
#
# Usage:
#   bash ~/.claude/hooks/hook-debug.sh enable    # Enable debug mode
#   bash ~/.claude/hooks/hook-debug.sh disable   # Disable debug mode
#   bash ~/.claude/hooks/hook-debug.sh status    # Show current status
#   bash ~/.claude/hooks/hook-debug.sh trace     # Show recent hook executions
#   bash ~/.claude/hooks/hook-debug.sh trace 50  # Show last 50 executions
# =============================================================================

set -euo pipefail

DEBUG_FILE="${HOME}/.claude/state/hook-debug-enabled"
TRACE_FILE="${HOME}/.claude/state/hook-trace.log"
METRICS_FILE="${HOME}/.claude/hook-metrics.jsonl"

mkdir -p "${HOME}/.claude/state"

show_usage() {
    cat << 'EOF'
Hook Debug Tool

Commands:
  enable     Enable verbose hook debugging
  disable    Disable hook debugging
  status     Show current debug status
  trace [n]  Show last n hook executions (default: 20)
  stats      Show hook execution statistics
  slow       Show slowest hooks
  errors     Show recent hook errors
  clear      Clear trace and metrics logs

Environment Variables (when enabled):
  HOOK_DEBUG=1           Verbose output from all hooks
  HOOK_TRACE=1           Log all hook invocations to trace file

EOF
}

enable_debug() {
    echo "1" > "$DEBUG_FILE"
    export HOOK_DEBUG=1
    export HOOK_TRACE=1
    echo "✅ Hook debug mode ENABLED"
    echo ""
    echo "Debug features active:"
    echo "  - Verbose hook output"
    echo "  - Execution tracing to $TRACE_FILE"
    echo "  - Performance timing logged"
    echo ""
    echo "Run 'bash ~/.claude/hooks/hook-debug.sh trace' to view executions"
}

disable_debug() {
    rm -f "$DEBUG_FILE"
    unset HOOK_DEBUG 2>/dev/null || true
    unset HOOK_TRACE 2>/dev/null || true
    echo "✅ Hook debug mode DISABLED"
}

show_status() {
    if [[ -f "$DEBUG_FILE" ]]; then
        echo "🐛 Debug mode: ENABLED"
    else
        echo "Debug mode: disabled"
    fi

    echo ""
    echo "Trace file: $TRACE_FILE"
    if [[ -f "$TRACE_FILE" ]]; then
        local lines=$(wc -l < "$TRACE_FILE")
        local size=$(du -h "$TRACE_FILE" | cut -f1)
        echo "  Lines: $lines | Size: $size"
    else
        echo "  (not created yet)"
    fi

    echo ""
    echo "Metrics file: $METRICS_FILE"
    if [[ -f "$METRICS_FILE" ]]; then
        local lines=$(wc -l < "$METRICS_FILE")
        local size=$(du -h "$METRICS_FILE" | cut -f1)
        echo "  Entries: $lines | Size: $size"
    else
        echo "  (not created yet)"
    fi
}

show_trace() {
    local count="${1:-20}"

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No hook executions recorded yet."
        return
    fi

    echo "Last $count hook executions:"
    echo "─────────────────────────────────────────────────────────────────"
    printf "%-20s %-25s %-10s %-8s %s\n" "HOOK" "TIMESTAMP" "RESULT" "MS" "PROJECT"
    echo "─────────────────────────────────────────────────────────────────"

    tail -n "$count" "$METRICS_FILE" | while read -r line; do
        local hook=$(echo "$line" | jq -r '.hook // "unknown"')
        local timestamp=$(echo "$line" | jq -r '.timestamp // ""' | cut -c1-19)
        local result=$(echo "$line" | jq -r '.result // "?"')
        local duration=$(echo "$line" | jq -r '.duration_ms // 0')
        local project=$(echo "$line" | jq -r '.project // ""' | cut -c1-15)

        local result_icon="✓"
        [[ "$result" == "failure" ]] && result_icon="✗"

        printf "%-20s %-25s %-10s %-8s %s\n" "$hook" "$timestamp" "$result_icon $result" "${duration}ms" "$project"
    done
}

show_stats() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No hook executions recorded yet."
        return
    fi

    echo "Hook Execution Statistics"
    echo "═════════════════════════════════════════════════════════════════"
    echo ""
    echo "By Hook (execution count):"
    echo "─────────────────────────────────────────────────────────────────"

    jq -r '.hook' "$METRICS_FILE" | sort | uniq -c | sort -rn | head -20 | while read -r count hook; do
        printf "  %-30s %5d executions\n" "$hook" "$count"
    done

    echo ""
    echo "By Result:"
    echo "─────────────────────────────────────────────────────────────────"
    jq -r '.result' "$METRICS_FILE" | sort | uniq -c | sort -rn | while read -r count result; do
        printf "  %-20s %5d\n" "$result" "$count"
    done

    echo ""
    echo "Average Duration by Hook:"
    echo "─────────────────────────────────────────────────────────────────"
    jq -s 'group_by(.hook) | map({hook: .[0].hook, avg_ms: (map(.duration_ms) | add / length | floor), count: length}) | sort_by(.avg_ms) | reverse | .[:15][] | "\(.hook)\t\(.avg_ms)ms\t(\(.count) runs)"' "$METRICS_FILE" 2>/dev/null | \
        while IFS=$'\t' read -r hook avg count; do
            printf "  %-30s %8s  %s\n" "$hook" "$avg" "$count"
        done
}

show_slow() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No hook executions recorded yet."
        return
    fi

    echo "Slowest Hook Executions (>1000ms)"
    echo "═════════════════════════════════════════════════════════════════"

    jq -s 'map(select(.duration_ms > 1000)) | sort_by(.duration_ms) | reverse | .[:20][] | "\(.hook)\t\(.duration_ms)ms\t\(.timestamp)\t\(.project)"' "$METRICS_FILE" 2>/dev/null | \
        while IFS=$'\t' read -r hook duration timestamp project; do
            printf "  %-25s %8s  %s  %s\n" "$hook" "$duration" "${timestamp:0:19}" "$project"
        done

    local slow_count=$(jq -s '[.[] | select(.duration_ms > 1000)] | length' "$METRICS_FILE")
    echo ""
    echo "Total slow executions: $slow_count"
}

show_errors() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "No hook executions recorded yet."
        return
    fi

    echo "Recent Hook Errors"
    echo "═════════════════════════════════════════════════════════════════"

    jq -s 'map(select(.result == "failure")) | sort_by(.timestamp) | reverse | .[:20][] | "\(.hook)\t\(.timestamp)\t\(.project)"' "$METRICS_FILE" 2>/dev/null | \
        while IFS=$'\t' read -r hook timestamp project; do
            printf "  %-25s %s  %s\n" "$hook" "${timestamp:0:19}" "$project"
        done

    local error_count=$(jq -s '[.[] | select(.result == "failure")] | length' "$METRICS_FILE")
    local total_count=$(jq -s 'length' "$METRICS_FILE")
    local error_rate=$(echo "scale=2; $error_count * 100 / $total_count" | bc 2>/dev/null || echo "0")

    echo ""
    echo "Total errors: $error_count / $total_count ($error_rate%)"
}

clear_logs() {
    rm -f "$TRACE_FILE"
    rm -f "$METRICS_FILE"
    echo "✅ Cleared trace and metrics logs"
}

# Main command router
case "${1:-}" in
    enable)
        enable_debug
        ;;
    disable)
        disable_debug
        ;;
    status)
        show_status
        ;;
    trace)
        show_trace "${2:-20}"
        ;;
    stats)
        show_stats
        ;;
    slow)
        show_slow
        ;;
    errors)
        show_errors
        ;;
    clear)
        clear_logs
        ;;
    *)
        show_usage
        ;;
esac
