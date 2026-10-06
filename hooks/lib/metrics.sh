#!/usr/bin/env bash
# Hook metrics library
# Source this in hooks to automatically track execution time and results

METRICS_FILE="${HOME}/.claude/hook-metrics.jsonl"
METRICS_HOOK_NAME="${METRICS_HOOK_NAME:-$(basename "${BASH_SOURCE[1]:-unknown}" .sh)}"
METRICS_START_TIME=$(date +%s%3N)
METRICS_START_ISO=$(date -Iseconds)

METRICS_SESSION_ID="${SESSION_ID:-unknown}"
METRICS_TOOL_NAME="${TOOL_NAME:-unknown}"
METRICS_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
METRICS_PROJECT_NAME=$(basename "$METRICS_PROJECT_DIR")

# Auto-rotate metrics file to prevent unbounded growth
_rotate_metrics() {
    METRICS_FILE="${HOME}/.claude/hook-metrics.jsonl"
    MAX_SIZE=$((10 * 1024 * 1024))  # 10MB

    if [[ -f "$METRICS_FILE" ]]; then
        # Get file size (compatible with Linux and macOS)
        size=$(stat -c%s "$METRICS_FILE" 2>/dev/null || stat -f%z "$METRICS_FILE" 2>/dev/null || echo 0)

        if [[ $size -gt $MAX_SIZE ]]; then
            backup="${METRICS_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
            mv "$METRICS_FILE" "$backup" 2>/dev/null || true

            # Keep only last 3 backups
            ls -t "${METRICS_FILE}.backup-"* 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true

            # Log rotation (silent - don't spam output)
            : # echo "Rotated metrics file (${size} bytes -> ${backup})" >&2
        fi
    fi
}

# Run rotation check on library load
_rotate_metrics

_record_metrics() {
    local exit_code=$?
    local end_time=$(date +%s%3N)
    local duration_ms=$((end_time - METRICS_START_TIME))
    local result="success"
    [[ $exit_code -ne 0 ]] && result="failure"

    printf '{"hook":"%s","duration_ms":%d,"exit_code":%d,"result":"%s","tool":"%s","project":"%s","timestamp":"%s"}\n' \
        "$METRICS_HOOK_NAME" "$duration_ms" "$exit_code" "$result" \
        "$METRICS_TOOL_NAME" "$METRICS_PROJECT_NAME" "$METRICS_START_ISO" \
        >> "$METRICS_FILE" 2>/dev/null || true
}

trap _record_metrics EXIT

record_metric() {
    local name="$1" duration_ms="$2" result="${3:-success}" exit_code="${4:-0}"
    printf '{"hook":"%s","duration_ms":%d,"exit_code":%d,"result":"%s","tool":"%s","project":"%s","timestamp":"%s"}\n' \
        "$name" "$duration_ms" "$exit_code" "$result" \
        "$METRICS_TOOL_NAME" "$METRICS_PROJECT_NAME" "$(date -Iseconds)" \
        >> "$METRICS_FILE" 2>/dev/null || true
}
