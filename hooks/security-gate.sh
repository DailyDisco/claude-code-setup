#!/usr/bin/env bash
# =============================================================================
# Security Gate - PreToolUse Hook
# =============================================================================
# Blocks dangerous operations before they execute.
# Based on IndyDevDan's "Damage Control" pattern.
# Patterns defined in: hooks/security-patterns.yaml
#
# Exit codes:
#   0 = allow (tool proceeds)
#   2 = block (tool is prevented, reason shown)
# =============================================================================
set -euo pipefail
source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_FILE="${SCRIPT_DIR}/security-patterns.yaml"

# Source output filter for logging (degrade gracefully)
source "${SCRIPT_DIR}/lib/output-filter.sh" 2>/dev/null || true

# Read tool input from stdin
TOOL_INPUT=""
if [[ ! -t 0 ]]; then
  TOOL_INPUT="$(cat)"
fi

# Resolve tool name from stdin JSON, falling back to env var
TOOL_NAME="$(echo "$TOOL_INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)"
TOOL_NAME="${TOOL_NAME:-${CLAUDE_TOOL_NAME:-}}"

# -----------------------------------------------------------------------------
# Helper: block with reason
# -----------------------------------------------------------------------------
block() {
  local reason="$1"
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","reason":"${reason}"}}
EOF
  exit 2
}

# -----------------------------------------------------------------------------
# Helper: warn but allow
# -----------------------------------------------------------------------------
warn() {
  local reason="$1"
  echo "SECURITY WARNING: ${reason}" >&2
  exit 0
}

# -----------------------------------------------------------------------------
# Check bash commands against patterns
# -----------------------------------------------------------------------------
check_bash() {
  local command=""
  command="$(echo "$TOOL_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

  [[ -z "$command" ]] && exit 0

  # Blocked patterns
  local blocked_patterns=(
    '--no-preserve-root'
    'mkfs'
    'fdisk'
    'dd if='
    'chmod 777'
    'chmod -R 777'
  )

  for pattern in "${blocked_patterns[@]}"; do
    if [[ "$command" == *"$pattern"* ]]; then
      block "Blocked dangerous command: ${pattern}"
    fi
  done

  # rm aimed at filesystem root (/, /*), a bare top-level system dir (/etc, /usr,
  # /tmp, ...), a whole user home (/home/x, ~, $HOME), or their globs. Subpaths
  # like `rm -rf /tmp/build` stay allowed — the old literal 'rm -rf /' substring
  # flagged every absolute path.
  if echo "$command" | grep -qP '\brm\s+(--?[A-Za-z0-9-]+\s+)*(/+\*?|~/?|\$\{?HOME\}?/?|/(home|root|etc|usr|var|boot|bin|sbin|lib|lib64|opt|srv|tmp|mnt|media|dev|proc|sys)/?\*?|/home/[^/\s]+/?\*?)(\s|$|[;&|<>)])'; then
    block "Blocked rm targeting filesystem root, a system directory, or a whole home directory"
  fi

  # Piped download-to-execution — interpreter must be the command right after the
  # pipe, in the same pipeline segment as curl/wget (plain .* spans matched "sh"
  # inside unrelated words like "finish" and flagged legit curl-then-jq lines)
  if echo "$command" | grep -qP '(curl|wget)[^|]*\|\s*(sudo\s+)?((ba|z|da)?sh|python[0-9.]*|perl|ruby)\b'; then
    block "Blocked piped download-to-execution: curl/wget piped to interpreter"
  fi

  # Base64 decode to execution
  if echo "$command" | grep -qP 'base64[^|]*(--decode|-d)[^|]*\|\s*(sudo\s+)?(ba|z|da)?sh\b'; then
    block "Blocked encoded execution: base64 decode piped to shell"
  fi

  # Netcat reverse shell
  if echo "$command" | grep -qP '(nc|ncat)\s+-e'; then
    block "Blocked potential reverse shell: netcat with -e flag"
  fi

  # Warned patterns (allow but log)
  local warned_patterns=(
    'sudo '
    'kill -9'
    'docker system prune'
    'docker volume prune'
    'pkill'
    'killall'
  )

  for pattern in "${warned_patterns[@]}"; do
    if [[ "$command" == *"$pattern"* ]]; then
      warn "Potentially dangerous command: ${pattern}"
    fi
  done

  exit 0
}

# -----------------------------------------------------------------------------
# Check file paths for Write/Edit
# -----------------------------------------------------------------------------
check_file_write() {
  local file_path=""
  file_path="$(echo "$TOOL_INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"

  [[ -z "$file_path" ]] && exit 0

  # Blocked paths
  local blocked_paths=(
    '/.ssh/'
    '/.aws/'
    '/.gnupg/'
    '/.config/gcloud/'
    '/etc/passwd'
    '/etc/shadow'
    '/etc/sudoers'
    '/etc/hosts'
  )

  for pattern in "${blocked_paths[@]}"; do
    if [[ "$file_path" == *"$pattern"* ]]; then
      block "Blocked write to protected path: ${pattern}"
    fi
  done

  # Warned paths (allow but log)
  local warned_paths=(
    '/.bashrc'
    '/.zshrc'
    '/.profile'
    '/.bash_profile'
    '/.gitconfig'
  )

  for pattern in "${warned_paths[@]}"; do
    if [[ "$file_path" == *"$pattern"* ]]; then
      warn "Writing to sensitive dotfile: ${file_path}"
    fi
  done

  exit 0
}

# -----------------------------------------------------------------------------
# Route by tool name
# -----------------------------------------------------------------------------
case "$TOOL_NAME" in
  Bash)
    check_bash
    ;;
  Write|Edit)
    check_file_write
    ;;
  *)
    # Allow all other tools
    exit 0
    ;;
esac

exit 0
