# Security Review

## Context
Use this prompt for security-focused code review, especially for authentication flows, data handling, API endpoints, and user input processing.

## Methodology

### Phase 1: Attack Surface Mapping
1. Identify all entry points (APIs, forms, file uploads, webhooks)
2. Map authentication and authorization boundaries
3. Document data flows involving sensitive information
4. List external integrations and trust boundaries

### Phase 2: OWASP Top 10 Check
1. **Injection** - SQL, NoSQL, OS command, LDAP injection points
2. **Broken Authentication** - Session management, credential handling
3. **Sensitive Data Exposure** - Encryption, data classification
4. **XML External Entities** - XML parsing vulnerabilities
5. **Broken Access Control** - Authorization checks, IDOR
6. **Security Misconfiguration** - Default configs, error handling
7. **XSS** - Output encoding, CSP headers
8. **Insecure Deserialization** - Object deserialization points
9. **Known Vulnerabilities** - Dependency versions
10. **Insufficient Logging** - Security event monitoring

### Phase 3: Authentication & Authorization
1. Password policies and storage (bcrypt/argon2)
2. Session management (timeout, rotation, invalidation)
3. Multi-factor authentication implementation
4. OAuth/OIDC configuration
5. API key/token handling
6. Role-based access control implementation

### Phase 4: Data Protection
1. Encryption at rest and in transit
2. PII handling and data minimization
3. Secrets management (no hardcoded secrets)
4. Backup and recovery security
5. Data retention and deletion

### Phase 5: Infrastructure
1. HTTPS enforcement
2. Security headers (CSP, HSTS, X-Frame-Options)
3. CORS configuration
4. Rate limiting and DDoS protection
5. Network segmentation

## Questions to Answer
- What is the most sensitive data in this system?
- What would an attacker target first?
- What happens if authentication is bypassed?
- Are there any implicit trust assumptions?
- What's the blast radius of a breach?

## Output Format

### Security Posture Summary
Overall assessment: [Critical/High/Medium/Low Risk]

### Attack Surface
| Entry Point | Auth Required | Data Sensitivity | Risk Level |
|-------------|---------------|------------------|------------|

### Findings
For each finding:
```
[CRITICAL/HIGH/MEDIUM/LOW] Title
CWE: CWE-XXX
Location: file:line
Description: What the vulnerability is
Exploit Scenario: How it could be exploited
Remediation: How to fix it
```

### Prioritized Remediation Plan
1. Critical fixes (do immediately)
2. High priority (this sprint)
3. Medium priority (next sprint)
4. Low priority (backlog)

### Security Checklist
- [ ] No hardcoded secrets
- [ ] Input validation on all entry points
- [ ] Output encoding for XSS prevention
- [ ] Parameterized queries for SQL
- [ ] Authentication on sensitive endpoints
- [ ] Authorization checks for resources
- [ ] Security headers configured
- [ ] Dependencies up to date
- [ ] Logging for security events
- [ ] Error messages don't leak info
