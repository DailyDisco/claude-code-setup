# Core Development Principles

Universal rules that apply to all projects regardless of stack.

---

## Environment Files

- Environment files (`.env`, `.env.local`, etc.) may be edited when needed
- Document required variables in `.env.example`
- Never commit secrets to version control
- Warn if patterns resemble API keys or tokens

---

## Code Quality

- Optimize for **clarity, maintainability, and correctness** over cleverness
- Prefer **explicit behavior** over hidden or magic abstractions
- Break complex logic into **small, single-purpose functions**
- Apply the **Single Responsibility Principle** consistently
- Prefer **composition over inheritance**

### DRY vs Premature Abstraction

- Apply the **Rule of Three**: duplicate code is acceptable until you see the pattern three times
- A bad abstraction is worse than duplication — don't force unrelated code into a shared helper
- When abstracting, ensure the shared logic has a **single reason to change**
- If a helper takes more configuration than the code it replaces, it's premature

### Dependency Management

- Minimize dependencies — every dep is a liability (security, maintenance, bundle size)
- Audit new dependencies before adding: check maintenance status, download count, security history
- Prefer well-maintained packages with few transitive dependencies
- Pin versions in production; use lockfiles always

---

## Decision Making

- Explain reasoning for **non-trivial architectural decisions**
- Ask clarifying questions **before** implementing ambiguous requirements
- When multiple solutions exist:
  - Present trade-offs
  - Recommend one option with justification

---

## Working Style

### Stop and ask when unclear

- If something is ambiguous, **stop** — name what's confusing and ask. Don't pick silently between interpretations.
- Surface assumptions explicitly before implementing. If uncertain, ask.
- Push back when a simpler approach exists — don't just follow instructions you disagree with.

### Surgical changes

Touch only what the task requires. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting that isn't part of the task
- Don't refactor things that aren't broken
- **Match existing style** even if you'd do it differently — consistency beats personal preference
- If you notice unrelated dead code or issues, **mention them** — don't delete or fix silently
- Remove imports/variables/functions that **your changes** made unused. Leave pre-existing dead code alone unless asked.

**The test**: every changed line should trace directly to the request.

### Goal-driven execution

Transform vague tasks into verifiable goals before coding:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after, behavior unchanged"

For multi-step tasks, state a brief plan with verification per step:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") create rework.

---

## Architecture & Project Structure

### Configuration & Environment

- All configuration via environment variables
- Maintain `.env.example` with documented, safe defaults
- Group related variables and comment their purpose
- Validate **required variables at startup** and fail fast
- Never commit secrets. Warn if patterns resemble keys or tokens

### File Organization

- Use **clear, descriptive names** aligned with project conventions
- Co-locate related logic (components + tests, utilities + types)
- Naming conventions:
  - `camelCase` → functions, variables
  - `PascalCase` → components, types, classes
- Avoid abbreviations unless universally understood (`id`, `api`, `url`)

---

## Error Handling

Errors must be:

- **Explicit** — never silently swallow errors
- **Logged with context** — include what was attempted, relevant IDs, and stack traces
- **User-friendly** — show actionable messages, not stack traces

### Error Boundary Principles

- Fail **gracefully**, not silently — an empty catch block is a bug
- Fail **fast at boundaries** — validate inputs at entry points, not deep in the call stack
- Provide **fallback behavior** where possible (cached data, default values, degraded mode)
- Categorize errors: **retriable** (network timeout) vs **fatal** (invalid config) vs **user error** (bad input)

---

## Code Review Mindset

When reviewing code (or self-reviewing), check for:

- **Correctness** — does it handle edge cases? Off-by-one? Null/undefined?
- **Security** — injection risks? Auth checks? Input validation?
- **Performance** — N+1 queries? Unnecessary re-renders? Missing indexes?
- **Readability** — would a new team member understand this in 6 months?
- **Error handling** — what happens when things fail?

---

## Enforcement

Any AI agent operating in this repository **must comply** with these rules.

If instructions conflict:

1. This file
2. Repository README
3. Framework documentation
