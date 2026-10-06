#!/usr/bin/env bash
# =============================================================================
# MCP Server Healthcheck Hook
# =============================================================================
# Event: SessionStart
# Purpose: Verify MCP servers are responding and warn about failures
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true
source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

SETTINGS_FILE="${HOME}/.claude/settings.json"
TIMEOUT=5

# Check if settings file exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
    exit 0
fi

# Extract MCP servers from settings
MCP_SERVERS=$(jq -r '.mcpServers // {} | keys[]' "$SETTINGS_FILE" 2>/dev/null || true)

if [[ -z "$MCP_SERVERS" ]]; then
    exit 0
fi

healthy=0
unhealthy=0
warnings=()

for server in $MCP_SERVERS; do
    server_type=$(jq -r ".mcpServers.\"$server\".type // \"stdio\"" "$SETTINGS_FILE")

    case "$server_type" in
        sse)
            # SSE servers have a URL we can ping
            url=$(jq -r ".mcpServers.\"$server\".url // empty" "$SETTINGS_FILE")
            if [[ -n "$url" ]]; then
                # Try to connect to the SSE endpoint
                if curl -s --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" "$url" > /dev/null 2>&1; then
                    ((++healthy))
                else
                    ((++unhealthy))
                    warnings+=("⚠️  MCP server '$server' (SSE) is not responding at $url")
                fi
            else
                ((++healthy))  # No URL to check, assume OK
            fi
            ;;
        *)
            # stdio/command-based servers - check if command exists
            cmd=$(jq -r ".mcpServers.\"$server\".command // empty" "$SETTINGS_FILE")
            if [[ -n "$cmd" ]]; then
                if command -v "$cmd" &> /dev/null || [[ "$cmd" == "npx" ]] || [[ "$cmd" == "uvx" ]]; then
                    ((++healthy))
                else
                    ((++unhealthy))
                    warnings+=("⚠️  MCP server '$server' command '$cmd' not found")
                fi
            else
                ((++healthy))  # No command to check
            fi
            ;;
    esac
done

# Output warnings if any
if [[ ${#warnings[@]} -gt 0 ]]; then
    hook_section "MCP Server Health Check"
    for warning in "${warnings[@]}"; do
        hook_warning "${warning#⚠️  }"
    done
    hook_info "Healthy: $healthy | Unhealthy: $unhealthy"
    hook_warning "Some MCP features may be unavailable."
fi

exit 0
