---
name: prompt
description: Load curated analysis prompts for complex tasks. Use when you need structured guidance for architecture reviews, debugging, security analysis, or other expert workflows.
allowed-tools: Read, Glob
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Prompt Library

Load and execute curated prompts for complex analysis tasks.

## Usage
```
/prompt <prompt-name>
/prompt list
```

## Available Prompts

### Architecture & Design
- `architecture-review` - Comprehensive codebase architecture analysis
- `api-design-review` - REST/GraphQL API design evaluation
- `schema-review` - Database schema analysis

### Code Quality
- `code-review-checklist` - Thorough PR review checklist
- `refactoring-analysis` - Identify refactoring opportunities
- `tech-debt-assessment` - Technical debt evaluation

### Debugging & Performance
- `debugging-methodology` - Systematic bug investigation
- `performance-analysis` - Performance bottleneck identification
- `memory-leak-hunt` - Memory issue investigation

### Security
- `security-review` - Security-focused code review
- `auth-audit` - Authentication/authorization review
- `data-flow-analysis` - Sensitive data handling review

### Planning
- `feature-breakdown` - Break features into tasks
- `migration-planning` - System migration strategy
- `incident-postmortem` - Post-incident analysis template

## Workflow

1. List available prompts: `/prompt list`
2. Load a prompt: `/prompt <name>`
3. The prompt content will be loaded and applied to your current context
4. Follow the structured methodology in the prompt

## Adding Custom Prompts

Add `.md` files to `~/.claude/prompts/` with this structure:

```markdown
# Prompt Title

## Context
When to use this prompt

## Methodology
Step-by-step approach

## Questions to Answer
Key questions to address

## Output Format
Expected deliverable structure
```
