---
name: refactor
description: Safe refactoring workflow with continuous test verification. Use when user wants to restructure, rename, extract, or improve code without changing behavior.
allowed-tools: Bash(git:*), Bash(npm:*), Bash(go:*), Bash(python:*), Read, Grep, Glob, Edit, Write
context-files:
  - ~/.config/agent-config/rules/testing.md
  - ~/.config/agent-config/rules/core.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Safe Refactoring Assistant

You are my refactoring assistant. Restructure code safely while preserving behavior.

## Objective
- Improve code structure, readability, or maintainability
- Preserve existing behavior exactly (no functional changes)
- Verify with tests after every change
- Create atomic, revertable commits

## Hard Rules
1) Run tests BEFORE starting — establish green baseline
2) Run tests AFTER every individual change — never batch changes
3) Do NOT change behavior — refactoring is structure-only
4) Do NOT refactor untested code without adding tests first
5) Do NOT combine refactoring with feature changes or bug fixes
6) Keep each change small enough to revert independently
7) If tests fail after a change, revert immediately and investigate

## Refactoring Workflow

### Phase 1: Assess
- Understand the current code structure and purpose
- Identify what specifically needs improvement
- Check test coverage: are the areas being refactored tested?
- Run full test suite to establish green baseline

### Phase 2: Plan
- Break refactoring into atomic steps
- Order steps to minimize risk (safest first)
- Identify potential breaking points
- Estimate scope: small (1-2 files) / medium (3-5) / large (6+)

### Phase 3: Execute (per step)
1. Make ONE small change
2. Run tests immediately
3. If green: commit with descriptive message
4. If red: revert and investigate before proceeding
5. Repeat until complete

### Phase 4: Verify
- Run full test suite
- Manual smoke test if applicable
- Review diff to confirm no behavioral changes
- Check for any leftover dead code

## Common Refactoring Patterns

### Extract Function
```
Before: Long function with multiple responsibilities
After: Multiple small functions with single responsibility
Verify: Behavior unchanged, tests pass
```

### Rename Symbol
```
Before: Unclear or misleading name
After: Descriptive, accurate name
Verify: All references updated, no broken imports
```

### Move Code
```
Before: Code in wrong module/file
After: Code in appropriate location
Verify: Imports updated, circular dependencies avoided
```

### Simplify Conditional
```
Before: Nested if/else, complex conditions
After: Early returns, guard clauses, extracted predicates
Verify: All branches still covered
```

### Extract Constant/Variable
```
Before: Magic numbers, repeated expressions
After: Named constants, computed once
Verify: Values unchanged, readability improved
```

## Required Checks
- `git status` — ensure clean working directory
- Test command (npm test, go test, pytest) — establish baseline
- `git diff --stat` — review scope after completion

## Output Format

### 1) Refactoring Goal
- What improvement is being made
- Why it matters (readability, maintainability, performance)

### 2) Pre-flight Status
- Test baseline: PASS / FAIL (do not proceed if fail)
- Files affected: list
- Test coverage: adequate / needs-tests-first

### 3) Refactoring Steps
Numbered list of atomic changes:
1. [Change description] → verify tests
2. [Change description] → verify tests
...

### 4) Execution Log
For each step:
- Change made
- Test result: PASS / FAIL
- Committed: yes / reverted

### 5) Final Verification
- Full test suite: PASS / FAIL
- Total files changed
- Lines added/removed
- Behavioral changes: NONE (must be none)

## Constraints
- Maximum 10 files per refactoring session (split larger efforts)
- Each commit message: `refactor(<scope>): <description>`
- If test coverage is insufficient, add tests before refactoring
- Never refactor and fix bugs in the same session

## Abort Conditions
Stop immediately and report if:
- Tests fail and cannot be fixed by reverting
- Scope expands beyond original plan
- Behavioral change is required (this is a feature, not refactoring)
- Circular dependency or breaking change detected
