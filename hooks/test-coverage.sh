#!/bin/bash
# =============================================================================
# TIER 2: Test Coverage Expectation Hook
# =============================================================================
# Event: PostToolUse (Write on source files)
# Purpose: Reminds to add tests for new features
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only check Write operations (new files)
[[ "$tool_name" != "Write" ]] && exit 0

# Skip test files themselves
if echo "$file_path" | grep -qE '\.(test|spec)\.(js|ts|jsx|tsx|py|go|rs)$'; then
    exit 0
fi

# Skip non-source files
if ! echo "$file_path" | grep -qE '\.(js|ts|jsx|tsx|py|go|rs|java|kt)$'; then
    exit 0
fi

# Skip config/setup files
if echo "$file_path" | grep -qiE '(config|setup|index|types|interfaces|constants)'; then
    exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
basename=$(basename "$file_path")
name="${basename%.*}"
ext="${basename##*.}"

# Determine test file patterns
test_patterns=()
case "$ext" in
    js|jsx)
        test_patterns+=("$name.test.js" "$name.spec.js" "$name.test.jsx")
        ;;
    ts|tsx)
        test_patterns+=("$name.test.ts" "$name.spec.ts" "$name.test.tsx")
        ;;
    py)
        test_patterns+=("test_$name.py" "${name}_test.py")
        ;;
    go)
        test_patterns+=("${name}_test.go")
        ;;
    rs)
        test_patterns+=("${name}_test.rs")
        ;;
esac

# Check if corresponding test exists
test_exists=false
for pattern in "${test_patterns[@]}"; do
    if find "$PROJECT_DIR" -name "$pattern" -type f 2>/dev/null | grep -q .; then
        test_exists=true
        break
    fi
done

if [[ "$test_exists" == "false" ]]; then
    echo "New source file: $file_path"
    echo ""
    echo "Consider adding tests:"
    echo "  - Unit tests for core logic"
    echo "  - Edge case coverage"
    echo "  - Integration tests if needed"
fi

exit 0
