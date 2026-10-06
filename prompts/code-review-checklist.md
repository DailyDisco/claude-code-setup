# Code Review Checklist

## Context
Use this prompt for thorough pull request reviews. Covers correctness, security, performance, maintainability, and testing.

## Methodology

### Phase 1: Understand the Change
1. Read the PR description and linked issues
2. Understand the intended behavior change
3. Review the scope — is it appropriately sized?
4. Check if the approach aligns with codebase patterns

### Phase 2: Correctness
1. Does the code do what it claims to do?
2. Are edge cases handled?
3. Are error conditions handled gracefully?
4. Is the logic sound (no off-by-one, null checks, etc.)?
5. Are race conditions possible?

### Phase 3: Security
1. Is user input validated and sanitized?
2. Are SQL queries parameterized?
3. Is output properly encoded?
4. Are secrets handled securely?
5. Are authorization checks in place?

### Phase 4: Performance
1. Are there obvious N+1 queries?
2. Is data fetched efficiently?
3. Are expensive operations cached appropriately?
4. Are there potential memory leaks?
5. Is pagination used for large datasets?

### Phase 5: Maintainability
1. Is the code readable and self-documenting?
2. Are functions/methods appropriately sized?
3. Is there unnecessary complexity?
4. Are abstractions at the right level?
5. Is there code duplication that should be extracted?

### Phase 6: Testing
1. Are there tests for new functionality?
2. Do tests cover edge cases?
3. Are tests readable and maintainable?
4. Is test coverage appropriate?
5. Do existing tests still pass?

### Phase 7: Documentation
1. Are public APIs documented?
2. Are complex algorithms explained?
3. Is the README updated if needed?
4. Are breaking changes documented?

## Questions to Ask
- What could go wrong with this code?
- How would I debug this if it failed in production?
- Will the next developer understand this?
- What happens under load?
- What happens with malicious input?

## Output Format

### Review Summary
Overall assessment: [Approve/Request Changes/Comment]

### What I Reviewed
- Files reviewed: X
- Lines changed: +X/-X
- Complexity: [Low/Medium/High]

### Strengths
- What the PR does well

### Required Changes
Must be addressed before merge:
1. [Blocking] Description of issue

### Suggestions
Nice-to-have improvements:
1. [Non-blocking] Description of suggestion

### Questions
Things I need clarification on:
1. Question about specific code

### Checklist
- [ ] Code compiles/builds
- [ ] Tests pass
- [ ] No security vulnerabilities
- [ ] No performance regressions
- [ ] Follows codebase conventions
- [ ] Changes are appropriately scoped
- [ ] Documentation updated if needed
