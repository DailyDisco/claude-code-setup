---
name: quick-fix
description: Apply common fixes without full skill workflows. For simple, targeted changes.
allowed-tools: Read, Edit, Bash(npm:*), Bash(go:*)
---

# Quick Fix Command

Apply common, simple fixes without the overhead of full skill workflows.

## Usage

```
/quick-fix [issue]
```

## Supported Fixes

### TypeScript/JavaScript
- `any` → proper type
- Missing null check
- Unused import cleanup
- Missing await
- Console.log removal

### Go
- Unhandled error
- Missing nil check
- Unused variable
- Missing defer

### General
- Typo fixes
- Comment cleanup
- Import organization
- Simple refactors (rename, extract)

## Hard Rules
1. Only fix what's asked - no scope creep
2. Verify fix compiles/type-checks
3. One fix at a time
4. If fix requires > 5 lines changed, suggest a skill instead

## Output

```
Fixed: [description]
File: path/to/file.ts:42
Change: [before] → [after]
```
