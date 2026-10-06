#!/usr/bin/env bash
# =============================================================================
# Secret Rotation Reminder Hook
# =============================================================================
# Event: SessionStart
# Purpose: Remind about secrets that may need rotation
# =============================================================================

set -euo pipefail

source "${HOME}/.claude/hooks/lib/metrics.sh" 2>/dev/null || true

ROTATION_FILE="${HOME}/.claude/state/secret-rotation.json"
ROTATION_INTERVAL_DAYS=90

mkdir -p "$(dirname "$ROTATION_FILE")"

# Initialize rotation tracking if not exists
if [[ ! -f "$ROTATION_FILE" ]]; then
    cat > "$ROTATION_FILE" << 'EOF'
{
  "secrets": [
    {"name": "GITHUB_TOKEN", "env": "GITHUB_TOKEN", "last_rotated": null, "interval_days": 90},
    {"name": "ATLASSIAN_API_TOKEN", "env": "ATLASSIAN_API_TOKEN", "last_rotated": null, "interval_days": 90},
    {"name": "VERCEL_TOKEN", "env": "VERCEL_TOKEN", "last_rotated": null, "interval_days": 180},
    {"name": "NETLIFY_AUTH_TOKEN", "env": "NETLIFY_AUTH_TOKEN", "last_rotated": null, "interval_days": 180},
    {"name": "RAILWAY_TOKEN", "env": "RAILWAY_TOKEN", "last_rotated": null, "interval_days": 180}
  ],
  "last_check": null
}
EOF
fi

# Check if we've checked recently (within 24 hours)
LAST_CHECK=$(jq -r '.last_check // empty' "$ROTATION_FILE")
if [[ -n "$LAST_CHECK" ]]; then
    LAST_CHECK_TS=$(date -d "$LAST_CHECK" +%s 2>/dev/null || echo 0)
    NOW_TS=$(date +%s)
    HOURS_SINCE=$((($NOW_TS - $LAST_CHECK_TS) / 3600))

    if [[ "$HOURS_SINCE" -lt 24 ]]; then
        exit 0
    fi
fi

# Update last check time
TMP=$(mktemp)
jq --arg now "$(date -Iseconds)" '.last_check = $now' "$ROTATION_FILE" > "$TMP" && mv "$TMP" "$ROTATION_FILE"

# Check each secret
warnings=()
NOW_TS=$(date +%s)

while IFS= read -r secret; do
    name=$(echo "$secret" | jq -r '.name')
    env_var=$(echo "$secret" | jq -r '.env')
    last_rotated=$(echo "$secret" | jq -r '.last_rotated // empty')
    interval=$(echo "$secret" | jq -r '.interval_days // 90')

    # Check if env var is set
    if [[ -z "${!env_var:-}" ]]; then
        continue  # Not configured, skip
    fi

    if [[ -z "$last_rotated" ]]; then
        warnings+=("🔑 $name: Never recorded rotation date")
        warnings+=("   Run: claude secret-rotated $name")
    else
        ROTATED_TS=$(date -d "$last_rotated" +%s 2>/dev/null || echo 0)
        DAYS_SINCE=$((($NOW_TS - $ROTATED_TS) / 86400))

        if [[ "$DAYS_SINCE" -gt "$interval" ]]; then
            warnings+=("🔑 $name: Last rotated $DAYS_SINCE days ago (recommended: every $interval days)")
            warnings+=("   After rotating, run: claude secret-rotated $name")
        fi
    fi
done < <(jq -c '.secrets[]' "$ROTATION_FILE")

# Output warnings if any
if [[ ${#warnings[@]} -gt 0 ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 Secret Rotation Reminders"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for warning in "${warnings[@]}"; do
        echo "$warning"
    done
    echo ""
    echo "To mark a secret as rotated:"
    echo "  jq '.secrets |= map(if .name == \"SECRET_NAME\" then .last_rotated = \"$(date -Iseconds)\" else . end)' ~/.claude/state/secret-rotation.json > tmp && mv tmp ~/.claude/state/secret-rotation.json"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

exit 0
