#!/bin/bash
# =============================================================================
# TIER 1: Smart Build + Test Gate Hook
# =============================================================================
# Event: PreToolUse (Bash - git commit)
# Purpose: Ensures build and tests pass before allowing commits
# Features:
#   - Only runs tests for changed files (when possible)
#   - Caches last successful build hash
#   - Runs checks in parallel
# =============================================================================

set -euo pipefail

# Ensure common paths are available (npm, node, go, etc.)
export PATH="$HOME/.nvm/versions/node/$(ls -1 $HOME/.nvm/versions/node 2>/dev/null | tail -1)/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/go/bin:$HOME/go/bin:$PATH" 2>/dev/null || true
source "${HOME}/.claude/hooks/lib/metrics.sh"
source "${HOME}/.claude/hooks/lib/state.sh" 2>/dev/null || true

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only gate git commit commands
[[ "$tool_name" != "Bash" ]] && exit 0
echo "$command" | grep -qE 'git\s+commit' || exit 0

# Allow bypass with --no-verify flag
echo "$command" | grep -q '\-\-no-verify' && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

CACHE_DIR="$HOME/.claude/cache"
mkdir -p "$CACHE_DIR"

# Get current state hash (staged files + their content)
get_state_hash() {
    (git diff --cached --name-only 2>/dev/null | sort | xargs -I{} sh -c 'echo {} && cat "{}" 2>/dev/null' | md5sum | cut -d' ' -f1) || echo "no-cache"
}

# Check if we can skip based on cache
CACHE_FILE="$CACHE_DIR/build-gate-$(echo "$PROJECT_DIR" | md5sum | cut -d' ' -f1)"
CURRENT_HASH=$(get_state_hash)

if [[ -f "$CACHE_FILE" ]] && [[ "$(cat "$CACHE_FILE" 2>/dev/null)" == "$CURRENT_HASH" ]]; then
    echo "Build/test cache hit - no changes since last successful check"
    exit 0
fi

# Get changed files for targeted testing
CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)
CHANGED_SRC_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|jsx|ts|tsx|py|go|rs)$' || true)

# Temp files for parallel execution results
RESULT_DIR=$(mktemp -d)
trap "rm -rf $RESULT_DIR" EXIT

# Run check in background, save result
run_check() {
    local name="$1"
    local cmd="$2"
    local result_file="$RESULT_DIR/$name"

    if eval "$cmd" > "$result_file.log" 2>&1; then
        echo "pass" > "$result_file"
    else
        echo "fail" > "$result_file"
    fi
}

# =============================================================================
# Node.js projects
# =============================================================================
if [[ -f "package.json" ]]; then
    # Detect package manager
    PKG_MGR="npm"
    [[ -f "pnpm-lock.yaml" ]] && PKG_MGR="pnpm"
    [[ -f "yarn.lock" ]] && PKG_MGR="yarn"
    [[ -f "bun.lockb" ]] && PKG_MGR="bun"

    # Type check (parallel)
    if jq -e '.scripts.typecheck' package.json > /dev/null 2>&1; then
        run_check "typecheck" "$PKG_MGR run typecheck" &
    elif jq -e '.scripts["type-check"]' package.json > /dev/null 2>&1; then
        run_check "typecheck" "$PKG_MGR run type-check" &
    fi

    # Build (parallel)
    if jq -e '.scripts.build' package.json > /dev/null 2>&1; then
        run_check "build" "$PKG_MGR run build" &
    fi

    # Lint - only changed files if possible
    if jq -e '.scripts.lint' package.json > /dev/null 2>&1; then
        if [[ -n "$CHANGED_SRC_FILES" ]] && command -v eslint &> /dev/null; then
            run_check "lint" "echo '$CHANGED_SRC_FILES' | tr '\n' ' ' | xargs eslint --max-warnings=0 2>/dev/null || $PKG_MGR run lint" &
        else
            run_check "lint" "$PKG_MGR run lint" &
        fi
    fi

    # Tests - run only changed if test runner supports it
    if jq -e '.scripts.test' package.json > /dev/null 2>&1; then
        if [[ -n "$CHANGED_SRC_FILES" ]]; then
            if jq -e '.devDependencies.vitest // .dependencies.vitest' package.json > /dev/null 2>&1; then
                run_check "test" "$PKG_MGR run test -- --changed --passWithNoTests 2>/dev/null || $PKG_MGR run test" &
            elif jq -e '.devDependencies.jest // .dependencies.jest' package.json > /dev/null 2>&1; then
                run_check "test" "$PKG_MGR run test -- --onlyChanged --passWithNoTests 2>/dev/null || $PKG_MGR run test" &
            else
                run_check "test" "$PKG_MGR run test" &
            fi
        else
            echo "No source files changed, skipping tests"
            echo "pass" > "$RESULT_DIR/test"
        fi
    fi
fi

# =============================================================================
# Go projects
# =============================================================================
if [[ -f "go.mod" ]]; then
    run_check "go_build" "go build ./..." &

    # Test only changed packages
    if [[ -n "$CHANGED_SRC_FILES" ]]; then
        CHANGED_PACKAGES=$(echo "$CHANGED_SRC_FILES" | grep '\.go$' | xargs -I{} dirname {} 2>/dev/null | sort -u | sed 's|^|./|' | tr '\n' ' ' || true)
        if [[ -n "$CHANGED_PACKAGES" ]]; then
            run_check "go_test" "go test $CHANGED_PACKAGES" &
        else
            run_check "go_test" "go test ./..." &
        fi
    else
        run_check "go_test" "go test ./..." &
    fi

    # Lint only new changes
    if command -v golangci-lint &> /dev/null; then
        run_check "go_lint" "golangci-lint run --new-from-rev=HEAD~1 2>/dev/null || golangci-lint run" &
    fi
fi

# =============================================================================
# Rust projects
# =============================================================================
if [[ -f "Cargo.toml" ]]; then
    run_check "cargo_build" "cargo build" &
    run_check "cargo_test" "cargo test" &
    if command -v cargo-clippy &> /dev/null; then
        run_check "cargo_clippy" "cargo clippy --all-targets -- -D warnings" &
    fi
fi

# =============================================================================
# Python projects
# =============================================================================
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    if command -v pytest &> /dev/null; then
        # Use testmon if available for incremental testing
        if python -c "import pytest_testmon" 2>/dev/null; then
            run_check "pytest" "pytest --testmon" &
        else
            run_check "pytest" "pytest" &
        fi
    fi

    if command -v ruff &> /dev/null; then
        if [[ -n "$CHANGED_SRC_FILES" ]]; then
            PY_FILES=$(echo "$CHANGED_SRC_FILES" | grep '\.py$' | tr '\n' ' ' || true)
            [[ -n "$PY_FILES" ]] && run_check "ruff" "ruff check $PY_FILES" &
        else
            run_check "ruff" "ruff check ." &
        fi
    fi

    if command -v mypy &> /dev/null; then
        run_check "mypy" "mypy . --ignore-missing-imports" &
    fi
fi

# =============================================================================
# Wait and collect results
# =============================================================================
wait

errors=""
for result_file in "$RESULT_DIR"/*.log; do
    [[ -f "$result_file" ]] || continue
    name=$(basename "$result_file" .log)
    status_file="$RESULT_DIR/$name"

    if [[ -f "$status_file" ]] && [[ "$(cat "$status_file")" == "fail" ]]; then
        errors+="$name failed:\n$(tail -30 "$result_file")\n\n"
    fi
done

if [[ -n "$errors" ]]; then
    echo -e "Build/Test Gate Failed:\n$errors" >&2
    # Update cross-hook state
    set_state "last_build_status" "fail" 2>/dev/null || true
    set_state "last_build_time" "$(date -Iseconds)" 2>/dev/null || true
    exit 2
fi

# Cache successful state
echo "$CURRENT_HASH" > "$CACHE_FILE"

# Update cross-hook state for other hooks to read
set_state "last_build_status" "pass" 2>/dev/null || true
set_state "last_build_time" "$(date -Iseconds)" 2>/dev/null || true
set_state "last_test_status" "pass" 2>/dev/null || true

echo "All checks passed (parallel execution)"
exit 0
