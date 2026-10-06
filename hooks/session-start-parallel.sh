#!/bin/bash
# Parallel SessionStart hook execution
# Phase 1 optimization: Run all SessionStart hooks concurrently
set -euo pipefail

HOOKS_DIR="$HOME/.claude/hooks"
output_dir=$(mktemp -d)
trap "rm -rf $output_dir" EXIT

# Launch all hooks in parallel with individual timeouts
# Prefix output files with numbers to ensure deterministic ordering
timeout 30 bash "$HOOKS_DIR/repo-scan.sh" > "$output_dir/1-repo-scan.out" 2>&1 &
pids[0]=$!
timeout 10 bash "$HOOKS_DIR/mcp-healthcheck.sh" > "$output_dir/2-mcp.out" 2>&1 &
pids[1]=$!
timeout 10 bash "$HOOKS_DIR/context-injector.sh" > "$output_dir/3-context.out" 2>&1 &
pids[2]=$!
timeout 5 bash "$HOOKS_DIR/workflow-resume.sh" > "$output_dir/4-workflow.out" 2>&1 &
pids[3]=$!
timeout 5 bash "$HOOKS_DIR/stale-branch-warn.sh" > "$output_dir/5-branch.out" 2>&1 &
pids[4]=$!

# Wait for all background jobs to complete (properly handle exit codes)
for pid in "${pids[@]}"; do
    wait "$pid" || true  # Don't fail if individual hook fails
done

# Output results in deterministic order (sorted by filename prefix)
for f in "$output_dir"/*.out; do
    # Only output files that have content (non-empty)
    [[ -s "$f" ]] && cat "$f"
done

# Explicitly exit with success (prevent exit code from last background job)
exit 0
