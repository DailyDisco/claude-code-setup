---
name: compare
description: Compare two implementations, approaches, or versions. Useful for decision making.
allowed-tools: Read, Grep, Glob, WebSearch
---

# Compare Command

Compare two implementations, approaches, libraries, or code versions.

## Usage

```
/compare [A] vs [B]
```

## Examples

- `/compare React Query vs SWR`
- `/compare our auth vs OAuth standard`
- `/compare main vs feature-branch`
- `/compare function A vs function B`

## Output Format

```
═══════════════════════════════════════════════════════════════
                    Comparison: A vs B
═══════════════════════════════════════════════════════════════

                        A                   B
────────────────────────────────────────────────────────────────
Performance         [rating]            [rating]
Bundle Size         [size]              [size]
Learning Curve      [rating]            [rating]
Maintenance         [rating]            [rating]
Community           [rating]            [rating]

═══════════════════════════════════════════════════════════════

## Detailed Analysis

### A Strengths
- [point]
- [point]

### A Weaknesses
- [point]
- [point]

### B Strengths
- [point]
- [point]

### B Weaknesses
- [point]
- [point]

## Recommendation

[Which to choose and why, with context about when each is better]
```

## Hard Rules
- Be objective, present both sides fairly
- Include concrete data where available
- Consider the user's specific context
- Don't recommend without explaining tradeoffs
