#!/usr/bin/env bash
# =============================================================================
# Alerting Library - Phase 3.2
# =============================================================================
# Purpose: Send notifications for critical events
# Channels:
#   - Desktop notifications (notify-send on Linux)
#   - Slack webhooks
#   - Discord webhooks
#   - File-based alerts (fallback)
# =============================================================================

source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

ALERT_LOG="${HOME}/.claude/cache/alerts.log"
mkdir -p "$(dirname "$ALERT_LOG")"

# =============================================================================
# Alert Levels
# =============================================================================
ALERT_LEVEL_INFO=1
ALERT_LEVEL_WARNING=2
ALERT_LEVEL_ERROR=3
ALERT_LEVEL_CRITICAL=4

# Minimum alert level to send (default: WARNING)
ALERT_THRESHOLD="${CLAUDE_ALERT_THRESHOLD:-2}"

# =============================================================================
# Send Alert (main function)
# =============================================================================
send_alert() {
    local level="$1"      # info | warning | error | critical
    local title="$2"
    local message="$3"
    local channel="${4:-all}"  # all | desktop | slack | discord | log

    # Convert level to numeric
    local level_num
    case "$level" in
        info)     level_num=$ALERT_LEVEL_INFO ;;
        warning)  level_num=$ALERT_LEVEL_WARNING ;;
        error)    level_num=$ALERT_LEVEL_ERROR ;;
        critical) level_num=$ALERT_LEVEL_CRITICAL ;;
        *)        level_num=$ALERT_LEVEL_INFO ;;
    esac

    # Skip if below threshold
    [[ $level_num -lt $ALERT_THRESHOLD ]] && return 0

    # Log alert
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $title: $message" >> "$ALERT_LOG"

    # Send to channels
    case "$channel" in
        all)
            _send_desktop_notification "$level" "$title" "$message"
            _send_slack_notification "$level" "$title" "$message"
            _send_discord_notification "$level" "$title" "$message"
            ;;
        desktop)
            _send_desktop_notification "$level" "$title" "$message"
            ;;
        slack)
            _send_slack_notification "$level" "$title" "$message"
            ;;
        discord)
            _send_discord_notification "$level" "$title" "$message"
            ;;
        log)
            # Already logged above
            ;;
    esac
}

# =============================================================================
# Desktop Notification (Linux)
# =============================================================================
_send_desktop_notification() {
    local level="$1"
    local title="$2"
    local message="$3"

    # Check if notify-send is available
    command -v notify-send &>/dev/null || return 0

    # Check if DISPLAY is set (required for X11)
    [[ -z "${DISPLAY:-}" ]] && return 0

    # Map level to urgency and icon
    local urgency="normal"
    local icon="dialog-information"

    case "$level" in
        critical)
            urgency="critical"
            icon="dialog-error"
            ;;
        error)
            urgency="critical"
            icon="dialog-warning"
            ;;
        warning)
            urgency="normal"
            icon="dialog-warning"
            ;;
    esac

    # Send notification
    notify-send -u "$urgency" -i "$icon" "Claude Code: $title" "$message" 2>/dev/null || true
}

# =============================================================================
# Slack Notification
# =============================================================================
_send_slack_notification() {
    local level="$1"
    local title="$2"
    local message="$3"

    # Check if webhook URL is configured
    local webhook_url="${CLAUDE_SLACK_WEBHOOK:-}"
    [[ -z "$webhook_url" ]] && return 0

    # Check if curl is available
    command -v curl &>/dev/null || return 0

    # Map level to color
    local color="#36a64f"  # green
    case "$level" in
        critical) color="#ff0000" ;;  # red
        error)    color="#ff9900" ;;  # orange
        warning)  color="#ffcc00" ;;  # yellow
    esac

    # Send Slack message
    local payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        --arg color "$color" \
        '{
            attachments: [{
                color: $color,
                title: ("Claude Code: " + $title),
                text: $message,
                footer: "Claude Code Alerts",
                ts: (now | floor)
            }]
        }')

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "$webhook_url" >/dev/null 2>&1 || true
}

# =============================================================================
# Discord Notification
# =============================================================================
_send_discord_notification() {
    local level="$1"
    local title="$2"
    local message="$3"

    # Check if webhook URL is configured
    local webhook_url="${CLAUDE_DISCORD_WEBHOOK:-}"
    [[ -z "$webhook_url" ]] && return 0

    # Check if curl is available
    command -v curl &>/dev/null || return 0

    # Map level to color (Discord uses decimal color codes)
    local color=3066993  # green
    case "$level" in
        critical) color=16711680 ;;  # red
        error)    color=16737792 ;;  # orange
        warning)  color=16776960 ;;  # yellow
    esac

    # Send Discord message
    local payload=$(jq -n \
        --arg title "$title" \
        --arg message "$message" \
        --argjson color "$color" \
        '{
            embeds: [{
                title: ("Claude Code: " + $title),
                description: $message,
                color: $color,
                footer: {
                    text: "Claude Code Alerts"
                },
                timestamp: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
            }]
        }')

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$payload" "$webhook_url" >/dev/null 2>&1 || true
}

# =============================================================================
# Convenience Functions
# =============================================================================
alert_info() {
    send_alert "info" "$1" "${2:-}" "${3:-all}"
}

alert_warning() {
    send_alert "warning" "$1" "${2:-}" "${3:-all}"
}

alert_error() {
    send_alert "error" "$1" "${2:-}" "${3:-all}"
}

alert_critical() {
    send_alert "critical" "$1" "${2:-}" "${3:-all}"
}

# =============================================================================
# Hook-specific alerts
# =============================================================================
alert_hook_failure() {
    local hook_name="$1"
    local error_msg="$2"

    alert_error \
        "Hook Failure: $hook_name" \
        "Hook '$hook_name' failed with error: $error_msg" \
        "all"
}

alert_performance_degradation() {
    local hook_name="$1"
    local duration="$2"
    local threshold="$3"

    alert_warning \
        "Performance Degradation" \
        "Hook '$hook_name' took ${duration}ms (threshold: ${threshold}ms)" \
        "desktop"
}

alert_mcp_server_down() {
    local server_name="$1"
    local url="$2"

    alert_warning \
        "MCP Server Down" \
        "MCP server '$server_name' is not responding at $url" \
        "desktop"
}

# =============================================================================
# Alert Log Management
# =============================================================================
alert_rotate_log() {
    local max_size=$((5 * 1024 * 1024))  # 5MB

    [[ ! -f "$ALERT_LOG" ]] && return 0

    local size=$(stat -c%s "$ALERT_LOG" 2>/dev/null || stat -f%z "$ALERT_LOG" 2>/dev/null || echo 0)

    if [[ $size -gt $max_size ]]; then
        mv "$ALERT_LOG" "${ALERT_LOG}.1" 2>/dev/null || true
        # Keep last 3 backups
        ls -t "${ALERT_LOG}".* 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true
    fi
}

# Rotate on source
alert_rotate_log

# =============================================================================
# Test Function
# =============================================================================
test_alerts() {
    echo "Testing alert system..."
    echo ""

    echo "1. Info alert (may not show if threshold > 1):"
    alert_info "Test Info" "This is a test info alert"
    sleep 1

    echo "2. Warning alert:"
    alert_warning "Test Warning" "This is a test warning alert"
    sleep 1

    echo "3. Error alert:"
    alert_error "Test Error" "This is a test error alert"
    sleep 1

    echo ""
    echo "Check desktop notifications and alert log:"
    echo "  tail -10 ~/.claude/cache/alerts.log"
}
