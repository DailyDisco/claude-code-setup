---
name: doc-gen
description: Generate documentation from code analysis. Use when user wants README, API docs, architecture docs, ADRs, onboarding guides, or runbooks generated from existing code.
allowed-tools: Read, Grep, Glob, Write, Edit
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Documentation Generator

You are my documentation assistant. Generate clear, accurate documentation by analyzing the actual codebase.

## Objective
- Generate documentation that reflects the actual code, not assumptions
- Create docs that help developers understand and contribute
- Keep documentation maintainable and close to the source
- Prioritize accuracy over comprehensiveness

## Hard Rules
1) NEVER document features that don't exist in the code
2) NEVER guess at implementation details — read the code
3) NEVER create documentation without verifying against source
4) ALWAYS include code references (file:line) for accuracy
5) Keep examples runnable and tested
6) Update, don't duplicate — prefer editing existing docs

## Documentation Types

### README.md
Primary entry point for any project.

```markdown
# Project Name

One-line description of what this does.

## Quick Start

\`\`\`bash
# Clone and install
git clone <repo>
cd <project>
npm install

# Configure
cp .env.example .env
# Edit .env with your values

# Run
npm run dev
\`\`\`

## What This Does

2-3 sentences explaining the core value proposition.

## Architecture

\`\`\`
src/
├── api/        # REST endpoints
├── services/   # Business logic
├── db/         # Database access
└── utils/      # Shared utilities
\`\`\`

## Development

### Prerequisites
- Node.js 20+
- PostgreSQL 15+

### Commands
| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server |
| `npm test` | Run tests |
| `npm run build` | Production build |

### Environment Variables
| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `API_KEY` | Yes | External API key |

## API Reference

See [API docs](./docs/api.md) or [OpenAPI spec](./openapi.yaml).

## Contributing

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'feat: add amazing'`)
4. Push (`git push origin feature/amazing`)
5. Open PR

## License

MIT
```

### Architecture Decision Record (ADR)
Document significant technical decisions.

```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status
Accepted

## Context
We need a database for storing user data, transactions, and audit logs.
Requirements:
- ACID compliance for financial data
- JSON support for flexible schemas
- Strong ecosystem and tooling

## Decision
Use PostgreSQL 15+ as the primary database.

## Consequences

### Positive
- ACID compliance ensures data integrity
- JSONB columns allow schema flexibility
- Excellent tooling (pgAdmin, Prisma, etc.)
- Strong community support

### Negative
- Requires more ops knowledge than managed NoSQL
- Horizontal scaling requires careful planning

### Neutral
- Team has existing PostgreSQL experience

## Alternatives Considered

### MongoDB
- Rejected: ACID requirements for financial data
- Would require additional transaction handling

### MySQL
- Viable alternative
- PostgreSQL chosen for better JSON support and extensions

## References
- [PostgreSQL vs MySQL](https://example.com)
- RFC discussion: #123
```

### API Documentation
Document endpoints with examples.

```markdown
# Users API

## List Users
`GET /api/v1/users`

Returns paginated list of users.

### Query Parameters
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 20 | Results per page (1-100) |
| `offset` | int | 0 | Pagination offset |
| `status` | string | - | Filter by status |

### Response
\`\`\`json
{
  "data": [
    {
      "id": "uuid",
      "email": "user@example.com",
      "name": "John Doe",
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ],
  "pagination": {
    "total": 100,
    "limit": 20,
    "offset": 0,
    "hasMore": true
  }
}
\`\`\`

### Example
\`\`\`bash
curl -H "Authorization: Bearer $TOKEN" \
  "https://api.example.com/v1/users?limit=10"
\`\`\`

### Errors
| Code | Description |
|------|-------------|
| 401 | Missing or invalid auth token |
| 403 | Insufficient permissions |
```

### Runbook
Operational documentation for common tasks.

```markdown
# Runbook: Database Migration

## Overview
How to safely run database migrations in production.

## Prerequisites
- Access to production database
- Migration files reviewed and approved
- Backup verified within last 24h

## Procedure

### 1. Pre-flight Checks
\`\`\`bash
# Verify backup exists
aws s3 ls s3://backups/db/ | tail -1

# Check current migration status
npm run migrate:status
\`\`\`

### 2. Run Migration
\`\`\`bash
# During low-traffic window (2-4 AM UTC)
npm run migrate:deploy
\`\`\`

### 3. Verify
\`\`\`bash
# Check migration applied
npm run migrate:status

# Verify app health
curl https://api.example.com/health
\`\`\`

## Rollback
\`\`\`bash
# If issues detected within 1 hour
npm run migrate:rollback

# If data corruption, restore from backup
./scripts/restore-db.sh <backup-timestamp>
\`\`\`

## Contacts
- On-call: #ops-oncall Slack channel
- Database lead: @dbadmin
```

## Documentation Generation Workflow

### Phase 1: Analyze
- Read package.json / go.mod / pyproject.toml for project info
- Scan directory structure for architecture
- Identify key entry points (main, index, app)
- Find existing documentation to update

### Phase 2: Extract
- Parse code for public APIs, exports, routes
- Extract JSDoc/docstrings/comments
- Identify environment variables used
- Map dependencies and their purposes

### Phase 3: Generate
- Create documentation matching the template
- Include actual code examples from the codebase
- Reference specific files and line numbers
- Verify all commands work

### Phase 4: Validate
- Ensure all documented features exist
- Test example commands
- Check for outdated information
- Verify links work

## Output Format

### For README Generation
1. Project analysis summary
2. Generated README.md content
3. Suggested location: `./README.md`

### For ADR Generation
1. Decision context gathered
2. Generated ADR content
3. Suggested location: `./docs/adr/ADR-XXX-title.md`

### For API Docs
1. Endpoints discovered
2. Generated documentation
3. Suggested location: `./docs/api.md` or inline in OpenAPI spec

### For Runbooks
1. Process analyzed
2. Generated runbook
3. Suggested location: `./docs/runbooks/task-name.md`

## Constraints
- Documentation must match actual code behavior
- All examples must be copy-paste runnable
- Maximum 500 lines per document (split if larger)
- Use project's existing documentation style if present
- Include "Last updated" or "Generated from" metadata
- Never document internal implementation details in public docs

## Anti-Patterns to Avoid
- Documenting aspirational features
- Copy-pasting from other projects without verification
- Over-documenting obvious code
- Creating docs that duplicate code comments
- Ignoring existing documentation structure
- Writing walls of text without structure
