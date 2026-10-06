#!/bin/bash
# Import Fixer Hook
# Event: PostToolUse (Edit|Write)
# Purpose: Automatically fix missing imports after code edits
# Industry standard: IDE-like auto-import behavior
#
# Best practices followed:
# - Respects project-local tools over global
# - Uses language-specific best tools (goimports for Go, isort/ruff for Python)
# - Skips vendor/generated directories
# - Silent by default, verbose with CLAUDE_HOOK_DEBUG=true
# - Never blocks workflow (always exits 0)

# Don't use set -e because fixer failures are expected and handled
set -uo pipefail
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

# Skip non-code files and generated directories
case "$FILE_PATH" in
    */node_modules/*|*/vendor/*|*/dist/*|*/build/*|*/.next/*|*/coverage/*|*.min.*)
        exit 0
        ;;
esac

# Track results
fixed=false
fixer_used=""

# ============================================
# TypeScript/JavaScript - ESLint auto-fix imports
# ============================================
fix_ts_imports() {
    local eslint_bin=""

    # Find eslint
    if [[ -f "$PROJECT_DIR/node_modules/.bin/eslint" ]]; then
        eslint_bin="$PROJECT_DIR/node_modules/.bin/eslint"
    elif command -v eslint &>/dev/null; then
        eslint_bin="eslint"
    else
        return 1
    fi

    # Check for eslint-plugin-import or similar
    # Run with --fix to auto-fix import issues
    # Only fix import-related rules to avoid changing other code
    $eslint_bin --fix \
        --rule 'import/order: error' \
        --rule 'import/no-duplicates: error' \
        --rule '@typescript-eslint/no-unused-vars: off' \
        "$FILE_PATH" 2>/dev/null || true

    return 0
}

# Alternative: Use TypeScript's organize imports via ts-prune or similar
fix_ts_imports_tsc() {
    # If project has typescript, we can use the language service
    # This is a lighter approach using editor-style import organization
    if [[ -f "$PROJECT_DIR/node_modules/.bin/tsc" ]]; then
        # TypeScript doesn't have a direct CLI for import fixing
        # But we can use tools like organize-imports-cli if available
        if [[ -f "$PROJECT_DIR/node_modules/.bin/organize-imports-cli" ]]; then
            "$PROJECT_DIR/node_modules/.bin/organize-imports-cli" "$FILE_PATH" 2>/dev/null && return 0
        fi
    fi
    return 1
}

# ============================================
# Go - goimports handles this perfectly
# ============================================
fix_go_imports() {
    if command -v goimports &>/dev/null; then
        goimports -w "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Python - isort for import sorting, autoflake for unused
# ============================================
fix_python_imports() {
    local fixed_something=false

    # isort for sorting imports
    if command -v isort &>/dev/null; then
        isort --quiet "$FILE_PATH" 2>/dev/null && fixed_something=true
    fi

    # ruff can also fix import issues
    if command -v ruff &>/dev/null; then
        ruff check --fix --select=I,F401 "$FILE_PATH" 2>/dev/null && fixed_something=true
    fi

    # autoflake removes unused imports
    if command -v autoflake &>/dev/null; then
        autoflake --in-place --remove-all-unused-imports "$FILE_PATH" 2>/dev/null && fixed_something=true
    fi

    $fixed_something && return 0
    return 1
}

# ============================================
# Rust - rustfmt handles use statements
# ============================================
fix_rust_imports() {
    # rustfmt with imports_granularity option
    if command -v rustfmt &>/dev/null; then
        rustfmt --config imports_granularity=Crate "$FILE_PATH" 2>/dev/null && return 0
    fi
    return 1
}

# ============================================
# Fix based on file type
# ============================================
case "$EXT" in
    ts|tsx)
        if fix_ts_imports_tsc; then
            fixed=true
            fixer_used="organize-imports"
        elif fix_ts_imports; then
            fixed=true
            fixer_used="eslint"
        fi
        ;;
    js|jsx|mjs|cjs)
        if fix_ts_imports; then fixed=true; fixer_used="eslint"; fi
        ;;
    go)
        if fix_go_imports; then fixed=true; fixer_used="goimports"; fi
        ;;
    py)
        if fix_python_imports; then fixed=true; fixer_used="isort/ruff"; fi
        ;;
    rs)
        if fix_rust_imports; then fixed=true; fixer_used="rustfmt"; fi
        ;;
esac

# Silent success - only report in debug mode
if [[ "${CLAUDE_HOOK_DEBUG:-}" == "true" && "$fixed" == "true" ]]; then
    echo "📦 Fixed imports with $fixer_used: $(basename "$FILE_PATH")"
fi

exit 0
