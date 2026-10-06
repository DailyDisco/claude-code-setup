# Performance & Observability

Apply these rules when building production-ready systems.

---

## Logging

- Use structured JSON logs
- Include log levels: `debug`, `info`, `warn`, `error`
- Add correlation IDs for request tracing
- Never log sensitive data

```json
{
  "level": "info",
  "message": "User logged in",
  "userId": "123",
  "correlationId": "abc-def-ghi",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

---

## Metrics & Monitoring

- Track business-critical metrics
- Set up alerts on anomalies
- Monitor error rates, latency, throughput
- Use percentiles (p50, p95, p99) not just averages

---

## Performance Optimization

- **Profile before optimizing** — don't guess bottlenecks
- Measure impact of changes (before/after with real data)
- Optimize hot paths, not everything
- Consider caching strategies (but invalidate correctly)

### Measuring Impact

```
# Before: Identify the bottleneck
Request latency p95: 850ms
DB query time: 720ms (84% of request)

# After: Verify improvement
Added index on users.email
Request latency p95: 120ms (86% reduction)
```

---

## Memory & Resource Management

- Watch for memory leaks: unclosed connections, growing caches, event listener accumulation
- Set max sizes on in-memory caches (LRU eviction)
- Use streaming for large payloads — don't buffer entire files in memory
- Close database connections, file handles, and HTTP clients in `finally`/`defer`

---

## Database Performance

- Index frequently queried columns
- Avoid N+1 queries — use eager loading or batch queries
- Use connection pooling (tune pool size to `cores * 2 + spindle_count`)
- Monitor slow query logs
- Use `EXPLAIN ANALYZE` before adding indexes

---

## Frontend Performance

- Lazy load non-critical resources (routes, images, heavy components)
- Optimize bundle size — tree-shake, code-split by route
- Use proper caching headers (`Cache-Control`, `ETag`)
- Measure Core Web Vitals (LCP, FID, CLS)
- Debounce/throttle user input handlers (search, scroll, resize)

---

## API Performance

- Implement pagination for list endpoints (cursor-based for large datasets)
- Use appropriate HTTP caching (`Cache-Control`, `If-None-Match`)
- Consider rate limiting to protect against abuse
- Compress responses (gzip/brotli)
- Set request timeouts (30s default, 5s for internal services)

---

## Caching Strategy

| Layer | TTL | Use For |
|-------|-----|---------|
| Browser | Hours-days | Static assets, API responses with `Cache-Control` |
| CDN/Edge | Minutes-hours | Public pages, images, fonts |
| Application | Seconds-minutes | Expensive computations, API aggregations |
| Database | Query-level | Materialized views, query result cache |

**Cache invalidation**: Prefer TTL-based expiration. Use event-driven invalidation for data that must be immediately consistent.

---

## Load Testing Checklist

Before any major release or traffic spike:
- [ ] Identify expected peak load (requests/sec, concurrent users)
- [ ] Load test at 2x expected peak
- [ ] Monitor database connection pool under load
- [ ] Check for memory leaks during sustained load
- [ ] Verify graceful degradation (what fails first?)
- [ ] Test with realistic data volumes, not empty databases
