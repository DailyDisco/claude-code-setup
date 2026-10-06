---
name: dbhub-setup
description: Set up dbhub MCP server for per-project database access. Creates .mcp.json with dbhub config and .env.agent with DSN template.
allowed-tools: Read, Write, Edit, Bash(ls:*), Glob, AskUserQuestion
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Database MCP Setup

Configure dbhub for per-project database connections.

## Objective
- Create or update `.mcp.json` with dbhub configuration
- Add `DB_DSN` template to `.env.agent` or `.env.example`
- Optionally enable the MCP server in project settings

## Process

### 1. Detect Backend & Database Configuration
Scan the project to identify:

**Backend Framework Detection:**
| File/Pattern | Framework | Expected DB |
|--------------|-----------|-------------|
| `go.mod` + GORM imports | Go + GORM | PostgreSQL (preferred) |
| `package.json` + Prisma | Node.js + Prisma | Check `schema.prisma` |
| `package.json` + Drizzle | Node.js + Drizzle | Check `drizzle.config.*` |
| `requirements.txt` + SQLAlchemy | Python + SQLAlchemy | Check config |
| `requirements.txt` + Django | Python + Django | Check `settings.py` |
| `Gemfile` + ActiveRecord | Ruby + Rails | Check `database.yml` |

**Database Detection Methods:**
- `schema.prisma` → Look for `provider = "postgresql"` etc.
- `drizzle.config.ts` → Check dialect configuration
- `docker-compose.yml` → Look for `postgres`, `mysql`, `mariadb` images
- `.env.example` → Parse `DATABASE_URL` format hints
- Go files → Check GORM driver imports (`gorm.io/driver/postgres`)
- `config/database.yml` → Rails database adapter

### 2. Validate Database Compatibility
After detection, verify the database type makes sense:

```
Backend expects: PostgreSQL (detected from schema.prisma)
User requested:  MySQL
→ WARNING: Mismatch detected!
```

If mismatch detected:
1. Warn the user about the discrepancy
2. Ask if they want to:
   - Use the detected database type (recommended)
   - Override with their specified type (may cause issues)
   - Abort and fix configuration first

### 3. Check Existing MCP Configuration
- Look for existing `.mcp.json`
- Check if dbhub is already configured
- If configured, verify DSN format matches detected database

### 4. Gather Database Info
Ask user for:
- Database type (auto-detected, confirm or override)
- Connection details OR let them fill in `.env.agent` later
- Read-only mode preference (default: true for safety)

### 5. Create/Update .mcp.json

```json
{
  "mcpServers": {
    "db": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub"],
      "env": {
        "TRANSPORT": "stdio",
        "DSN": "${DB_DSN}",
        "READONLY": "true"
      }
    }
  }
}
```

If `.mcp.json` exists, merge the `db` server into existing config.

### 6. Add DSN Template

Add to `.env.agent` (create if needed):
```bash
# Database connection for dbhub MCP
# Format: postgres://user:pass@host:port/dbname?sslmode=disable
export DB_DSN=""
```

Add to `.env.example` if it exists:
```bash
# Database connection for Claude Code dbhub MCP
DB_DSN=postgres://user:password@localhost:5432/dbname?sslmode=disable
```

### 7. Update .gitignore

Ensure `.env.agent` is ignored:
```
.env.agent
```

## DSN Format Reference

| Database | DSN Format |
|----------|------------|
| PostgreSQL | `postgres://user:pass@host:5432/dbname?sslmode=disable` |
| MySQL | `mysql://user:pass@host:3306/dbname` |
| MariaDB | `mariadb://user:pass@host:3306/dbname` |
| SQLite | `sqlite:///path/to/database.db` |
| SQL Server | `sqlserver://user:pass@host:1433?database=dbname` |

## Multiple Databases

For projects needing multiple database connections, use unique IDs:

```json
{
  "mcpServers": {
    "main-db": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub"],
      "env": {
        "TRANSPORT": "stdio",
        "DSN": "${MAIN_DB_DSN}",
        "ID": "main"
      }
    },
    "analytics-db": {
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub"],
      "env": {
        "TRANSPORT": "stdio",
        "DSN": "${ANALYTICS_DB_DSN}",
        "ID": "analytics",
        "READONLY": "true"
      }
    }
  }
}
```

## Hard Rules
1. NEVER write actual credentials to any file
2. Always use environment variable expansion (`${DB_DSN}`)
3. Default to `READONLY: true` for safety
4. Preserve existing `.mcp.json` servers when merging
5. Always add `.env.agent` to `.gitignore`

## Output
After setup, inform user:
1. Location of `.mcp.json`
2. Where to set their `DB_DSN` value
3. How to test: restart Claude Code and use `mcp__db__*` tools
