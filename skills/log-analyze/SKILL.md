---
name: log-analyze
description: Analyze application logs to identify patterns, errors, performance issues, and anomalies. Use for debugging production issues, monitoring health, or investigating incidents.
allowed-tools: Bash(grep:*), Bash(awk:*), Bash(jq:*), Bash(curl:*), Bash(tail:*), Bash(head:*), Read, Grep, Glob, Write
context-files:
  - ~/.config/agent-config/rules/performance.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Log Analysis Assistant

Analyze application logs to identify errors, patterns, and performance issues.

## Objective
- Parse and analyze structured (JSON) and unstructured logs
- Identify error patterns and frequencies
- Detect performance anomalies
- Correlate events across services
- Generate actionable insights

## Hard Rules
1. NEVER expose sensitive data (tokens, passwords, PII) in analysis output
2. ALWAYS sanitize log excerpts before displaying
3. NEVER store raw logs - only aggregated analysis
4. ALWAYS include timestamps in findings
5. Correlate by request ID when available

## Analysis Workflow

### Phase 1: Log Discovery

```bash
# Common log locations
/var/log/app/*.log
./logs/*.log
~/.pm2/logs/*.log
docker logs <container>

# Structured log formats
- JSON lines (one JSON object per line)
- Common Log Format (Apache/Nginx)
- Combined Log Format
- Syslog format
```

### Phase 2: Log Parsing

#### JSON Logs
```bash
# Extract errors from JSON logs
cat app.log | jq -c 'select(.level == "error")'

# Group by error message
cat app.log | jq -r 'select(.level == "error") | .message' | sort | uniq -c | sort -rn

# Filter by time range
cat app.log | jq -c 'select(.timestamp > "2025-01-15T10:00:00")'
```

#### Unstructured Logs
```bash
# Extract error lines
grep -E "(ERROR|FATAL|Exception|Traceback)" app.log

# Extract with context
grep -B2 -A5 "Exception" app.log

# Time-based filtering
awk '/2025-01-15 10:/ && /ERROR/' app.log
```

### Phase 3: Pattern Detection

#### Error Frequency Analysis
```bash
# Count errors per minute
cat app.log | jq -r 'select(.level == "error") | .timestamp[:16]' | uniq -c

# Group similar errors
cat app.log | jq -r 'select(.level == "error") | .message' | \
  sed 's/[0-9a-f-]\{36\}/UUID/g' | \  # Normalize UUIDs
  sed 's/[0-9]\+/N/g' | \              # Normalize numbers
  sort | uniq -c | sort -rn
```

#### Performance Analysis
```bash
# Extract response times
cat app.log | jq -r 'select(.duration_ms) | "\(.timestamp) \(.duration_ms)"'

# Find slow requests (>1s)
cat app.log | jq -c 'select(.duration_ms > 1000)'

# P95 response time
cat app.log | jq -r '.duration_ms' | sort -n | awk '{a[NR]=$1} END {print a[int(NR*0.95)]}'
```

### Phase 4: Correlation

```bash
# Trace request across services
REQUEST_ID="abc-123"
grep "$REQUEST_ID" service-a.log service-b.log service-c.log | sort -t: -k2

# Timeline reconstruction
cat combined.log | jq -c 'select(.request_id == "abc-123")' | sort -t'"' -k4
```

### Phase 5: Anomaly Detection

- Sudden increase in error rate
- Unusual response time spikes
- New error types not seen before
- Missing expected log entries
- Gaps in log timestamps

## Output Format

### Log Analysis Report

```
═══════════════════════════════════════════════════════════════
                     Log Analysis Report
═══════════════════════════════════════════════════════════════

Source: /var/log/app/api.log
Time Range: 2025-01-15 00:00:00 to 2025-01-15 23:59:59
Total Entries: 1,247,382
Analysis Time: 12.3 seconds

───────────────────────────────────────────────────────────────
📊 LOG LEVEL DISTRIBUTION
───────────────────────────────────────────────────────────────

Level     Count      Percentage    Trend (vs yesterday)
────────────────────────────────────────────────────────────
DEBUG     892,451    71.5%         ━━━━━━━━━━━━━━━ (normal)
INFO      298,234    23.9%         ━━━━━━━━━━━━━━━ (normal)
WARN       42,891     3.4%         ━━━━━━━━━━━━━━━ (+15% ⚠️)
ERROR      13,672     1.1%         ━━━━━━━━━━━━━━━ (+45% 🔴)
FATAL         134     0.01%        ━━━━━━━━━━━━━━━ (+200% 🔴)

───────────────────────────────────────────────────────────────
🔴 ERROR ANALYSIS
───────────────────────────────────────────────────────────────

Top 10 Errors by Frequency:

1. Database connection timeout (3,421 occurrences)
   First seen: 10:23:45
   Last seen: 14:56:12
   Peak: 10:30-10:45 (892 errors/min)
   Sample:
     "Connection to postgres:5432 timed out after 30000ms"

   Likely cause: Database overload or network issue
   Related: DB CPU spike at 10:25 (from metrics)

2. JWT token expired (2,891 occurrences)
   Pattern: Evenly distributed throughout day
   Sample:
     "Token expired at 2025-01-15T10:00:00Z"

   Status: Expected behavior (users with stale tokens)

3. External API rate limit exceeded (1,892 occurrences)
   First seen: 12:00:00
   Pattern: Burst at top of each hour
   Sample:
     "Rate limit exceeded for api.stripe.com: 429"

   Action needed: Implement request queuing

4. File not found: /uploads/* (1,234 occurrences)
   Pattern: Various files, consistent rate
   Sample:
     "ENOENT: no such file /uploads/avatar-[UUID].jpg"

   Likely cause: Orphaned file references in database

5. JSON parse error (987 occurrences)
   Source: POST /api/webhooks/stripe
   Sample:
     "Unexpected token '<' at position 0"

   Likely cause: HTML error page from upstream

───────────────────────────────────────────────────────────────
⚡ PERFORMANCE ANALYSIS
───────────────────────────────────────────────────────────────

Response Time Percentiles:
  P50: 45ms
  P75: 123ms
  P90: 287ms
  P95: 534ms ⚠️ (target: <500ms)
  P99: 1,892ms 🔴 (target: <1000ms)

Slowest Endpoints:
┌─────────────────────────────────────────────────────────────┐
│ Endpoint                      │ Avg    │ P99    │ Calls    │
├─────────────────────────────────────────────────────────────┤
│ GET /api/reports/generate     │ 2.3s   │ 8.5s   │ 1,234    │
│ POST /api/search              │ 890ms  │ 3.2s   │ 45,678   │
│ GET /api/users/:id/activity   │ 456ms  │ 2.1s   │ 23,456   │
│ POST /api/orders              │ 234ms  │ 1.8s   │ 12,345   │
│ GET /api/products             │ 123ms  │ 890ms  │ 89,012   │
└─────────────────────────────────────────────────────────────┘

Slowest Request:
  Time: 10:34:56
  Endpoint: GET /api/reports/generate
  Duration: 32,456ms
  Request ID: req-abc-123
  User: user@example.com
  Trace: Database query took 31,234ms

───────────────────────────────────────────────────────────────
📈 TRAFFIC PATTERNS
───────────────────────────────────────────────────────────────

Requests per Hour:
00:00 ████░░░░░░░░░░░░░░░░  12,345
01:00 ███░░░░░░░░░░░░░░░░░   8,234
...
09:00 ████████████████████  89,012  (peak)
10:00 ███████████████████░  82,345
...
23:00 █████░░░░░░░░░░░░░░░  15,678

Peak Traffic: 09:00-10:00 (89,012 requests)
Lowest Traffic: 03:00-04:00 (4,567 requests)

───────────────────────────────────────────────────────────────
🔍 ANOMALIES DETECTED
───────────────────────────────────────────────────────────────

1. Error Rate Spike (10:30-10:45)
   Normal rate: 0.5% errors
   Spike rate: 8.3% errors
   Duration: 15 minutes
   Correlated: Database timeout errors
   Resolution: Auto-recovered at 10:45

2. Missing Logs Gap (14:23:15 - 14:23:45)
   Duration: 30 seconds
   Expected entries: ~500
   Actual entries: 0
   Possible cause: Log rotation, service restart, or network issue

3. New Error Type Appeared
   First occurrence: 16:45:23
   Error: "Redis READONLY: cannot write to replica"
   Count: 23 occurrences
   Action: Investigate Redis failover

───────────────────────────────────────────────────────────────
🔗 REQUEST CORRELATION
───────────────────────────────────────────────────────────────

Failed Request Trace (req-xyz-789):

10:34:56.123 [api-gateway]   INFO  Request received: GET /api/orders/123
10:34:56.125 [auth-service]  INFO  Token validated for user-456
10:34:56.128 [order-service] INFO  Fetching order 123
10:34:56.234 [order-service] WARN  Cache miss for order 123
10:34:56.235 [order-service] INFO  Querying database
10:34:57.456 [order-service] ERROR Connection timeout to postgres
10:34:57.457 [order-service] ERROR Failed to fetch order: timeout
10:34:57.458 [api-gateway]   ERROR Request failed: 500 Internal Server Error

Root Cause: Database connection timeout after 1.2s

───────────────────────────────────────────────────────────────
💡 RECOMMENDATIONS
───────────────────────────────────────────────────────────────

1. [CRITICAL] Investigate database timeout spike at 10:30
   - Check database metrics for that time
   - Review slow query log
   - Consider connection pool sizing

2. [HIGH] Implement rate limit handling for Stripe API
   - Add exponential backoff
   - Queue requests near limit

3. [MEDIUM] Clean up orphaned file references
   - Run data integrity check
   - Add cascade delete or cleanup job

4. [LOW] Review JWT token refresh strategy
   - 2,891 expired token errors is high
   - Consider proactive refresh before expiry

═══════════════════════════════════════════════════════════════
                         Summary
═══════════════════════════════════════════════════════════════

Health Score: 72/100 (Fair)

Key Metrics:
  Error Rate: 1.1% (target: <1%)
  P95 Response: 534ms (target: <500ms)
  Availability: 99.2% (target: 99.9%)

Action Items: 4 (1 critical, 1 high, 2 medium)
```

## Real-Time Analysis Commands

```bash
# Follow logs with filtering
tail -f app.log | jq -c 'select(.level == "error")'

# Monitor error rate
while true; do
  COUNT=$(tail -1000 app.log | jq 'select(.level == "error")' | wc -l)
  echo "$(date): $COUNT errors in last 1000 entries"
  sleep 60
done

# Alert on pattern
tail -f app.log | grep --line-buffered "FATAL" | while read line; do
  echo "ALERT: $line"
done
```

## Required Inputs
- Log file path(s) or log stream
- Time range (optional, defaults to last 24h)
- Focus area (errors, performance, specific endpoint)

## Constraints
- Process maximum 10GB of logs per analysis
- Sampling for very large log files
- Redact PII and secrets from all output
- Cache aggregated results for 1 hour
