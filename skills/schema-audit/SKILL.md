---
name: schema-audit
description: Validate database schemas against best practices, detect drift between environments, and verify migration safety. Use when reviewing database changes or auditing schema health.
allowed-tools: Bash(psql:*), Bash(pg_dump:*), Bash(npx prisma:*), Bash(go run:*), mcp__dbhub__*, Read, Grep, Glob, Edit, Write
context-files:
  - ~/.config/agent-config/rules/database.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Schema Validation Assistant

Validate database schemas for best practices, consistency, and migration safety.

## Objective
- Audit database schemas for anti-patterns and issues
- Detect drift between schema definition and actual database
- Validate migrations before execution
- Check index coverage and query performance implications
- Ensure naming conventions are followed

## Hard Rules
1. NEVER execute destructive operations on production databases
2. ALWAYS recommend backup before schema changes
3. ALWAYS provide rollback strategy for any suggested changes
4. NEVER store or log database credentials
5. Flag any migration that could cause data loss

## Validation Workflow

### Phase 1: Schema Discovery
- Connect to database or read schema files
- Extract current schema structure
- Identify tables, columns, indexes, constraints
- Map relationships and foreign keys

### Phase 2: Best Practices Audit

#### Naming Conventions
```
✓ Tables: snake_case, plural (users, order_items)
✓ Columns: snake_case (created_at, user_id)
✓ Indexes: idx_{table}_{columns} (idx_users_email)
✓ Foreign Keys: fk_{table}_{referenced} (fk_orders_user)
✓ Primary Keys: {table}_pkey (users_pkey)
```

#### Required Columns
```
✓ Primary key (id or composite)
✓ created_at timestamp
✓ updated_at timestamp
✓ Soft delete: deleted_at (if applicable)
```

#### Data Types
```
✓ Use UUID for public identifiers
✓ Use BIGINT for internal IDs (if not UUID)
✓ Use TIMESTAMPTZ for timestamps (not TIMESTAMP)
✓ Use TEXT for variable strings (not VARCHAR without limit)
✓ Use JSONB for JSON data (not JSON)
```

### Phase 3: Index Analysis

#### Missing Index Detection
```sql
-- Find foreign keys without indexes
SELECT
    tc.table_name,
    kcu.column_name,
    'Missing index on foreign key' as issue
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN pg_indexes pi
    ON pi.tablename = tc.table_name
    AND pi.indexdef LIKE '%' || kcu.column_name || '%'
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND pi.indexname IS NULL;
```

#### Unused Index Detection
```sql
-- Find indexes with low usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan < 50
ORDER BY idx_scan;
```

#### Duplicate Index Detection
```sql
-- Find potentially duplicate indexes
SELECT
    a.indexname AS index1,
    b.indexname AS index2,
    a.tablename
FROM pg_indexes a
JOIN pg_indexes b ON a.tablename = b.tablename
    AND a.indexname < b.indexname
    AND (
        a.indexdef LIKE '%' || split_part(b.indexdef, '(', 2)
        OR b.indexdef LIKE '%' || split_part(a.indexdef, '(', 2)
    );
```

### Phase 4: Constraint Validation

#### Missing Constraints
- Foreign key relationships without FK constraints
- Columns that should have NOT NULL
- Missing CHECK constraints for enums/status fields
- Missing UNIQUE constraints for natural keys

### Phase 5: Migration Safety Check

For each migration file:
```
□ Has corresponding DOWN migration
□ Wrapped in transaction (or explicitly noted as non-transactional)
□ No data loss risk (or documented and approved)
□ Estimated execution time documented
□ Tested on production-like data volume
□ Lock implications documented
```

#### High-Risk Operations
Flag these for extra review:
- `DROP TABLE` / `DROP COLUMN`
- `ALTER COLUMN` type changes
- `TRUNCATE`
- Large table migrations (>1M rows)
- Index creation without `CONCURRENTLY`

## Output Format

### Schema Health Report

```
═══════════════════════════════════════════════════════════════
                    Schema Validation Report
═══════════════════════════════════════════════════════════════

Database: myapp_production
Tables: 45 | Indexes: 127 | Constraints: 89
Analyzed: 2025-01-15T10:30:00Z

───────────────────────────────────────────────────────────────
CRITICAL ISSUES (2)
───────────────────────────────────────────────────────────────

[CRITICAL] Missing index on foreign key
  Table: orders
  Column: customer_id
  Impact: Full table scan on customer lookups
  Fix: CREATE INDEX CONCURRENTLY idx_orders_customer_id ON orders(customer_id);

[CRITICAL] No primary key
  Table: audit_logs
  Impact: Cannot ensure row uniqueness, replication issues
  Fix: ALTER TABLE audit_logs ADD PRIMARY KEY (id);

───────────────────────────────────────────────────────────────
HIGH ISSUES (5)
───────────────────────────────────────────────────────────────

[HIGH] Missing NOT NULL constraint
  Table: users
  Column: email
  Impact: Data integrity risk
  Fix: ALTER TABLE users ALTER COLUMN email SET NOT NULL;

[HIGH] Using TIMESTAMP instead of TIMESTAMPTZ
  Table: events
  Column: occurred_at
  Impact: Timezone handling bugs
  Fix: ALTER TABLE events ALTER COLUMN occurred_at TYPE TIMESTAMPTZ;

... (more issues)

───────────────────────────────────────────────────────────────
MEDIUM ISSUES (12)
───────────────────────────────────────────────────────────────

[MEDIUM] Naming convention violation
  Table: UserPreferences (should be: user_preferences)
  Impact: Inconsistent codebase
  Fix: Rename table (requires application changes)

... (more issues)

───────────────────────────────────────────────────────────────
RECOMMENDATIONS
───────────────────────────────────────────────────────────────

1. Add missing indexes (2 critical)
   Priority: Immediate
   Estimated impact: 10x query performance improvement

2. Fix timestamp columns (3 tables)
   Priority: Next sprint
   Migration complexity: Medium

3. Add audit columns to new tables
   Priority: Ongoing
   Add to schema template

───────────────────────────────────────────────────────────────
SCHEMA DRIFT
───────────────────────────────────────────────────────────────

Comparing: prisma/schema.prisma vs database

+ Column: users.avatar_url (in schema, not in DB)
- Column: users.legacy_id (in DB, not in schema)
~ Column: products.price DECIMAL(10,2) → NUMERIC

Drift detected: 3 differences
Run: npx prisma db push --preview-feature to sync

═══════════════════════════════════════════════════════════════
                         Summary
═══════════════════════════════════════════════════════════════

Health Score: 72/100 (Fair)

Issues by Severity:
  Critical: 2
  High: 5
  Medium: 12
  Low: 8

Top Priority Actions:
  1. Create missing foreign key indexes
  2. Add primary key to audit_logs
  3. Fix timezone column types
```

## Integration with /migration-planner

When issues are found:
1. Generate migration files to fix issues
2. Test migrations on staging
3. Document rollback procedures
4. Schedule maintenance window for critical fixes

## Required Inputs
- Database connection string OR schema files (Prisma, migrations)
- Environment context (development, staging, production)

## Constraints
- Read-only analysis by default
- Never suggest fixes that could cause data loss without explicit user confirmation
- Maximum 100 issues per report (paginate if more)
