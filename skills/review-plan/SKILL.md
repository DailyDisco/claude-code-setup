---
name: review-plan
description: Critically review an implementation plan before execution. Verifies nothing will break, integration is sound, and best practices are followed. Use after a plan is presented and before coding begins.
allowed-tools: Read, Grep, Glob
context-files:
  - ~/.config/agent-config/rules/core.md
  - ~/.config/agent-config/rules/security.md
  - ~/.config/agent-config/rules/testing.md
  - ~/.config/agent-config/rules/performance.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Plan Reviewer

You just presented an implementation plan. Now critically review it BEFORE writing any code. Your job is to poke holes, find risks, and verify the plan is sound.

## Objective
- Verify the plan won't break existing functionality
- Confirm proper integration with the existing codebase
- Check that the approach follows best practices and industry standards
- Identify gaps, risks, or overlooked dependencies
- Revise the plan if issues are found

## Hard Rules
1. Do NOT write or edit any code — this is a review phase only
2. Do NOT skip files — read every file the plan touches or depends on
3. Be adversarial — assume something IS wrong until proven otherwise
4. If you find issues, revise the plan before proceeding
5. Do NOT rubber-stamp — finding zero issues is suspicious, dig deeper

## Review Process

### Step 1: Inventory What the Plan Touches

List every file the plan will:
- **Create** — is there already something similar? Would this duplicate existing code?
- **Modify** — read the current state of each file to understand what exists
- **Depend on** — read imports, utilities, services, types the plan assumes exist

### Step 2: Read the Existing Code

For each file the plan touches or depends on, actually read it. Verify:
- **Do the functions/types/exports the plan references actually exist?** Check names, signatures, and locations
- **Has the code changed since the plan was formed?** The plan may be based on stale assumptions
- **Are there existing utilities the plan should reuse instead of creating new ones?**
- **Are there patterns in adjacent code the plan should follow?**

### Step 3: Integration Analysis

Ask these questions for each planned change:

**Will it break callers?**
- If modifying a function signature, who calls it? Are they all accounted for?
- If changing an export, who imports it?
- If changing a type, what breaks downstream?

**Will it break at runtime?**
- Are there edge cases the plan doesn't handle (null, empty, error states)?
- Are there async boundaries the plan misses (missing await, race conditions)?
- Does the plan handle the unhappy path (API errors, validation failures, timeouts)?

**Will it break tests?**
- Do existing tests depend on the behavior being changed?
- Does the plan include updating affected tests?
- Are there test utilities or factories that need updating?

**Will it break the build?**
- Are all new imports available? Are removed imports cleaned up?
- Does the plan account for TypeScript strict mode?
- Are there circular dependency risks?

### Step 4: Best Practices Check

**Architecture**
- Does the plan follow the project's established layering? (e.g., service layer, not Prisma in routes)
- Does it reuse existing patterns or invent new ones unnecessarily?
- Is the scope right? (not over-engineered, not cutting corners)

**Security**
- Input validation at boundaries?
- Auth/authz on new or modified endpoints?
- No secrets, PII, or sensitive data exposure?

**Performance**
- N+1 query risks?
- Unbounded queries or loops?
- Missing pagination on list endpoints?

**Standards**
- Consistent naming with the rest of the codebase?
- Error handling follows project patterns?
- Response formats match API conventions?

### Step 5: Dependency & Ordering Check

- Are the steps in the right order? (e.g., schema before service, service before route)
- Are there implicit dependencies between steps the plan doesn't acknowledge?
- Could any step fail in a way that leaves the system in a broken intermediate state?

## Output Format

### Plan Review Summary

**Files inspected:** List of files you actually read during review

### Issues Found

For each issue:
```
[RISK LEVEL] — Description
  What the plan says: ...
  What actually exists: ...
  Impact if not addressed: ...
  Suggested fix: ...
```

Risk levels:
- **BREAKING** — Will cause errors, test failures, or runtime crashes
- **INCORRECT** — Plan assumes something that isn't true
- **MISSING** — Plan omits a necessary step or consideration
- **SUBOPTIMAL** — Works but violates project conventions or best practices
- **MINOR** — Low-risk nit that could be improved

### Revised Plan

If issues were found, present the corrected plan with changes highlighted.
If no issues were found, state that the plan looks solid and is ready to execute.

### Verdict

One of:
- **Ready to execute** — Plan is sound, proceed with implementation
- **Revised and ready** — Issues found and corrected, proceed with revised plan
- **Needs discussion** — Found issues that require your input before proceeding
