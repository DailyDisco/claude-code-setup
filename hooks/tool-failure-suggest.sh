#!/bin/bash
# tool-failure-suggest.sh — PostToolUseFailure hook
# Detects common failure patterns and suggests fixes.
# Non-blocking — outputs suggestions as context for Claude.

set -euo pipefail

hook_data=$(cat 2>/dev/null || echo "{}")

tool_name=$(echo "$hook_data" | jq -r '.tool_name // empty' 2>/dev/null)
error_msg=$(echo "$hook_data" | jq -r '.error // empty' 2>/dev/null)
tool_input=$(echo "$hook_data" | jq -r '.tool_input.command // .tool_input.file_path // empty' 2>/dev/null)

[[ -z "$error_msg" ]] && exit 0

suggestion=""

# ─── npm/node failures ────────────────────────────────────────────────
if echo "$error_msg" | grep -qi "ENOENT.*package.json\|Cannot find module\|MODULE_NOT_FOUND"; then
    suggestion="Module not found. Try: npm install (or npm ci for clean install)"

elif echo "$error_msg" | grep -qi "ERESOLVE\|peer dep\|dependency tree"; then
    suggestion="Dependency conflict. Try: npm install --legacy-peer-deps, or check package.json for version mismatches"

elif echo "$error_msg" | grep -qi "EACCES\|permission denied.*npm"; then
    suggestion="Permission issue with npm. Avoid sudo — check ~/.npm ownership or use nvm"

elif echo "$error_msg" | grep -qi "node_modules.*not found\|npm ERR.*missing"; then
    suggestion="Missing node_modules. Run: npm ci"

# ─── TypeScript failures ─────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "TS[0-9].*error\|Cannot find name\|Property.*does not exist"; then
    suggestion="TypeScript error. Check types with: npx tsc --noEmit"

# ─── Go failures ──────────────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "go:.*module.*not found\|cannot find package"; then
    suggestion="Go module not found. Try: go mod tidy"

elif echo "$error_msg" | grep -qi "go build.*undefined\|undeclared name"; then
    suggestion="Go compilation error. Check imports and ensure all referenced symbols are exported"

# ─── Python failures ─────────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "ModuleNotFoundError\|No module named"; then
    module=$(echo "$error_msg" | grep -oP "No module named '\K[^']+")
    suggestion="Python module missing. Try: pip install $module (or check pyproject.toml/requirements.txt)"

elif echo "$error_msg" | grep -qi "SyntaxError\|IndentationError"; then
    suggestion="Python syntax error. Check indentation and syntax near the reported line"

# ─── Git failures ─────────────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "CONFLICT\|merge conflict"; then
    suggestion="Merge conflict detected. Resolve conflicts in the listed files, then git add and commit"

elif echo "$error_msg" | grep -qi "rejected.*non-fast-forward\|failed to push"; then
    suggestion="Push rejected — remote has changes. Pull first: git pull --rebase origin $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')"

elif echo "$error_msg" | grep -qi "not a git repository"; then
    suggestion="Not inside a git repo. Run: git init, or cd to the project root"

elif echo "$error_msg" | grep -qi "pathspec.*did not match"; then
    suggestion="Git pathspec error — file or branch doesn't exist. Check spelling and current directory"

# ─── Docker failures ──────────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "docker.*not found\|Cannot connect to the Docker daemon"; then
    suggestion="Docker not running. Start it with: sudo systemctl start docker"

elif echo "$error_msg" | grep -qi "port.*already.*use\|address already in use"; then
    port=$(echo "$error_msg" | grep -oP ':\K[0-9]+' | head -1)
    suggestion="Port ${port:-unknown} in use. Find what's using it: lsof -i :${port:-PORT} or kill it: kill \$(lsof -t -i :${port:-PORT})"

# ─── File system failures ────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "No such file or directory"; then
    suggestion="File/directory not found. Check the path exists and spelling is correct"

elif echo "$error_msg" | grep -qi "Permission denied" && ! echo "$error_msg" | grep -qi "npm"; then
    suggestion="Permission denied. Check file permissions: ls -la on the target path"

elif echo "$error_msg" | grep -qi "ENOSPC\|No space left"; then
    suggestion="Disk full. Free space: du -sh /tmp/* ~/.cache/* | sort -rh | head -10"

# ─── Database failures ───────────────────────────────────────────────
elif echo "$error_msg" | grep -qi "connection refused.*5432\|ECONNREFUSED.*5432\|pg_isready"; then
    suggestion="PostgreSQL not reachable. Check: sudo systemctl status postgresql, or verify DATABASE_URL"

elif echo "$error_msg" | grep -qi "relation.*does not exist\|table.*not found"; then
    suggestion="Database table missing. Run migrations: check your migration runner (prisma migrate dev, golang-migrate, etc.)"

elif echo "$error_msg" | grep -qi "authentication failed.*password\|FATAL.*password"; then
    suggestion="Database auth failed. Verify DATABASE_URL credentials in .env"

# ─── Generic command failures ────────────────────────────────────────
elif echo "$error_msg" | grep -qi "command not found"; then
    cmd=$(echo "$error_msg" | grep -oP '\S+(?=: command not found)' | head -1)
    suggestion="Command '${cmd:-unknown}' not found. Install it or check PATH"
fi

if [[ -n "$suggestion" ]]; then
    echo "Recovery suggestion: $suggestion"
fi

exit 0
