#!/usr/bin/env bash
# =============================================================================
# Lint Staged Files Hook
# =============================================================================
# Event: PreToolUse (Bash - git commit)
# Purpose: Run linters on staged files before commit
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

# Ensure common paths are available
export PATH="$HOME/.nvm/versions/node/$(ls -1 $HOME/.nvm/versions/node 2>/dev/null | tail -1)/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/go/bin:$HOME/go/bin:$PATH" 2>/dev/null || true

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only run for git commit
[[ "$tool_name" != "Bash" ]] && exit 0
echo "$command" | grep -qE 'git\s+commit' || exit 0

# Allow bypass
echo "$command" | grep -q '\-\-no-verify' && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

if [[ -z "$STAGED_FILES" ]]; then
    exit 0
fi

errors=""

# =============================================================================
# TypeScript/JavaScript Linting
# =============================================================================
TS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' || true)

if [[ -n "$TS_FILES" ]] && [[ -f "package.json" ]]; then
    # Detect linter
    if [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f "eslint.config.js" ]] || jq -e '.eslintConfig' package.json > /dev/null 2>&1; then
        # Check if eslint is available
        if command -v eslint &> /dev/null || jq -e '.devDependencies.eslint' package.json > /dev/null 2>&1; then
            echo "Running ESLint on staged files..."

            # Create temp file with staged files
            FILE_LIST=$(echo "$TS_FILES" | tr '\n' ' ')

            if npx eslint --max-warnings=0 $FILE_LIST 2>&1; then
                echo "✓ ESLint passed"
            else
                errors+="ESLint failed on staged files.\n"
            fi
        fi
    fi

    # Check for Prettier
    if [[ -f ".prettierrc" ]] || [[ -f ".prettierrc.json" ]] || [[ -f "prettier.config.js" ]]; then
        if command -v prettier &> /dev/null || jq -e '.devDependencies.prettier' package.json > /dev/null 2>&1; then
            echo "Checking Prettier formatting..."

            FILE_LIST=$(echo "$TS_FILES" | tr '\n' ' ')

            if npx prettier --check $FILE_LIST 2>&1; then
                echo "✓ Prettier check passed"
            else
                echo "⚠️  Prettier formatting issues detected (non-blocking)"
                echo "   Run: npx prettier --write <files>"
            fi
        fi
    fi
fi

# =============================================================================
# Go Linting
# =============================================================================
GO_FILES=$(echo "$STAGED_FILES" | grep '\.go$' || true)

if [[ -n "$GO_FILES" ]] && [[ -f "go.mod" ]]; then
    echo "Running Go linting on staged files..."

    # Get unique directories
    GO_DIRS=$(echo "$GO_FILES" | xargs -I{} dirname {} | sort -u | sed 's|^|./|' | tr '\n' ' ')

    # Run go vet
    if go vet $GO_DIRS 2>&1; then
        echo "✓ go vet passed"
    else
        errors+="go vet failed.\n"
    fi

    # Run golangci-lint if available
    if command -v golangci-lint &> /dev/null; then
        if golangci-lint run --new-from-rev=HEAD $GO_DIRS 2>&1; then
            echo "✓ golangci-lint passed"
        else
            errors+="golangci-lint failed.\n"
        fi
    fi
fi

# =============================================================================
# Python Linting
# =============================================================================
PY_FILES=$(echo "$STAGED_FILES" | grep '\.py$' || true)

if [[ -n "$PY_FILES" ]]; then
    FILE_LIST=$(echo "$PY_FILES" | tr '\n' ' ')

    # Run ruff if available
    if command -v ruff &> /dev/null; then
        echo "Running Ruff on staged files..."

        if ruff check $FILE_LIST 2>&1; then
            echo "✓ Ruff passed"
        else
            errors+="Ruff linting failed.\n"
        fi
    fi

    # Run mypy if available and configured
    if command -v mypy &> /dev/null && [[ -f "mypy.ini" || -f "pyproject.toml" ]]; then
        echo "Running mypy on staged files..."

        if mypy $FILE_LIST --ignore-missing-imports 2>&1; then
            echo "✓ mypy passed"
        else
            echo "⚠️  mypy issues detected (non-blocking)"
        fi
    fi
fi

# =============================================================================
# Results
# =============================================================================
if [[ -n "$errors" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ Lint Staged Failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$errors"
    echo "Fix issues and try again, or use --no-verify to bypass."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 2
fi

exit 0
