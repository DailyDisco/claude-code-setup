#!/bin/bash
# =============================================================================
# Type Check Hook (Lightweight)
# =============================================================================
# Event: PreToolUse (Bash - git commit)
# Purpose: Fast TypeScript/type check before commits
# Note: Runs before build-test-gate for quick fail-fast feedback
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only gate git commit commands
[[ "$tool_name" != "Bash" ]] && exit 0
echo "$command" | grep -qE 'git\s+commit' || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# =============================================================================
# TypeScript Projects
# =============================================================================
if [[ -f "tsconfig.json" ]]; then
    # Check for staged TypeScript files
    TS_FILES=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(ts|tsx)$' || true)

    if [[ -z "$TS_FILES" ]]; then
        exit 0  # No TS files staged, skip
    fi

    # Detect package manager
    PKG_MGR="npx"
    [[ -f "pnpm-lock.yaml" ]] && PKG_MGR="pnpm exec"
    [[ -f "bun.lockb" ]] && PKG_MGR="bunx"

    # Run tsc --noEmit for type checking only (faster than full build)
    echo "Type-checking staged TypeScript files..."

    if ! $PKG_MGR tsc --noEmit 2>&1; then
        echo ""
        echo "TypeScript errors detected. Fix before committing." >&2
        exit 2
    fi

    echo "TypeScript check passed"
fi

# =============================================================================
# Python Type Checking
# =============================================================================
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    PY_FILES=$(git diff --cached --name-only 2>/dev/null | grep '\.py$' || true)

    if [[ -z "$PY_FILES" ]]; then
        exit 0  # No Python files staged
    fi

    # Check with pyright (preferred) or mypy
    if command -v pyright &> /dev/null; then
        echo "Type-checking staged Python files with pyright..."
        if ! echo "$PY_FILES" | xargs pyright 2>&1; then
            echo "Python type errors detected. Fix before committing." >&2
            exit 2
        fi
        echo "Pyright check passed"
    elif command -v mypy &> /dev/null; then
        echo "Type-checking staged Python files with mypy..."
        if ! echo "$PY_FILES" | xargs mypy --ignore-missing-imports 2>&1; then
            echo "Python type errors detected. Fix before committing." >&2
            exit 2
        fi
        echo "Mypy check passed"
    fi
fi

exit 0
