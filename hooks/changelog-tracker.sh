#!/bin/bash
# =============================================================================
# Changelog Tracker Hook
# =============================================================================
# Event: PostToolUse (Edit|Write)
# Purpose: Track file changes for release notes generation
# Features:
#   - Logs file path, change type, timestamp
#   - Appends to ~/.claude/state/changelog-draft.md
#   - Groups by date and category (feat/fix/refactor/docs)
#   - /release skill can consume this for changelog generation
# =============================================================================

set -euo pipefail

# Read hook input from stdin
hook_data=$(cat)

# Extract file path and tool name
file_path=$(echo "$hook_data" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
tool_name=$(echo "$hook_data" | jq -r '.tool_name // empty' 2>/dev/null)

# Exit if no file path
[[ -z "$file_path" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="${HOME}/.claude/state"
CHANGELOG_FILE="${STATE_DIR}/changelog-draft.md"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# =============================================================================
# Determine Change Category
# =============================================================================
category=""
case "$file_path" in
    *.test.*|*.spec.*|*_test.*|*/tests/*|*/test/*)
        category="test"
        ;;
    *.md|README*|CHANGELOG*|docs/*|*.txt)
        category="docs"
        ;;
    *.css|*.scss|*.sass|*.less|*/styles/*)
        category="style"
        ;;
    migrations/*|*.sql|schema.*)
        category="db"
        ;;
    Dockerfile*|docker-compose*|*.tf|*.yaml|*.yml|.github/*)
        category="infra"
        ;;
    package.json|go.mod|Cargo.toml|pyproject.toml|requirements.txt)
        category="deps"
        ;;
    *.config.*|tsconfig*|eslint*|prettier*|.env*)
        category="config"
        ;;
    *)
        # Default to feat for source files
        category="feat"
        ;;
esac

# =============================================================================
# Determine Change Type
# =============================================================================
change_type="modified"
if [[ "$tool_name" == "Write" ]]; then
    # Check if file existed before (rough heuristic)
    if ! git ls-files --error-unmatch "$file_path" >/dev/null 2>&1; then
        change_type="added"
    fi
fi

# =============================================================================
# Log Change
# =============================================================================
timestamp=$(date +"%Y-%m-%d %H:%M")
date_header=$(date +"%Y-%m-%d")
relative_path="${file_path#$PROJECT_DIR/}"

# Create file with header if it doesn't exist
if [[ ! -f "$CHANGELOG_FILE" ]]; then
    cat > "$CHANGELOG_FILE" << 'EOF'
# Changelog Draft

Auto-tracked changes for release notes generation.
Use `/release` skill to generate formatted changelog.

---

EOF
fi

# Check if today's section exists, add if not
if ! grep -q "^## $date_header" "$CHANGELOG_FILE" 2>/dev/null; then
    echo -e "\n## $date_header\n" >> "$CHANGELOG_FILE"
fi

# Append change entry
echo "- [$category] $change_type: \`$relative_path\`" >> "$CHANGELOG_FILE"

# =============================================================================
# Output (silent - no output needed for tracking)
# =============================================================================
exit 0
