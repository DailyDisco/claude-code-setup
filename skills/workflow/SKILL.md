---
name: workflow
description: Orchestrate multi-step development workflows. Chains skills together for complete feature development, bugfixes, or releases.
requires:
  - commit
triggers:
  - prd-gen
  - test-gen
  - debug
  - refactor
  - review-pr
  - release
emits:
  - WORKFLOW_COMPLETE
  - WORKFLOW_STEP_COMPLETE
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Development Workflow Orchestrator

You are my workflow orchestrator. Guide me through complete development workflows by chaining skills together.

## Workflow Management Commands

### `/workflow resume` - Resume Interrupted Workflow
Continue from where you left off in a previous session:
1. Read workflow state from `~/.claude/workflows/`
2. Display current progress and remaining steps
3. Continue from the current step

### `/workflow status` - View Workflow Progress
Display detailed progress:
```
Workflow: <type>
Started: <timestamp>
Progress: Step N/M - <step name>
Completed: [list of completed steps]
Skipped: [list of skipped steps with reasons]
Artifacts: [list of created files]
```

### `/workflow abort` - Cancel Current Workflow
Cancel the current workflow:
1. Archive current state to history
2. Clear active workflow
3. Confirm cancellation

## Available Workflows

When I say `/workflow <type>`, execute the corresponding workflow:

### `/workflow feature` - New Feature Development
Execute these steps in order:
1. **Plan** - Ask clarifying questions about the feature scope
2. **PRD** - Run `/prd-gen` to create PRD.md with requirements
3. **Implement** - Write the code following the PRD
4. **Test** - Run `/test-gen` to generate tests for new code
5. **Verify** - Run tests and fix any failures
6. **Commit** - Use `/commit` to draft a message from staged changes; create a commit only when the user authorized it
7. **Review** - Run `/review-pr` for self-review before PR

### `/workflow bugfix` - Bug Fix Workflow
Execute these steps in order:
1. **Debug** - Run `/debug` to systematically identify root cause
2. **Fix** - Implement the minimal fix addressing root cause
3. **Test** - Run `/test-gen` to add regression test
4. **Verify** - Run existing tests to ensure no regressions
5. **Commit** - Run `/commit` with `fix:` prefix

### `/workflow refactor` - Safe Refactoring
Execute these steps in order:
1. **Baseline** - Run existing tests, ensure all pass
2. **Plan** - Identify refactoring scope and strategy
3. **Refactor** - Run `/refactor` for safe code changes
4. **Verify** - Run tests after each change
5. **Review** - Run `/review-pr` focusing on behavior preservation
6. **Commit** - Run `/commit` with `refactor:` prefix

### `/workflow release` - Release Preparation
Execute these steps in order:
1. **Review** - Run `/review-pr` on all changes since last release
2. **Test** - Run full test suite
3. **Release** - Run `/release` for changelog and version bump
4. **Tag** - Create git tag for the release

### `/workflow hotfix` - Urgent Production Fix
Execute these steps in order:
1. **Branch** - Create hotfix branch from main/master
2. **Debug** - Quick root cause identification
3. **Fix** - Minimal surgical fix
4. **Test** - Run critical path tests
5. **Commit** - Run `/commit` with `hotfix:` prefix
6. **Release** - Run `/release` with patch version bump

## Workflow State Persistence

Workflows persist across sessions via `~/.claude/workflows/`:
- State file per project (based on git root or directory)
- Tracks: current step, completed steps, skipped steps, artifacts
- History of past workflows in `~/.claude/workflows/archive/`

### State Management
When starting a workflow, initialize state:
```bash
# State is managed by ~/.claude/hooks/lib/workflow-state.sh
# Available functions:
# - workflow_start "type" '["Step1", "Step2", ...]'
# - workflow_next_step
# - workflow_skip_step "reason"
# - workflow_add_artifact "filename"
# - workflow_complete
# - workflow_summary
```

## Hard Rules
1. Never skip the verification/test step without explicit consent
2. Run reviews independently of committing; `/commit` only drafts text from staged changes
3. Document any deviations from the standard workflow
4. If blocked, explain why and suggest resolution
5. Persist state after each step completion
6. On session start, check for interrupted workflows

## Output Format

At workflow start:
```
## Workflow: <type>
Steps:
1. [ ] Step 1
2. [ ] Step 2
...

Starting Step 1...
```

After each step:
```
## Step N Complete
[Summary of what was done]

Proceeding to Step N+1...
```

At workflow end:
```
## Workflow Complete
Summary:
- Steps completed: N/M
- Steps skipped: [list]
- Artifacts created: [list files]
```

On resume:
```
## Resuming Workflow: <type>
Previously completed: [list]
Current step: N - <step name>

Continuing...
```
