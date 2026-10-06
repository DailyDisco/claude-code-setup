# Hook System Documentation

This directory contains Claude Code hooks that run automatically at various lifecycle events.

## Quick Reference

| Event | Trigger | Active Hooks |
|-------|---------|--------------|
| **SessionStart** | Session begins | repo-scan, project-memory, workflow-resume, mcp-healthcheck, secret-rotation-reminder, context-budget, context-injector, stale-branch-warn |
| **UserPromptSubmit** | User sends message | prd-enforcement, skill-suggester, agent-router |
| **PreToolUse (git commit)** | Before `git commit` | commit-guard, type-check, build-test-gate, lint-staged, commit-size |
| **PreToolUse (git push)** | Before `git push` | pre-push |
| **PostToolUse (Edit/Write)** | After file changes | auto-format, import-fixer, post-edit-dispatch, auto-test, changelog-tracker |
| **PostToolUse (Bash)** | After shell commands | dependency-audit |
| **PostToolUse (Skill)** | After skill invocation | skill-metrics |
| **Stop** | Session ends | completion-check, project-memory (save), uncommitted-warn |

## Hook Descriptions

### Session Start Hooks

| Hook | Purpose | Timeout |
|------|---------|---------|
| `repo-scan.sh` | Detect monorepo type, frameworks, test/build commands | 30s |
| `project-memory.sh` | Load per-project learnings and decisions | 5s |
| `workflow-resume.sh` | Offer to resume interrupted workflows | 5s |
| `mcp-healthcheck.sh` | Verify MCP servers are responding | 10s |
| `secret-rotation-reminder.sh` | Remind about secrets needing rotation | 5s |
| `context-budget.sh` | Track context token usage | 5s |
| `context-injector.sh` | Auto-load rules based on file patterns | 10s |
| `stale-branch-warn.sh` | Warn if branch is behind main or inactive | 10s |

### User Prompt Hooks

| Hook | Purpose |
|------|---------|
| `prd-enforcement.sh` | Enforce PRD-first workflow for features |
| `skill-suggester.sh` | Suggest relevant skills based on prompt |
| `agent-router.sh` | Route to specialized agents |

### Pre-Commit Hooks

| Hook | Purpose |
|------|---------|
| `commit-guard.sh` | Enforce conventional commits, block AI references |
| `type-check.sh` | Fast TypeScript/Go type checking |
| `build-test-gate.sh` | Ensure build and tests pass |
| `lint-staged.sh` | Run linters on staged files |
| `commit-size.sh` | Warn about oversized commits |

### Pre-Push Hooks

| Hook | Purpose |
|------|---------|
| `pre-push.sh` | Full validation for protected branches |

### Post-Edit Hooks

| Hook | Purpose | Timeout |
|------|---------|---------|
| `auto-format.sh` | Auto-format files (prettier/biome/gofmt/ruff/rustfmt) | 10s |
| `import-fixer.sh` | Auto-fix imports (goimports/isort/eslint) | 10s |
| `post-edit-dispatch.sh` | Dispatch to appropriate post-edit checks | 30s |
| `auto-test.sh` | Run relevant tests after file edits | 60s |
| `changelog-tracker.sh` | Track changes for release notes | 5s |

**Dispatched Checks** (via post-edit-dispatch.sh):
| Check | Purpose |
|-------|---------|
| `openapi-sync.sh` | Remind to update OpenAPI spec |
| `test-gen-prompt.sh` | Suggest test generation for uncovered code |
| `security-check.sh` | Flag security considerations |
| `infra-drift.sh` | Ensure dev/prod parity |
| `breaking-change.sh` | Warn about breaking API changes |
| `i18n-check.sh` | Check for missing translations |
| `migration-safety.sh` | Validate database migration safety |

### Stop Hooks

| Hook | Purpose | Timeout |
|------|---------|---------|
| `completion-check.sh` | Verify task completion before ending | 5s |
| `project-memory.sh save` | Persist learnings to project memory | 5s |
| `uncommitted-warn.sh` | Remind about uncommitted changes | 5s |

### Utility Hooks

| Hook | Purpose |
|------|---------|
| `dependency-audit.sh` | Warn about new dependencies |
| `skill-metrics.sh` | Track skill usage for analytics |
| `test-coverage.sh` | Check test coverage (template) |
| `hook-debug.sh` | Enable debug mode for hook troubleshooting |
| `persist-learnings.sh` | Save learnings to project memory |

## Library Utilities

Shared utilities in `lib/`:

| File | Purpose |
|------|---------|
| `metrics.sh` | Log hook execution metrics to JSONL |
| `state.sh` | Build cache and state management |
| `workflow-state.sh` | Workflow resumption state |
| `aggregator.sh` | Data aggregation utilities |

## Configuration

Hooks are configured in `~/.claude/settings.json` under the `hooks` key.

Example hook configuration:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/repo-scan.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Debugging

To debug hook execution issues:

1. Run `hook-debug.sh` manually to enable debug mode
2. Check `~/.claude/hook-metrics.jsonl` for execution history
3. Check individual hook output in `~/.claude/debug/`

## Adding New Hooks

1. Create script in `~/.claude/hooks/`
2. Make executable: `chmod +x ~/.claude/hooks/your-hook.sh`
3. Add configuration to `~/.claude/settings.json`
4. Test with a sample trigger

## Hook Template

```bash
#!/bin/bash
# Hook: your-hook-name
# Event: SessionStart | UserPromptSubmit | PreToolUse | PostToolUse | Stop
# Description: What this hook does

set -euo pipefail

# Source common utilities
source ~/.claude/hooks/lib/metrics.sh 2>/dev/null || true

# Your hook logic here

# Output for Claude (optional)
echo "Hook message for Claude"
```
