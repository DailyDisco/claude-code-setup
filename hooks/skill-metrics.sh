#!/bin/bash
# Skill Metrics Hook
# Event: PostToolUse (Skill)
# Purpose: Track skill usage for analytics and optimization

set -euo pipefail

# Metrics file location
METRICS_DIR="${HOME}/.claude/metrics"
METRICS_FILE="${METRICS_DIR}/skill-usage.jsonl"
mkdir -p "$METRICS_DIR"

# Get skill information from stdin
# tool_name is "Skill" when the Skill tool is used; skill name lives in tool_input
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null || true)

# Only track Skill tool usage
[[ "$tool_name" != "Skill" ]] && exit 0

# Extract skill name from input (format: {"tool_input": {"skill": "name", "args": "..."}})
skill_name=$(echo "$input" | jq -r '.tool_input.skill // .tool_input.name // empty' 2>/dev/null)
skill_args=$(echo "$input" | jq -r '.tool_input.args // empty' 2>/dev/null)

# Skip if no skill name
[[ -z "$skill_name" ]] && exit 0

# Get project context
project_dir="${PWD}"
project_name=$(basename "$project_dir")

# Check if in git repo
git_repo="false"
git_branch=""
if git rev-parse --git-dir &>/dev/null 2>&1; then
    git_repo="true"
    git_branch=$(git branch --show-current 2>/dev/null || echo "")
fi

# Create metric entry
timestamp=$(date -Iseconds)
metric=$(jq -n \
    --arg skill "$skill_name" \
    --arg args "$skill_args" \
    --arg project "$project_name" \
    --arg project_path "$project_dir" \
    --arg git_repo "$git_repo" \
    --arg git_branch "$git_branch" \
    --arg timestamp "$timestamp" \
    --arg session "${CLAUDE_SESSION_ID:-unknown}" \
    '{
        timestamp: $timestamp,
        skill: $skill,
        args: $args,
        project: $project,
        project_path: $project_path,
        git_repo: ($git_repo == "true"),
        git_branch: $git_branch,
        session: $session
    }')

# Append to metrics file
echo "$metric" >> "$METRICS_FILE"

# Update aggregated stats
STATS_FILE="${METRICS_DIR}/skill-stats.json"

# Initialize stats file if it doesn't exist
if [[ ! -f "$STATS_FILE" ]]; then
    echo '{"total_invocations": 0, "skills": {}, "projects": {}, "last_updated": null}' > "$STATS_FILE"
fi

# Update stats
tmp_file=$(mktemp)
jq --arg skill "$skill_name" \
   --arg project "$project_name" \
   --arg timestamp "$timestamp" \
   '
   .total_invocations += 1 |
   .skills[$skill] = ((.skills[$skill] // 0) + 1) |
   .projects[$project] = ((.projects[$project] // 0) + 1) |
   .last_updated = $timestamp
   ' "$STATS_FILE" > "$tmp_file" && mv "$tmp_file" "$STATS_FILE"

exit 0
