# Security Rules

Apply these rules whenever working with authentication, authorization, user input, or external data.

---

## Input Validation

- Sanitize all user input
- Validate at **system boundaries** (API, forms, external data)
- Use Zod or equivalent for runtime validation
- Never trust client-side validation alone

```
// BAD - string concatenation (SQL injection risk)
query(`SELECT * FROM users WHERE id = '${userId}'`)

// GOOD - parameterized query
query('SELECT * FROM users WHERE id = $1', [userId])
```

---

## Authentication & Authorization

- Enforce authentication & authorization explicitly on **every endpoint**
- Use industry-standard patterns (JWT, OAuth 2.0, session tokens)
- Never store sensitive data in localStorage (use httpOnly cookies)
- Implement proper CSRF protection

### Session Management

- Set session timeouts (idle + absolute)
- Invalidate sessions on password change and logout
- Rotate session tokens after privilege escalation (login, role change)
- Store sessions server-side or use signed, encrypted cookies

---

## Rate Limiting

- Apply rate limiting at API boundaries (auth endpoints especially)
- Use sliding window or token bucket algorithms
- Return `429 Too Many Requests` with `Retry-After` header
- Rate limit by user AND by IP (prevent both brute force and DDoS)

---

## Data Protection

- HTTPS for all external traffic
- Never log sensitive fields (passwords, tokens, PII)
- Hash passwords with bcrypt/argon2 (never MD5/SHA1)
- Encrypt sensitive data at rest

### Content Security Policy

- Set `Content-Security-Policy` headers on all responses
- Restrict `script-src` to known origins (no `unsafe-inline` in production)
- Use `SameSite=Strict` or `SameSite=Lax` on cookies

---

## Logging & Auditing

- Log security-relevant events:
  - Authentication attempts (success/failure)
  - Permission changes
  - Sensitive data access
- Include correlation IDs for tracing
- Never log credentials or tokens

---

## Common Vulnerabilities (OWASP Top 10)

Guard against:

- **Injection** — Parameterized queries, input sanitization
- **XSS** — Output encoding, CSP headers
- **CSRF** — Anti-CSRF tokens, SameSite cookies
- **Broken Access Control** — Explicit authz checks on every endpoint
- **Security Misconfiguration** — Secure defaults, no debug in prod

---

## Secrets Management

- Never commit secrets to version control
- Use environment variables or secret managers
- Rotate credentials regularly (90-day maximum for API keys)
- Warn if code patterns resemble API keys or tokens

### Supply Chain Security

- Use lockfiles (`package-lock.json`, `go.sum`) and commit them
- Run `npm audit` / `go mod verify` in CI
- Pin major versions; review changelogs before upgrading
- Avoid dependencies with known vulnerabilities or unmaintained packages
