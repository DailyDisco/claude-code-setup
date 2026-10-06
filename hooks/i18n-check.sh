#!/bin/bash
# i18n-check.sh - Check for missing translations after code changes
# Triggered by PostToolUse on Edit|Write

set -euo pipefail

# Get the modified file from tool input
TOOL_INPUT="${TOOL_INPUT:-}"
MODIFIED_FILE=""

# Extract file path from tool input JSON
if [[ -n "$TOOL_INPUT" ]]; then
  MODIFIED_FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)
fi

# Skip if no file or not a component file
if [[ -z "$MODIFIED_FILE" ]]; then
  exit 0
fi

# Only check relevant file types (React components, pages)
case "$MODIFIED_FILE" in
  *.tsx|*.jsx|*.ts|*.js)
    ;;
  *)
    exit 0
    ;;
esac

# Skip test files, config files, and translation files
if [[ "$MODIFIED_FILE" =~ \.(test|spec)\. ]] || \
   [[ "$MODIFIED_FILE" =~ (config|\.config)\. ]] || \
   [[ "$MODIFIED_FILE" =~ /locales/ ]] || \
   [[ "$MODIFIED_FILE" =~ /messages/ ]] || \
   [[ "$MODIFIED_FILE" =~ /i18n/ ]]; then
  exit 0
fi

# Check if file exists
if [[ ! -f "$MODIFIED_FILE" ]]; then
  exit 0
fi

# Detect i18n setup in project
I18N_LIB=""
LOCALES_DIR=""

# Check for react-i18next
if [[ -f "package.json" ]] && grep -q "react-i18next\|i18next" package.json 2>/dev/null; then
  I18N_LIB="react-i18next"
  # Find locales directory
  for dir in "src/locales" "locales" "public/locales" "src/i18n/locales"; do
    if [[ -d "$dir" ]]; then
      LOCALES_DIR="$dir"
      break
    fi
  done
fi

# Check for next-intl
if [[ -f "package.json" ]] && grep -q "next-intl" package.json 2>/dev/null; then
  I18N_LIB="next-intl"
  for dir in "messages" "src/messages" "locales"; do
    if [[ -d "$dir" ]]; then
      LOCALES_DIR="$dir"
      break
    fi
  done
fi

# No i18n library detected, skip
if [[ -z "$I18N_LIB" ]]; then
  exit 0
fi

# Scan for potential hardcoded strings in the modified file
# Look for patterns like: >Text<, "Text", 'Text' in JSX context
HARDCODED_STRINGS=$(grep -n -E \
  '>\s*[A-Z][a-zA-Z\s]+\s*<|placeholder="[^"]+"|title="[^"]+"|alt="[^"]+"|aria-label="[^"]+"' \
  "$MODIFIED_FILE" 2>/dev/null | \
  grep -v -E 't\(|useTranslation|useTranslations|i18n\.' || true)

# Check if file uses translation hooks
USES_I18N=$(grep -c -E 'useTranslation|useTranslations|t\(' "$MODIFIED_FILE" 2>/dev/null || echo "0")

# If file has hardcoded strings and doesn't use i18n
if [[ -n "$HARDCODED_STRINGS" ]] && [[ "$USES_I18N" -eq 0 ]]; then
  HARDCODED_COUNT=$(echo "$HARDCODED_STRINGS" | wc -l)

  cat << EOF
{
  "warning": "i18n: Potential hardcoded strings detected",
  "file": "$MODIFIED_FILE",
  "count": $HARDCODED_COUNT,
  "suggestion": "Consider using /i18n skill to add translations",
  "library": "$I18N_LIB",
  "localesDir": "$LOCALES_DIR"
}
EOF
fi

exit 0
