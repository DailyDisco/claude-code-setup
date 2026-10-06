---
name: init-project
description: Initialize a per-project .claude/ directory with stack-aware CLAUDE.md. Use --complete for full setup with memory, ADRs, and hooks.
allowed-tools: Bash(mkdir:*), Bash(ls:*), Bash(chmod:*), Bash(cat:*), Bash(tree:*), Bash(grep:*), Bash(cp:*), Bash(basename:*), Bash(head:*), Bash(jq:*), Bash(sed:*), Read, Write, Edit, Glob, AskUserQuestion
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Project Initialization

Set up a per-project `.claude/` directory with stack-appropriate configuration.

## Modes

### Basic Mode (default)
`/init-project`

Creates minimal setup:
- `.claude/CLAUDE.md` with stack-aware rules
- Updates `.gitignore`

Best for: Simple projects, quick setup, when you want minimal files.

### Complete Mode
`/init-project --complete`

Creates full setup:
- Everything in Basic, plus:
- `.claude/memory/memory.md` - Persistent context across sessions
- `.claude/decisions/` - ADR templates (MADR format)
- `.claude/hooks/` - Memory sync and ADR index hooks
- `.claude/settings.local.json` - Hooks enabled by default

Best for: Long-running projects, team projects, when you want session memory.

### Update Mode
`/init-project --update`

When `.claude/` already exists:
- Adds missing components
- Updates hooks to latest versions
- Preserves customizations in CLAUDE.md

---

## Hard Rules

1. **NEVER** overwrite existing `.claude/CLAUDE.md` without user confirmation
2. **ALWAYS** detect stack automatically
3. **ALWAYS** update .gitignore
4. Make all shell scripts executable with `chmod +x`
5. **NO QUESTIONS** in basic mode (except if CLAUDE.md exists)

---

## Basic Mode Process

### Step 1: Check for Conflicts

```bash
ls .claude/CLAUDE.md 2>/dev/null
```

If exists: Ask (Overwrite/Merge/Abort)
If not: Proceed silently.

### Step 2: Detect Stack

| File | Template |
|------|----------|
| `package.json` + `next`/`react` | React/Next.js patterns |
| `tsconfig.json` | TypeScript patterns |
| `go.mod` | Go patterns |
| `pyproject.toml` | Python patterns |
| `Dockerfile` | Docker patterns |
| `prisma/` or postgres | Database patterns |

### Step 3: Generate CLAUDE.md

Create `.claude/CLAUDE.md` with:
1. Project header (name from directory, description from README)
2. Detected stack table
3. Commands from package.json/Makefile
4. Environment variables from .env.example
5. Key file locations
6. Stack-specific patterns

### Step 4: Update .gitignore

Add if not present:
```
# Claude Code
.claude/settings.local.json
.claude/todos/
.claude/plans/
```

### Step 5: Show Summary

```markdown
## Claude Code Initialized (Basic)

**Project:** {name}
**Stack:** {detected}

### Files Created
- .claude/CLAUDE.md

### Next Steps
1. Review: `cat .claude/CLAUDE.md`
2. Commit: `git add .claude/ && git commit -m "chore: init claude"`
3. For full setup: `/init-project --complete`
```

---

## Complete Mode Process

Everything in Basic Mode, plus:

### Additional Files

```bash
mkdir -p .claude/{memory,decisions,hooks,skills,prompts,agents}
```

### memory/memory.md

```markdown
# Project Memory

## Current Focus
- [ ] Current task

## Key Decisions
| Date | Decision | Rationale |
|------|----------|-----------|
| {today} | Initialized Claude Code | Persistent memory |

## Learnings & Gotchas
-

## Context for Next Session
---
### Last Updated: {timestamp}
```

### decisions/0000-template.md (MADR)

```markdown
# ADR-{NUMBER}: {Title}

## Status
{Proposed | Accepted | Deprecated | Superseded}

## Context
{Issue and constraints}

## Decision
{What we're doing}

## Consequences
### Positive
- {Benefit}

### Negative
- {Drawback}
```

### hooks/memory-sync.sh

Provides: load, save, add-note, add-learning commands

### hooks/adr-index.sh

Auto-regenerates decisions/index.md when ADRs change

### settings.local.json

```json
{
  "hooks": {
    "SessionStart": [{"command": ".claude/hooks/memory-sync.sh load"}],
    "SessionStop": [{"command": ".claude/hooks/memory-sync.sh save"}],
    "PostEdit": [{"matcher": ".claude/decisions/[0-9]*.md", "command": ".claude/hooks/adr-index.sh"}]
  }
}
```

### Complete Mode Summary

```markdown
## Claude Code Initialized (Complete)

**Project:** {name}
**Stack:** {detected}

### Files Created
| File | Purpose |
|------|---------|
| .claude/CLAUDE.md | Project instructions |
| .claude/memory/memory.md | Persistent context |
| .claude/decisions/ | ADR templates |
| .claude/hooks/ | Memory & ADR hooks |
| .claude/settings.local.json | Hooks enabled |

### Next Steps
1. Review: `cat .claude/CLAUDE.md`
2. Commit: `git add .claude/ .gitignore && git commit -m "chore: init claude"`
```

---

## Detection Matrix

### Package Manager

| Lockfile | Manager | Run Command |
|----------|---------|-------------|
| `package-lock.json` | npm | `npm run` |
| `pnpm-lock.yaml` | pnpm | `pnpm` |
| `yarn.lock` | yarn | `yarn` |
| `bun.lockb` | bun | `bun run` |

### Stack

| Pattern | Stack |
|---------|-------|
| `package.json` + `next` | Next.js |
| `package.json` + `react` | React |
| `package.json` + `@tanstack` | TanStack |
| `vite.config.*` | Vite |
| `go.mod` | Go |
| `go.mod` + `chi` | Chi Router |
| `go.mod` + `gorm` | GORM |
| `pyproject.toml` + `fastapi` | FastAPI |
| `Cargo.toml` | Rust |

### Test Framework

| Pattern | Framework |
|---------|-----------|
| `"vitest"` in package.json | Vitest |
| `"jest"` in package.json | Jest |
| `pytest` in pyproject.toml | pytest |
| `*_test.go` files | Go test |

---

## CLAUDE.md Template

```markdown
# {Project Name}

## Stack

| Layer | Technology |
|-------|------------|
| Frontend | {detected} |
| Backend | {detected} |
| Database | {detected} |
| Package Manager | {detected} |

## Commands

| Command | Purpose |
|---------|---------|
| `{pm} dev` | Development server |
| `{pm} build` | Production build |
| `{pm} test` | Run tests |

## Environment Variables

| Variable | Description |
|----------|-------------|
{parsed from .env.example}

## Key Files

| Purpose | Path |
|---------|------|
| Entry point | {detected} |
| Routes | {detected} |

## Patterns

{Stack-specific patterns from detection}
```

---

## Constraints

- Max 500 lines for CLAUDE.md
- Memory file under 100 lines initially
- POSIX-compatible bash for hooks
- Never write secrets
- Use detected package manager in all command examples
