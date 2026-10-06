---
paths: "**/{api,routes,handlers,controllers}/**"
---

# API Design Rules

Apply these rules when designing and implementing REST or GraphQL APIs.

---

## REST Conventions

### URL Structure

```
GET    /resources          # List resources
GET    /resources/:id      # Get single resource
POST   /resources          # Create resource
PUT    /resources/:id      # Replace resource
PATCH  /resources/:id      # Partial update
DELETE /resources/:id      # Delete resource
```

### Naming

- Use plural nouns for collections (`/users`, not `/user`)
- Use kebab-case for multi-word paths (`/user-profiles`)
- Use camelCase for query parameters and JSON fields
- Nest related resources: `/users/:id/orders`
- Max nesting depth: 2 levels

---

## Versioning

- Version in URL path: `/api/v1/resources`
- Increment major version only for breaking changes
- Support N-1 versions minimum
- Document deprecation timeline

### Breaking Changes

These require version bump:
- Removing fields or endpoints
- Changing field types
- Changing required/optional status
- Modifying error codes

---

## Request/Response Format

### Successful Response

```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "perPage": 20,
    "total": 100
  }
}
```

### Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description",
    "details": [
      { "field": "email", "message": "Invalid format" }
    ],
    "requestId": "abc-123"
  }
}
```

---

## Error Codes

Use consistent HTTP status codes:

| Code | Usage |
|------|-------|
| 200 | Success (GET, PUT, PATCH) |
| 201 | Created (POST) |
| 204 | No Content (DELETE) |
| 400 | Bad Request (validation) |
| 401 | Unauthorized (no/invalid auth) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (duplicate, state conflict) |
| 422 | Unprocessable Entity (business logic) |
| 429 | Rate Limited |
| 500 | Internal Server Error |

---

## Pagination

### Cursor-Based (Preferred)

```
GET /resources?cursor=abc123&limit=20

Response:
{
  "data": [...],
  "meta": {
    "nextCursor": "def456",
    "hasMore": true
  }
}
```

### Offset-Based (Simple cases only)

```
GET /resources?page=2&perPage=20

Response:
{
  "data": [...],
  "meta": {
    "page": 2,
    "perPage": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

---

## Filtering & Sorting

### Filtering

```
GET /resources?status=active&createdAfter=2025-01-01
GET /resources?filter[status]=active&filter[type]=premium
```

### Sorting

```
GET /resources?sort=createdAt       # Ascending
GET /resources?sort=-createdAt      # Descending
GET /resources?sort=status,-date    # Multiple fields
```

---

## Rate Limiting

- Return rate limit headers on every response:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

- Return 429 with `Retry-After` header when exceeded
- Implement per-user and per-IP limits
- Use sliding window algorithm

---

## Authentication

- Use `Authorization: Bearer <token>` header
- Never pass tokens in URLs (logged in access logs)
- Include auth errors in 401 response body
- Support token refresh without re-authentication

---

## Idempotency

- GET, PUT, DELETE must be idempotent
- POST should accept `Idempotency-Key` header
- Return cached response for duplicate idempotency keys
- Store idempotency keys for 24 hours minimum

---

## Documentation

Every endpoint must document:
- URL and HTTP method
- Request body schema (with examples)
- Response schema (with examples)
- Error cases
- Authentication requirements
- Rate limits

Use OpenAPI 3.0+ specification.

---

## Performance

- Set appropriate cache headers (`Cache-Control`, `ETag`)
- Support conditional requests (`If-None-Match`, `If-Modified-Since`)
- Compress responses (gzip/brotli)
- Use field selection: `GET /users/:id?fields=id,name,email`
- Implement request timeouts (30s default)
