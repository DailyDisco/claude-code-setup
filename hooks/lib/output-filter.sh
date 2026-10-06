#!/usr/bin/env bash
# =============================================================================
# Output Filter Library
# =============================================================================
# Purpose: Context-aware output filtering for hooks
# Usage: Source this file and use hook_output instead of echo
# Modes: minimal (default), full, silent
# =============================================================================

# Output mode from environment (default: minimal)
OUTPUT_MODE="${CLAUDE_OUTPUT_MODE:-minimal}"

# =============================================================================
# Main output function
# =============================================================================
hook_output() {
    local level="$1"  # info | warning | error | success
    shift
    local message="$*"

    case "$OUTPUT_MODE" in
        full)
            # Show everything with level prefix
            case "$level" in
                info)    echo "ℹ️  $message" ;;
                warning) echo "⚠️  $message" ;;
                error)   echo "❌ $message" ;;
                success) echo "✅ $message" ;;
                *)       echo "$message" ;;
            esac
            ;;
        minimal)
            # Only show warnings and errors
            case "$level" in
                warning) echo "⚠️  $message" ;;
                error)   echo "❌ $message" ;;
                success) echo "✅ $message" ;;
                # info is suppressed in minimal mode
            esac
            ;;
        silent)
            # Only show errors
            [[ "$level" == "error" ]] && echo "❌ $message"
            ;;
        *)
            # Unknown mode - default to minimal
            [[ "$level" != "info" ]] && echo "[$level] $message"
            ;;
    esac
}

# =============================================================================
# Convenience functions
# =============================================================================
hook_info() {
    hook_output info "$@"
}

hook_warning() {
    hook_output warning "$@"
}

hook_error() {
    hook_output error "$@"
}

hook_success() {
    hook_output success "$@"
}

# =============================================================================
# Section header (always shown, but minimal in minimal mode)
# =============================================================================
hook_section() {
    local title="$1"

    case "$OUTPUT_MODE" in
        full)
            echo ""
            echo "═══════════════════════════════════════════════════════════"
            echo "  $title"
            echo "═══════════════════════════════════════════════════════════"
            echo ""
            ;;
        minimal|silent)
            # Just the title, no decoration
            echo "$title"
            ;;
    esac
}

# =============================================================================
# Conditional output (only in full mode)
# =============================================================================
hook_debug() {
    [[ "$OUTPUT_MODE" == "full" ]] && echo "🔍 DEBUG: $*"
}

# Export functions for use in hooks
export -f hook_output
export -f hook_info
export -f hook_warning
export -f hook_error
export -f hook_success
export -f hook_section
export -f hook_debug
export OUTPUT_MODE
