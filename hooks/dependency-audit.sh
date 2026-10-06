#!/bin/bash
# =============================================================================
# BONUS: Dependency Audit Hook
# =============================================================================
# Event: PostToolUse (Bash - npm/yarn/pnpm install)
# Purpose: Warns about new dependencies and security issues
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[[ "$tool_name" != "Bash" ]] && exit 0

# Check if this is a package install command
if echo "$command" | grep -qE '(npm|yarn|pnpm)\s+(install|add|i)\s+[^-]'; then
    echo "New dependency added."
    echo ""
    echo "Dependency checklist:"
    echo "  [ ] Is this package actively maintained?"
    echo "  [ ] Check bundle size impact (bundlephobia.com)"
    echo "  [ ] Review license compatibility"
    echo "  [ ] Consider: can we avoid this dependency?"
    echo ""
    echo "Run 'npm audit' to check for vulnerabilities."
fi

exit 0
