---
name: explain
description: Explain code, architecture, or concepts in detail. Quick command for understanding without making changes.
allowed-tools: Read, Grep, Glob
---

# Explain Command

Provide clear, detailed explanations of code, architecture, or concepts.

## Usage

```
/explain [target]
```

## Examples

- `/explain src/auth/` - Explain the auth module architecture
- `/explain this function` - Explain selected/discussed code
- `/explain how login works` - Explain a specific flow

## Output Format

### For Code
1. **Purpose**: What does this code do?
2. **How it works**: Step-by-step logic flow
3. **Key dependencies**: What it relies on
4. **Usage examples**: How to use it
5. **Gotchas**: Common pitfalls or edge cases

### For Architecture
1. **Overview**: High-level system description
2. **Components**: Key parts and their responsibilities
3. **Data flow**: How data moves through the system
4. **Decisions**: Why was it designed this way?

## Hard Rules
- Read before explaining (no assumptions)
- Use simple language, avoid jargon where possible
- Include code snippets when helpful
- Don't suggest changes unless asked
