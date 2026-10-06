---
paths: "**/{migrations,prisma}/**,**/schema.{prisma,sql},**/*.migration.{ts,js,go,sql}"
---

# Database Rules

Apply these rules when working with databases, migrations, and data access.

---

## Migration Safety

- **Never run destructive migrations without backup verification**
- Always write reversible migrations (up AND down)
- Test migrations on a copy of production data before deploying
- Use transactions for multi-step migrations
- Add explicit timeouts for long-running migrations
- Lock tables explicitly when needed (don't rely on implicit locks)

### Migration Checklist

Before deploying:
- [ ] Migration tested locally with production-like data
- [ ] Rollback migration tested
- [ ] Estimated execution time documented
- [ ] Backup verified
- [ ] Off-peak deployment scheduled (if > 1 minute)

---

## Indexing

- Index columns used in WHERE, JOIN, and ORDER BY clauses
- Use composite indexes for multi-column queries (order matters)
- Avoid over-indexing (slows writes, wastes space)
- Use partial indexes for filtered queries
- Review EXPLAIN output before adding indexes

### Index Anti-Patterns

- Indexing low-cardinality columns (boolean, status)
- Too many indexes on write-heavy tables
- Missing indexes on foreign keys
- Unused indexes (monitor and remove)

---

## N+1 Prevention

- **Always eager load associations** when iterating collections
- Use `JOIN` or subqueries instead of loops with queries
- Batch operations (insert/update multiple rows at once)
- Use database-side aggregations, not application-side

### Detection

```sql
-- PostgreSQL: Find slow queries
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;
```

---

## Connection Pooling

- Always use connection pooling in production
- Size pool based on: `pool_size = (core_count * 2) + spindle_count`
- Set connection timeouts (don't wait forever)
- Release connections promptly (use `defer` or `finally`)
- Monitor pool exhaustion

### Recommended Settings

| Setting | Development | Production |
|---------|-------------|------------|
| Pool Size | 5 | 20-50 |
| Idle Timeout | 30s | 10m |
| Connection Timeout | 5s | 10s |
| Statement Timeout | 30s | 60s |

---

## Query Safety

- Use parameterized queries (never string concatenation)
- Set statement timeouts for all queries
- Use `LIMIT` on unbounded queries
- Avoid `SELECT *` - specify columns explicitly
- Use `EXISTS` instead of `COUNT` for existence checks

---

## Data Integrity

- Define foreign key constraints at the database level
- Use `NOT NULL` unless null is a valid business state
- Add `CHECK` constraints for business rules
- Use `UNIQUE` constraints for natural keys
- Implement soft deletes with `deleted_at` timestamp

---

## Performance Patterns

### Pagination
- Use cursor-based pagination for large datasets
- Offset pagination only for small, static datasets
- Always include a stable sort column

### Caching
- Cache expensive queries with appropriate TTL
- Invalidate on writes (don't serve stale data)
- Use read replicas for read-heavy workloads

### Bulk Operations
- Batch inserts (100-1000 rows per statement)
- Use `COPY` for large data imports (PostgreSQL)
- Consider temporary tables for complex transformations

---

## Monitoring

Track these metrics:
- Query latency (p50, p95, p99)
- Connection pool utilization
- Slow query log
- Lock wait times
- Replication lag (if using replicas)
