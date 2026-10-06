#!/bin/bash
# =============================================================================
# Auto-Test Hook
# =============================================================================
# Event: PostToolUse (Edit|Write)
# Purpose: Run relevant tests after file edits
# Features:
#   - Detects edited file path from hook input
#   - Finds corresponding test file (*.test.ts, *.spec.ts, *_test.go)
#   - Runs test if found, or suggests running test suite
#   - Reports pass/fail in additionalContext
# =============================================================================

set -euo pipefail

# Read hook input from stdin
hook_data=$(cat)

# Extract file path from tool_input
file_path=$(echo "$hook_data" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# Exit if no file path
[[ -z "$file_path" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
context=""

# =============================================================================
# Skip Non-Source Files
# =============================================================================
case "$file_path" in
    *.md|*.json|*.yaml|*.yml|*.txt|*.lock|*.log|*.env*)
        exit 0
        ;;
esac

# =============================================================================
# Find Corresponding Test File
# =============================================================================
dir=$(dirname "$file_path")
base=$(basename "$file_path")
name="${base%.*}"
ext="${base##*.}"

test_file=""
test_patterns=()

case "$ext" in
    ts|tsx)
        test_patterns=(
            "$dir/$name.test.ts"
            "$dir/$name.test.tsx"
            "$dir/$name.spec.ts"
            "$dir/$name.spec.tsx"
            "$dir/__tests__/$name.test.ts"
            "$dir/__tests__/$name.test.tsx"
        )
        ;;
    js|jsx)
        test_patterns=(
            "$dir/$name.test.js"
            "$dir/$name.test.jsx"
            "$dir/$name.spec.js"
            "$dir/__tests__/$name.test.js"
        )
        ;;
    go)
        test_patterns=(
            "$dir/${name}_test.go"
        )
        ;;
    py)
        test_patterns=(
            "$dir/test_$name.py"
            "$dir/${name}_test.py"
            "$(dirname "$dir")/tests/test_$name.py"
        )
        ;;
esac

# Check if test file exists
for pattern in "${test_patterns[@]}"; do
    if [[ -f "$pattern" ]]; then
        test_file="$pattern"
        break
    fi
done

# =============================================================================
# Suggest Test Run
# =============================================================================
if [[ -n "$test_file" ]]; then
    context="Test file found: $test_file\n"

    # Suggest appropriate test command
    case "$ext" in
        ts|tsx|js|jsx)
            if [[ -f "$PROJECT_DIR/package.json" ]]; then
                if jq -e '.scripts.test' "$PROJECT_DIR/package.json" >/dev/null 2>&1; then
                    pkg_mgr="npm"
                    [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]] && pkg_mgr="pnpm"
                    [[ -f "$PROJECT_DIR/yarn.lock" ]] && pkg_mgr="yarn"
                    [[ -f "$PROJECT_DIR/bun.lockb" ]] && pkg_mgr="bun"

                    # Check for vitest vs jest
                    if jq -r '.devDependencies | keys[]' "$PROJECT_DIR/package.json" 2>/dev/null | grep -q "vitest"; then
                        context+="Run: $pkg_mgr run test -- $test_file\n"
                    else
                        context+="Run: $pkg_mgr test -- --testPathPattern=\"$name\"\n"
                    fi
                fi
            fi
            ;;
        go)
            context+="Run: go test -v -run \"$name\" $dir/...\n"
            ;;
        py)
            context+="Run: pytest $test_file -v\n"
            ;;
    esac
else
    # No test file found - only suggest if it's a significant file
    case "$file_path" in
        */components/*|*/hooks/*|*/utils/*|*/services/*|*/lib/*)
            context="No test file found for: $base\n"
            context+="Consider creating: ${name}.test.${ext}\n"
            ;;
    esac
fi

# =============================================================================
# Output
# =============================================================================
if [[ -n "$context" ]]; then
    echo -e "$context"
fi

exit 0
