#!/bin/bash
# Auto-Format Hook
# Event: PostToolUse (Edit|Write)
# Purpose: Automatically format files after edits using project-configured formatters
# Industry standard: Format-on-save behavior, fail silently to not block workflow
#
# Best practices followed:
# - Respects project-local tools over global (node_modules/.bin first)
# - Respects project config (biome.json takes precedence)
# - Skips vendor/generated directories
# - Silent by default, verbose with CLAUDE_HOOK_DEBUG=true
# - Never blocks workflow (always exits 0)

# Exit on error, undefined variables, and pipe failures
set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

# Get the edited file from tool input
TOOL_INPUT="$(cat)"
[[ -z "$TOOL_INPUT" ]] && exit 0

# Extract file path from JSON input
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

# Get project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(dirname "$FILE_PATH")}"

# Determine file extension
EXT="${FILE_PATH##*.}"
BASENAME=$(basename "$FILE_PATH")

# Skip files that shouldn't be formatted
case "$BASENAME" in
    *.min.js|*.min.css|*.lock|package-lock.json|yarn.lock|pnpm-lock.yaml)
        exit 0
        ;;
esac

# Skip generated/vendor directories
case "$FILE_PATH" in
    */node_modules/*|*/vendor/*|*/dist/*|*/build/*|*/.next/*|*/coverage/*)
        exit 0
        ;;
esac

# Track if we formatted
formatted=false
formatter_used=""

# ============================================
# JavaScript/TypeScript/JSON/CSS/HTML/Markdown
# ============================================
format_with_prettier() {
    # Check for prettier in project
    if [[ -f "$PROJECT_DIR/node_modules/.bin/prettier" ]]; then
        "$PROJECT_DIR/node_modules/.bin/prettier" --write "$FILE_PATH" 2>/dev/null && return 0
    fi
    # Check for global prettier
    if command -v prettier &>/dev/null; then
        prettier --write "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

format_with_biome() {
    if [[ -f "$PROJECT_DIR/node_modules/.bin/biome" ]]; then
        "$PROJECT_DIR/node_modules/.bin/biome" format --write "$FILE_PATH" 2>/dev/null && return 0
    fi
    if command -v biome &>/dev/null; then
        biome format --write "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Go
# ============================================
format_go() {
    if command -v gofmt &>/dev/null; then
        gofmt -w "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

format_go_imports() {
    if command -v goimports &>/dev/null; then
        goimports -w "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Python
# ============================================
format_python() {
    # Prefer ruff (faster), then black
    if command -v ruff &>/dev/null; then
        ruff format "$FILE_PATH" 2>/dev/null && return 0
    fi
    if command -v black &>/dev/null; then
        black --quiet "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Rust
# ============================================
format_rust() {
    if command -v rustfmt &>/dev/null; then
        rustfmt "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Shell
# ============================================
format_shell() {
    if command -v shfmt &>/dev/null; then
        shfmt -w "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# YAML
# ============================================
format_yaml() {
    if command -v prettier &>/dev/null; then
        prettier --write "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Format based on file type
# ============================================
case "$EXT" in
    js|jsx|ts|tsx|mjs|cjs)
        # Prefer biome if biome.json exists, else prettier
        if [[ -f "$PROJECT_DIR/biome.json" || -f "$PROJECT_DIR/biome.jsonc" ]]; then
            if format_with_biome; then formatted=true; formatter_used="biome"; fi
        else
            if format_with_prettier; then formatted=true; formatter_used="prettier"; fi
        fi
        ;;
    json)
        # Skip package-lock, etc (already handled above)
        if [[ -f "$PROJECT_DIR/biome.json" || -f "$PROJECT_DIR/biome.jsonc" ]]; then
            if format_with_biome; then formatted=true; formatter_used="biome"; fi
        else
            if format_with_prettier; then formatted=true; formatter_used="prettier"; fi
        fi
        ;;
    css|scss|less|html|vue|svelte)
        if format_with_prettier; then formatted=true; formatter_used="prettier"; fi
        ;;
    md|mdx)
        if format_with_prettier; then formatted=true; formatter_used="prettier"; fi
        ;;
    go)
        # goimports is preferred as it also formats + organizes imports
        if format_go_imports; then
            formatted=true
            formatter_used="goimports"
        elif format_go; then
            formatted=true
            formatter_used="gofmt"
        fi
        ;;
    py)
        if format_python; then formatted=true; formatter_used="ruff/black"; fi
        ;;
    rs)
        if format_rust; then formatted=true; formatter_used="rustfmt"; fi
        ;;
    sh|bash|zsh)
        if format_shell; then formatted=true; formatter_used="shfmt"; fi
        ;;
    yaml|yml)
        if format_yaml; then formatted=true; formatter_used="prettier"; fi
        ;;
esac

# Silent success - don't clutter output
# Only report if CLAUDE_HOOK_DEBUG is set
if [[ "${CLAUDE_HOOK_DEBUG:-}" == "true" && "$formatted" == "true" ]]; then
    echo "✨ Auto-formatted with $formatter_used: $(basename "$FILE_PATH")"
fi

exit 0
