#!/bin/bash
# =============================================================================
# Context Injector Hook
# =============================================================================
# Event: SessionStart
# Purpose: Auto-load relevant rules from ~/.claude/rules/ based on file patterns
# Features:
#   - Scans repo for file types (.tsx, .go, .py, etc.)
#   - Loads matching language/framework rules
#   - Injects as additionalContext for session
#   - Works with repo-scan.sh detection
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/output-filter.sh" 2>/dev/null || true

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RULES_DIR="${HOME}/.claude/rules"
context=""

# Skip if not in a project directory or rules don't exist
[[ ! -d "$PROJECT_DIR" ]] && exit 0
[[ ! -d "$RULES_DIR" ]] && exit 0

# =============================================================================
# Detect File Patterns and Load Corresponding Rules (with Caching)
# =============================================================================
CACHE_DIR="$HOME/.claude/cache/context-injector"
mkdir -p "$CACHE_DIR"

# Cache TTL: 5 minutes (can be overridden with CLAUDE_CACHE_TTL)
CACHE_TTL="${CLAUDE_CACHE_TTL:-300}"

# Generate cache key from project path + modification time
get_cache_key() {
    local proj_hash=$(echo "$PROJECT_DIR" | md5sum | cut -d' ' -f1 | cut -c1-12)
    # Check if any files have been modified since last cache
    local mod_count=$(find "$PROJECT_DIR" -maxdepth 2 -type f -newer "$CACHE_DIR/.cache-$proj_hash" 2>/dev/null | wc -l)
    echo "${proj_hash}-${mod_count}"
}

CACHE_KEY=$(get_cache_key)
CACHE_FILE="$CACHE_DIR/rules-$CACHE_KEY"

# Check cache validity (time-based + file-modification based)
if [[ -f "$CACHE_FILE" ]] && [[ "$CACHE_TTL" -gt 0 ]]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [[ $cache_age -lt $CACHE_TTL ]]; then
        # Load from cache
        source "$CACHE_FILE"
        if [[ -n "$rules_loaded" ]]; then
            hook_info "Loaded rules for this session: $rules_loaded"
            hook_info "See ~/.claude/rules/ for detailed guidelines."
        fi
        exit 0
    fi
fi

# Cache miss or expired - perform detection
rules_loaded=""

# Single find with all file patterns (much faster than 6 sequential finds)
file_types=$(timeout 2 find "$PROJECT_DIR" -maxdepth 3 -type f \( \
    -name "*.ts" -o -name "*.tsx" -o -name "*.jsx" -o \
    -name "*.go" -o -name "*.py" \
\) -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/.git/*" 2>/dev/null || true)

# Pattern matching (fast - no I/O, just string matching)
[[ "$file_types" =~ \.tsx? ]] && [[ -f "$RULES_DIR/typescript.md" ]] && rules_loaded+="typescript "
[[ "$file_types" =~ \.(tsx|jsx) ]] && [[ -f "$RULES_DIR/react.md" ]] && rules_loaded+="react "
[[ "$file_types" =~ \.go ]] && [[ -f "$RULES_DIR/go.md" ]] && rules_loaded+="go "
[[ "$file_types" =~ \.py ]] && [[ -f "$RULES_DIR/python.md" ]] && rules_loaded+="python "

# Docker
if [[ -f "$PROJECT_DIR/Dockerfile" ]] || [[ -f "$PROJECT_DIR/docker-compose.yml" ]]; then
    [[ -f "$RULES_DIR/docker.md" ]] && rules_loaded+="docker "
fi

# Terraform (with timeout)
if timeout 2 find "$PROJECT_DIR" -maxdepth 2 -name "*.tf" 2>/dev/null | head -1 | grep -q . 2>/dev/null; then
    [[ -f "$RULES_DIR/docker.md" ]] && rules_loaded+="infra "
fi

# Database (migrations, schema files)
if [[ -d "$PROJECT_DIR/migrations" ]] || [[ -d "$PROJECT_DIR/prisma" ]] || [[ -f "$PROJECT_DIR/schema.prisma" ]]; then
    [[ -f "$RULES_DIR/database.md" ]] && rules_loaded+="database "
fi

# API routes
if [[ -d "$PROJECT_DIR/api" ]] || [[ -d "$PROJECT_DIR/routes" ]] || [[ -d "$PROJECT_DIR/src/api" ]]; then
    [[ -f "$RULES_DIR/api.md" ]] && rules_loaded+="api "
fi

# React Native / Expo
if [[ -f "$PROJECT_DIR/app.json" ]] && grep -q "expo" "$PROJECT_DIR/app.json" 2>/dev/null; then
    [[ -f "$RULES_DIR/react-native.md" ]] && rules_loaded+="react-native "
fi

# =============================================================================
# Cache Results
# =============================================================================
if [[ "$CACHE_TTL" -gt 0 ]]; then
    # Write to cache
    echo "rules_loaded='$rules_loaded'" > "$CACHE_FILE"

    # Update timestamp marker for file-mod detection
    proj_hash=$(echo "$PROJECT_DIR" | md5sum | cut -d' ' -f1 | cut -c1-12)
    touch "$CACHE_DIR/.cache-$proj_hash"

    # Cleanup old cache files (keep last 20)
    ls -t "$CACHE_DIR"/rules-* 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
fi

# =============================================================================
# Output Context
# =============================================================================
if [[ -n "$rules_loaded" ]]; then
    hook_info "Loaded rules for this session: $rules_loaded"
    hook_info "See ~/.claude/rules/ for detailed guidelines."
fi

exit 0
