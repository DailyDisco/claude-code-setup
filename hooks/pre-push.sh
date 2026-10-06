#!/usr/bin/env bash
# Pre-push validation hook
# Runs full validation before allowing push to remote
# Stricter checks for protected branches (main, master, production)

set -euo pipefail

# Source metrics if available
METRICS_LIB="${HOME}/.claude/hooks/lib/metrics.sh"
[[ -f "$METRICS_LIB" ]] && source "$METRICS_LIB"

# Only run on git push commands
TOOL_INPUT="${TOOL_INPUT:-}"
if [[ ! "$TOOL_INPUT" =~ git\ push ]]; then
    exit 0
fi

# Extract target branch/remote from command
TARGET_BRANCH=""
if [[ "$TOOL_INPUT" =~ origin[[:space:]]+([a-zA-Z0-9_/-]+) ]]; then
    TARGET_BRANCH="${BASH_REMATCH[1]}"
elif [[ "$TOOL_INPUT" =~ git\ push$ ]]; then
    # Pushing current branch
    TARGET_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

# Check if pushing to protected branch
PROTECTED_BRANCHES="main master production release"
IS_PROTECTED=false
for branch in $PROTECTED_BRANCHES; do
    if [[ "$TARGET_BRANCH" == "$branch" ]]; then
        IS_PROTECTED=true
        break
    fi
done

# Detect project type
detect_project_type() {
    if [[ -f "package.json" ]]; then
        echo "node"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    else
        echo "unknown"
    fi
}

PROJECT_TYPE=$(detect_project_type)
ERRORS=()

log() {
    echo "[pre-push] $*" >&2
}

run_check() {
    local name="$1"
    local cmd="$2"

    log "Running: $name"
    if ! eval "$cmd" >/dev/null 2>&1; then
        ERRORS+=("$name failed")
        return 1
    fi
    return 0
}

# Run type checking
run_typecheck() {
    case "$PROJECT_TYPE" in
        node)
            if [[ -f "tsconfig.json" ]]; then
                if command -v tsc >/dev/null 2>&1; then
                    run_check "TypeScript" "npx tsc --noEmit"
                elif [[ -f "node_modules/.bin/tsc" ]]; then
                    run_check "TypeScript" "node_modules/.bin/tsc --noEmit"
                fi
            fi
            ;;
        python)
            if command -v pyright >/dev/null 2>&1; then
                run_check "Pyright" "pyright"
            elif command -v mypy >/dev/null 2>&1; then
                run_check "Mypy" "mypy ."
            fi
            ;;
        go)
            run_check "Go vet" "go vet ./..."
            ;;
        rust)
            run_check "Cargo check" "cargo check"
            ;;
    esac
}

# Run tests
run_tests() {
    case "$PROJECT_TYPE" in
        node)
            if [[ -f "package.json" ]]; then
                if grep -q '"test"' package.json 2>/dev/null; then
                    run_check "Tests" "npm test"
                fi
            fi
            ;;
        go)
            run_check "Tests" "go test ./..."
            ;;
        rust)
            run_check "Tests" "cargo test"
            ;;
        python)
            if command -v pytest >/dev/null 2>&1; then
                run_check "Tests" "pytest"
            fi
            ;;
    esac
}

# Run build
run_build() {
    case "$PROJECT_TYPE" in
        node)
            if [[ -f "package.json" ]] && grep -q '"build"' package.json 2>/dev/null; then
                run_check "Build" "npm run build"
            fi
            ;;
        go)
            run_check "Build" "go build ./..."
            ;;
        rust)
            run_check "Build" "cargo build"
            ;;
    esac
}

# Run lint (for protected branches)
run_lint() {
    case "$PROJECT_TYPE" in
        node)
            if [[ -f "package.json" ]] && grep -q '"lint"' package.json 2>/dev/null; then
                run_check "Lint" "npm run lint"
            fi
            ;;
        go)
            if command -v golangci-lint >/dev/null 2>&1; then
                run_check "Lint" "golangci-lint run"
            fi
            ;;
        rust)
            run_check "Clippy" "cargo clippy -- -D warnings"
            ;;
        python)
            if command -v ruff >/dev/null 2>&1; then
                run_check "Ruff" "ruff check ."
            fi
            ;;
    esac
}

# Main validation
log "Validating before push to ${TARGET_BRANCH:-current branch}..."

if [[ "$IS_PROTECTED" == "true" ]]; then
    log "Protected branch detected - running full validation"
    run_typecheck
    run_tests
    run_build
    run_lint
else
    # Standard push - just typecheck and tests
    run_typecheck
    run_tests
fi

# Report results
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo ""
    echo "PUSH BLOCKED - Fix these issues first:"
    for err in "${ERRORS[@]}"; do
        echo "  - $err"
    done
    echo ""
    exit 1
fi

log "All checks passed"
exit 0
