#!/bin/bash
# =============================================================================
# Auto Test Generation Prompt Hook
# =============================================================================
# Event: PostToolUse (Edit|Write on source files)
# Purpose: Instructs Claude to generate tests for code lacking coverage
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only check Edit and Write operations
[[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]] && exit 0
[[ -z "$file_path" ]] && exit 0

# Skip test files themselves
if echo "$file_path" | grep -qE '\.(test|spec)\.(js|ts|jsx|tsx|py|go|rs)$|_test\.(go|py|rs)$|test_.*\.py$'; then
    exit 0
fi

# Skip non-source files
if ! echo "$file_path" | grep -qE '\.(js|ts|jsx|tsx|py|go|rs|java|kt)$'; then
    exit 0
fi

# Skip files that typically don't need tests
if echo "$file_path" | grep -qiE '(config|setup|index|types|interfaces|constants|\.d\.ts|mock|fixture|seed|migration)'; then
    exit 0
fi

# Skip small utility files and generated code
if echo "$file_path" | grep -qiE '(generated|\.gen\.|vendor/|node_modules/|dist/|build/)'; then
    exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
basename=$(basename "$file_path")
name="${basename%.*}"
ext="${basename##*.}"

# Determine test file patterns based on language
test_patterns=()
test_dirs=("" "tests/" "test/" "__tests__/" "spec/")

case "$ext" in
    js|jsx)
        test_patterns+=("$name.test.js" "$name.spec.js" "$name.test.jsx" "$name.spec.jsx")
        ;;
    ts|tsx)
        test_patterns+=("$name.test.ts" "$name.spec.ts" "$name.test.tsx" "$name.spec.tsx")
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
    java|kt)
        test_patterns+=("${name}Test.java" "${name}Test.kt" "${name}Spec.java" "${name}Spec.kt")
        ;;
esac

# Check if corresponding test exists anywhere in project
test_exists=false
for pattern in "${test_patterns[@]}"; do
    if find "$PROJECT_DIR" \( -name node_modules -o -name .git -o -name dist -o -name build -o -name vendor -o -name .next -o -name coverage \) -prune -o -name "$pattern" -type f -print 2>/dev/null | grep -q .; then
        test_exists=true
        break
    fi
done

# Also check for test in same directory with different naming
dir=$(dirname "$file_path")
for pattern in "${test_patterns[@]}"; do
    if [[ -f "$dir/$pattern" ]]; then
        test_exists=true
        break
    fi
done

# If no tests exist, output prompt instruction
if [[ "$test_exists" == "false" ]]; then
    # Determine the likely test path
    rel_path="${file_path#$PROJECT_DIR/}"
    rel_dir=$(dirname "$rel_path")

    case "$ext" in
        ts|tsx|js|jsx)
            suggested_test="$rel_dir/$name.test.$ext"
            ;;
        py)
            suggested_test="tests/test_$name.py"
            ;;
        go)
            suggested_test="$rel_dir/${name}_test.go"
            ;;
        *)
            suggested_test="$rel_dir/${name}_test.$ext"
            ;;
    esac

    cat << EOF

📝 **Test Coverage Required**

The file \`$rel_path\` was modified but has no corresponding test file.

**Action:** Generate tests for this file:
- Create \`$suggested_test\` (or appropriate location)
- Cover the main functions/methods
- Include edge cases and error handling
- Follow existing test patterns in the project

If this file genuinely doesn't need tests (pure types, simple re-exports), acknowledge and continue.
EOF
fi

exit 0
