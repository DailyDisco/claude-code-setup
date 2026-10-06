#!/bin/bash
# =============================================================================
# TIER 1: Commit Message Guardrail Hook
# =============================================================================
# Event: PreToolUse (Bash)
# Purpose: Enforces conventional commits, blocks AI references, prevents push
# =============================================================================

set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh"

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[[ "$tool_name" != "Bash" ]] && exit 0

# Block destructive commands
if echo "$command" | grep -qE 'git\s+(push\s+--force|push\s+-f|reset\s+--hard)'; then
    echo "Destructive git commands blocked." >&2
    exit 2
fi

# Validate commit message format
if echo "$command" | grep -qE 'git\s+commit'; then
    if echo "$command" | grep -qE "<<'?EOF'?"; then
        # Heredoc form: git commit -m "$(cat <<'EOF' ... EOF)"
        commit_msg=$(echo "$command" | sed -n "/<<'\{0,1\}EOF'\{0,1\}/,/^EOF/p" | sed '1d;$d')
    else
        # Capture ALL -m parts (subject + body paragraphs), one per line
        commit_msg=$(echo "$command" | grep -oP "(?<=-m\s[\"'])[^\"']+" || true)
    fi

    if [[ -n "$commit_msg" ]]; then
        first_line=$(echo "$commit_msg" | head -1)

        # Block AI references in subject (word-bounded to avoid false positives like "email"/"maintain")
        if echo "$first_line" | grep -iqE '\b(claude|ai|gpt|llm|copilot|chatgpt)\b'; then
            echo "Commit subject should not reference AI." >&2
            exit 2
        fi

        # Enforce conventional commits
        if ! echo "$first_line" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_-]+\))?!?:\s*.+'; then
            cat >&2 << 'EOF'
Conventional Commits required:
  <type>(<scope>): <description>

Types: feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
Example: feat(auth): add session refresh endpoint
EOF
            exit 2
        fi

        # Check length
        if [[ ${#first_line} -gt 72 ]]; then
            echo "Subject too long (${#first_line}/72 chars)." >&2
            exit 2
        fi

        # Block AI attribution anywhere in the full message (subject + body)
        if echo "$commit_msg" | grep -iqE '(co-authored-by:.*(claude|ai)|generated with.*(claude|ai)|🤖)'; then
            echo "Commit message must not include AI attribution." >&2
            exit 2
        fi
    fi
fi

exit 0
