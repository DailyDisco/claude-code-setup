# Debugging Methodology

## Context
Use this prompt when investigating bugs, unexpected behavior, or system failures. Follows a systematic approach to isolate and identify root causes.

## Methodology

### Phase 1: Reproduce
1. Gather exact reproduction steps
2. Identify the expected vs actual behavior
3. Determine if reproducible (always, sometimes, specific conditions)
4. Document the environment (OS, versions, config)

### Phase 2: Isolate
1. Identify the smallest reproduction case
2. Determine when the bug was introduced (git bisect if needed)
3. Check if the bug exists in other environments
4. Rule out external factors (network, database, third-party services)

### Phase 3: Hypothesize
Generate hypotheses ranked by likelihood:
1. Recent changes in related code
2. Edge cases in input handling
3. Race conditions or timing issues
4. State management bugs
5. External dependency issues
6. Configuration or environment differences

### Phase 4: Investigate
For each hypothesis:
1. Identify the code path involved
2. Add strategic logging/breakpoints
3. Trace the execution flow
4. Compare expected vs actual state at each step
5. Confirm or eliminate the hypothesis

### Phase 5: Verify
1. Implement the fix
2. Verify the original bug is resolved
3. Check for regression (related functionality still works)
4. Add a test case that would have caught this bug

## Questions to Answer
- What changed recently that could cause this?
- What are the inputs when the bug occurs?
- What is the state of the system when it fails?
- Is there a pattern to when it happens?
- What assumptions might be wrong?

## Output Format

### Bug Summary
One-line description of the issue

### Reproduction Steps
1. Step one
2. Step two
3. Observe: [actual behavior]
4. Expected: [expected behavior]

### Investigation Log
| Hypothesis | Evidence For | Evidence Against | Status |
|------------|--------------|------------------|--------|

### Root Cause
Technical explanation of why the bug occurs

### Fix
```
// Code or configuration change
```

### Prevention
How to prevent similar bugs in the future
