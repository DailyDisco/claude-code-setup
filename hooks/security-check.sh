#!/bin/bash
# =============================================================================
# TIER 3: Security Surface Check Hook
# =============================================================================
# Event: PostToolUse (Edit|Write on security-sensitive files)
# Purpose: Flags security considerations for auth, uploads, payments, webhooks
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
content=$(echo "$input" | jq -r '.tool_input.content // .tool_input.new_string // empty')

[[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]] && exit 0

# Security-sensitive patterns in filenames
sensitive_file_patterns="(auth|login|session|token|password|credential|payment|billing|stripe|webhook|upload|file|admin|permission|role|secret|key|crypto|encrypt)"

# Security-sensitive patterns in content
sensitive_content_patterns="(password|secret|api_key|apikey|token|bearer|authorization|credential|private_key|jwt|session|cookie|csrf|xss|sql|exec|eval|innerHTML|dangerouslySetInnerHTML)"

is_sensitive=false

# Check filename
if echo "$file_path" | grep -iqE "$sensitive_file_patterns"; then
    is_sensitive=true
fi

# Check content
if [[ -n "$content" ]] && echo "$content" | grep -iqE "$sensitive_content_patterns"; then
    is_sensitive=true
fi

if [[ "$is_sensitive" == "true" ]]; then
    echo "Security-sensitive file modified: $file_path"
    echo ""
    echo "Security checklist:"
    echo "  [ ] Authentication enforced server-side"
    echo "  [ ] Input validation on all user data"
    echo "  [ ] Output encoding to prevent XSS"
    echo "  [ ] Parameterized queries (no SQL injection)"
    echo "  [ ] Secrets not hardcoded or logged"
    echo "  [ ] Rate limiting on sensitive endpoints"
    echo "  [ ] Proper error handling (no stack traces)"
    echo "  [ ] CSRF protection if stateful"
    echo "  [ ] Webhook signature verification"
    echo ""
    echo "Consider running: npm audit / snyk test / trivy"
fi

exit 0
