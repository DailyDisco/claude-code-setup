---
name: full-stack-optimizer
description: Systematic optimization framework for production web applications. Use when user asks to optimize their app, audit the codebase, find bottlenecks, review architecture, assess tech debt, or prepare for scaling. Provides deep analysis across frontend, backend, data, infrastructure, and DevOps layers with prioritized, risk-assessed improvements.
allowed-tools: Read, Grep, Glob, Bash(npm:*), Bash(go:*), Bash(docker:*)
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Full-Stack Application Optimizer Skill

## Purpose
Systematic, high-impact optimization framework for production web applications. Provides deep analysis across all system layers (frontend, backend, data, infrastructure, DevOps) with prioritized, risk-assessed improvements.

## When to Use This Skill
- User explicitly requests: "optimize my app", "audit the codebase", "find bottlenecks"
- User mentions: performance issues, tech debt, scaling preparation, production incidents
- User asks for: improvement roadmap, risk assessment, architecture review
- **Always read this skill BEFORE starting any full-stack optimization work**

## When NOT to Use
- Single-file debugging or isolated feature development
- User hasn't granted explicit permission for comprehensive analysis
- Quick fixes or hotfixes (use targeted debugging instead)

---

## Core Philosophy

### Impact Formula
**Impact × Likelihood × Effort Efficiency > "Nice to Have"**

- **Impact**: User pain × Business risk × System health effect
- **Likelihood**: How often will this matter? (Daily/Weekly/Rare)
- **Effort**: Hours to implement + test + deploy + monitor

### Quality Principles
1. **No code until Phase 3 approved** - Planning before execution
2. **Minimal diffs** - Smallest change for maximum impact
3. **Existing patterns** - Reuse, don't reinvent
4. **Measured outcomes** - Metrics or GTFO
5. **Small, safe steps** - One improvement at a time

### Anti-Patterns to Avoid
- Framework rewrites or "modernization for the sake of it"
- Adding features disguised as "optimizations"
- Big-bang refactors without incremental value
- Optimizing for edge cases before fixing common paths
- Silent assumptions - always verify in actual code

---

## Phase 0: Pre-Flight Guardrails

**STOP and verify:**
- [ ] User has granted permission for comprehensive analysis
- [ ] Full codebase access via @Codebase or file uploads
- [ ] Current deployment/production context is known
- [ ] Tech stack is identified (framework versions, key dependencies)

**Constraints:**
- No new frameworks or language switches
- No architectural rewrites without explicit approval
- Every finding must cite actual code locations
- Uncertain assumptions must be flagged with [VERIFY]

---

## Phase 1: Multi-Layer Discovery (REQUIRED - No Code Changes)

### 1.1 Frontend Architecture Deep Dive

**Framework & Patterns**
- Framework: React/Vue/Svelte/Next/Nuxt/Remix? Version?
- Routing: File-based? Client-side? SSR/SSG strategy?
- State: Redux/Zustand/Jotai/Context? Server state (TanStack Query/SWR)?
- Data Fetching: REST/GraphQL/tRPC? Location (components/hooks/services)?
- Build Tool: Vite/Webpack/Turbopack? Bundle splitting config?

**Component Architecture**
- Design system/component library in use or ad-hoc?
- Shared component patterns (location, naming, exports)
- Prop drilling vs composition patterns
- Form libraries (React Hook Form/Formik/uncontrolled)?

**Frontend Performance Indicators**
- Bundle size: Total? Per route? Largest chunks?
- Code splitting: Route-based? Component-based? Dynamic imports?
- Image optimization: Next/Image or manual? Lazy loading?
- Hydration cost: SSR payload size? Streaming? Progressive enhancement?
- Re-render hotspots: Expensive components, missing memoization
- Network waterfalls: Sequential requests? Prefetch strategy?

**Frontend Build & Tooling**
- TypeScript strictness level and coverage gaps
- Linting: ESLint rules, Prettier, config enforcement
- Type generation: from OpenAPI/GraphQL/manual?
- Environment handling: .env files, runtime config, secrets exposure risk

### 1.2 Backend Architecture Deep Dive

**Framework & API Design**
- Framework: Express/Fastify/Nest/Go/FastAPI/Django? Version?
- API Style: REST (OpenAPI spec?), GraphQL (schema-first?), tRPC?
- Route organization: Controllers? Handlers? Monolithic vs modular?
- Middleware stack: Auth, logging, error handling, validation, CORS

**Request Lifecycle**
- Authentication: JWT? Sessions? OAuth flow? Token refresh strategy?
- Authorization: RBAC? ABAC? Middleware vs inline checks?
- Input validation: Joi/Zod/class-validator? Where enforced?
- Error handling: Consistent error shapes? HTTP status codes? Client error mapping?

**Backend Performance Indicators**
- Slow endpoints: >500ms response time? DB-bound? CPU-bound?
- N+1 queries: ORM usage patterns, missing eager loading
- Database connection: Pooling config, connection leaks, timeout settings
- Background jobs: Queue system (Bull/BullMQ/Celery)? Failure handling?
- Rate limiting: Per-user? Per-IP? API key-based?
- Caching: In-memory? Redis? CDN? Cache invalidation strategy?

**API Contracts & Client Integration**
- Type safety: Shared types? Code generation? Drift detection?
- Error contracts: Consistent shape? Field-level errors for forms?
- Pagination: Cursor? Offset? Consistent across endpoints?
- Versioning: API version strategy? Deprecation handling?

### 1.3 Data Layer Deep Dive

**Database Schema & Health**
- Database: PostgreSQL/MySQL/MongoDB? Version? Hosting (RDS/managed)?
- ORM/Query Builder: Prisma/TypeORM/Sequelize/SQLAlchemy/GORM?
- Migration strategy: Tool (Prisma/Flyway/Alembic)? Rollback safety?
- Schema design: Normalization level? Denormalization for reads?
- Indexing: Missing indexes on foreign keys, WHERE clauses, ORDER BY?
- Query analysis: Slow query log? EXPLAIN plans reviewed?

**Data Integrity & Constraints**
- Foreign key constraints: Enforced? Cascades defined?
- Unique constraints: Business logic vs DB level?
- NULL handling: Required fields, default values
- Soft deletes: Implemented? Indexed? Bloat risk?

**Data Operations**
- Connection pooling: Config, max connections, idle timeout
- Transaction patterns: ACID guarantees, isolation levels
- Backup strategy: Automated? Tested restores? RPO/RTO?
- Archival/retention: Old data cleanup? Log table growth?

**Caching Strategy**
- Layers: Client (SWR), Server (Redis), CDN (Cloudflare)
- Cache keys: Consistent naming? Collision risk?
- Invalidation: On-write? TTL-based? Stale-while-revalidate?
- Cache headers: Correct for static vs dynamic content?

### 1.4 Security Posture (Critical Path)

**Authentication & Session Management**
- Login flow: Credentials handling, password hashing (bcrypt/argon2?)
- Token storage: httpOnly cookies? localStorage? sessionStorage?
- Token lifecycle: Expiry, refresh, revocation
- Logout: Token invalidation? Server-side session cleanup?
- Password reset: Secure flow? Email verification? Rate limiting?

**Authorization & Access Control**
- Server-side enforcement: All protected routes? No client-only gates?
- Role/permission checks: Consistent middleware? Bypasses possible?
- IDOR risks: User ID validation? Object ownership checks?
- Tenant isolation (if multi-tenant): Data leakage risks? Row-level security?

**Input Validation & Output Encoding**
- SQL injection: Parameterized queries everywhere? ORM escaping?
- XSS: User content sanitization? CSP headers? React dangerouslySetInnerHTML usage?
- Path traversal: File upload paths validated? Serving static files safely?
- SSRF: URL validation on server-side fetch/requests?

**Infrastructure Security**
- CORS: Configured correctly? Overly permissive origins?
- CSRF: Tokens for state-changing requests? SameSite cookies?
- Rate limiting: Login endpoints? API endpoints? DDoS mitigation?
- Secrets management: .env in .gitignore? Production secrets in vault/KMS?
- Dependency scanning: npm audit/safety? Known CVEs? Outdated packages?
- Headers: HSTS? X-Frame-Options? Content-Security-Policy?

**File Upload Safety (if applicable)**
- File type validation: MIME check + magic bytes?
- Size limits: Enforced? DDoS via large uploads?
- Storage: Direct to S3/GCS? Virus scanning?
- Filename sanitization: Path traversal via filename?

### 1.5 Testing & CI/CD Posture

**Test Coverage & Quality**
- Unit tests: Framework (Jest/Vitest/pytest)? Coverage % on critical paths?
- Integration tests: API contracts? DB interactions? Auth flows?
- E2E tests: Playwright/Cypress? Critical user journeys covered?
- Test data: Factories/fixtures? Test DB strategy (in-memory/Docker)?
- Mocks: Service mocks for external APIs? Consistent mocking patterns?

**CI/CD Pipeline**
- Gates: Lint → Typecheck → Test → Build? Blocking on failure?
- Deployment: Blue-green? Canary? Rollback process?
- Database migrations: Run before/after deploy? Backward compatible?
- Environment parity: Dev/staging/prod config drift?
- Monitoring: Error tracking (Sentry)? Logs (CloudWatch/Datadog)?

**Critical Path Test Gaps**
- Auth flows: Login/logout/refresh tested?
- Payment flows (if applicable): Integrated tests?
- FE↔BE contract tests: Type safety verified? Error cases tested?
- Failure mode tests: Network errors, timeouts, 500 errors handled?

### 1.6 UX, Accessibility & User Flows

**Core User Journeys**
- Critical paths: Signup → Login → Core action → Success
- Error recovery: What happens when API fails? Retry UX?
- Loading states: Skeleton screens? Spinners? Perceived performance?
- Empty states: First-time user guidance? "No results" messaging?

**Form Handling**
- Client-side validation: Real-time feedback? Consistent rules?
- Server error mapping: Field-level errors displayed correctly?
- Submit state: Disabled during submission? Success/error toast?
- Autosave: Draft state? Lost work prevention?

**Accessibility (A11y)**
- Keyboard navigation: Tab order? Focus traps in modals?
- Screen reader: Semantic HTML? ARIA labels on interactive elements?
- Color contrast: WCAG AA compliant? Color-blind safe?
- Focus management: Visible focus states? Skip links?

**Responsive & Performance**
- Mobile: Touch targets ≥44px? Hamburger menu vs desktop nav?
- Layout shifts: CLS score? Skeleton dimensions match content?
- Font loading: FOUT/FOIT strategy? System font fallback?

### 1.7 DevOps, Infrastructure & Observability

**Deployment Architecture**
- Hosting: Vercel/Netlify/AWS/GCP? Regions? CDN config?
- Containerization: Docker? K8s? Compose for local dev?
- Scaling: Auto-scaling rules? Load balancer config?
- Secrets: Environment variables? KMS/Secrets Manager?

**Monitoring & Logging**
- Error tracking: Sentry/Rollbar? Error rate alerts?
- Performance monitoring: New Relic/Datadog? Slow query alerts?
- Logs: Structured logging? Centralized (CloudWatch/ELK)?
- Uptime monitoring: Pingdom/UptimeRobot? Status page?
- Alerting: PagerDuty/Slack? On-call rotation?

**Disaster Recovery**
- Backups: Automated? Offsite? Tested restores?
- Incident response: Runbook? Rollback procedure?
- Database: Point-in-time recovery? Replica lag monitoring?

### 1.8 Code Quality & Maintainability

**Code Organization**
- Folder structure: Feature-based? Layer-based? Consistent?
- Naming conventions: Consistent file/folder/variable naming?
- Module size: Files >500 lines? Functions >50 lines?
- Duplication: Copy-paste code? Extract to shared utilities?

**Technical Debt Indicators**
- TODO/FIXME/HACK comments: How many? Priority?
- Commented-out code: Dead code to remove?
- Unused dependencies: npm depcheck results?
- Type coverage: `any` usage? `@ts-ignore` count?
- Linting violations: ESLint errors/warnings count?

**Error Handling Consistency**
- Try-catch patterns: Consistent across codebase?
- Error logging: Sufficient context? User-safe messages?
- Retry logic: Exponential backoff? Circuit breakers?

### 1.9 Missing Features (UX-Critical Only)

**Bounded, High-Impact Frontend Gaps**
- Error boundaries: Prevent white screen crashes?
- Global toast/notification system: User feedback for actions?
- Session expiry handling: Auto re-auth modal?
- Offline indicators: "No connection" banner?
- Pagination/infinite scroll: Where list length is unbounded?
- Settings/account pages: Required for security compliance?
- Bulk actions: Multi-select + batch operations?
- Export functionality: Download reports/data?

**Rule:** Only include if:
- Directly reduces support burden or critical user frustration
- Small/medium effort (< 1 week)
- Not a product redesign

### 1.10 Environment & Configuration

**Environment Management**
- .env files: .env.example exists? Secrets documented?
- Feature flags: LaunchDarkly/ConfigCat? Kill switches?
- Config validation: Startup checks for required env vars?
- Multi-environment: Dev/staging/prod config differences?

---

## Phase 1 Output Format

Deliver a structured report with:
```markdown
# Full-Stack Optimization Audit: [Project Name]

## Executive Summary
- Tech Stack: [Frontend + Backend + DB + Infra]
- Overall Health Score: [Red/Yellow/Green per layer]
- Critical Risks: [Count & severity]
- Estimated Effort for Top 3: [Hours]

## 1. System Architecture Map
[ASCII diagram or bullet hierarchy of FE → BE → DB → External Services]

## 2. Security Findings
- Critical: [List with file locations]
- Medium: [List]
- Low: [List]

## 3. Performance Bottlenecks
- Frontend: [Bundle size, waterfalls, re-renders]
- Backend: [Slow endpoints, N+1 queries]
- Database: [Missing indexes, slow queries]
- Infrastructure: [CDN misses, cold starts]

## 4. Test Coverage Gaps
- Critical paths untested: [List]
- Missing test types: [Unit/Integration/E2E]
- CI/CD risks: [Deployment safety issues]

## 5. UX & Accessibility Issues
- Broken user flows: [List]
- Missing error recovery: [List]
- A11y violations: [Count + examples]

## 6. Code Quality Issues
- High-risk areas: [File paths + issue]
- Tech debt hotspots: [TODO count, duplication]
- Maintainability risks: [Module complexity]

## 7. Infrastructure & DevOps
- Deployment risks: [Migration safety, rollback]
- Monitoring gaps: [Missing alerts]
- Disaster recovery: [Backup/restore status]

## 8. Missing Features (Bounded)
- [Feature]: Impact + Effort estimate

## 9. Complete Candidate List (Unsorted)
[Every finding from above, one line each, no duplicates]
```

**Proceed directly to Phase 2 and Phase 3 to deliver prioritized recommendations.**

---

## Phase 2: Impact Categorization

For each candidate from Phase 1, assign tags:

### Category Tags
- **Security (Critical)** - Auth/authz, injection, data leaks, CSRF/XSS
- **Performance** - Speed, bundle size, queries, caching
- **Reliability** - Error handling, retries, monitoring
- **UX** - User flows, feedback, loading states, recovery
- **UI** - Visual consistency, responsiveness, theming
- **Testing** - Coverage gaps, contract tests, failure modes
- **Code Quality** - Duplication, patterns, complexity
- **Architecture** - Boundaries, contracts, layering
- **Data** - Schema, indexes, migrations, queries
- **DevOps** - Deployment, monitoring, disaster recovery
- **Missing Features** - Bounded, UX-critical additions

### Scoring Each Item

**Impact (H/M/L)**
- High: Affects critical user path OR security risk OR >10% users daily
- Medium: Improves common flow OR affects some users weekly
- Low: Edge case OR rare scenario OR nice-to-have

**Likelihood (Daily/Weekly/Rare)**
- Daily: Every user hits this multiple times per session
- Weekly: Most users encounter occasionally
- Rare: <5% users OR special circumstances

**Effort (S/M/L)**
- Small: <4 hours (1 file, small diff, existing patterns)
- Medium: 4-16 hours (multiple files, new patterns, moderate testing)
- Large: >16 hours (cross-cutting, migration, extensive testing)

**Risk (Breaking Change Potential)**
- Low: Isolated, backward compatible, easy rollback
- Medium: Touches shared code, requires coordination
- High: Schema change, auth change, API contract change

---

## Phase 3: Prioritized Recommendations (APPROVAL GATE)

### Top 3 High-Impact Improvements (Overall System)

For each:
```markdown
### [#1: Title - Impact Category Tags]

**Issue:** [What's wrong, why it matters, user/business impact]

**Current State:** [Code location, current behavior, metrics]

**Proposed Solution:** [Specific change, implementation approach]

**Impact:** High/Medium/Low - [Quantify: X% users, Y ms improvement, Z security risk]

**Likelihood:** Daily/Weekly/Rare - [How often this matters]

**Effort:** Small/Medium/Large - [Estimated hours]

**Risk:** Low/Medium/High - [Breaking change potential + mitigation]

**Success Criteria:**
- [Metric 1: e.g., "Bundle size < 200KB"]
- [Metric 2: e.g., "Auth flow test coverage 100%"]
- [Metric 3: e.g., "Zero XSS vulnerabilities"]

**Verification Plan:**
- [ ] Unit tests: [Specific test cases]
- [ ] Integration tests: [API contract tests]
- [ ] Manual QA: [Checklist]
- [ ] Metrics: [Before/after comparison]

**File Targets:**
- `path/to/file1.ts` - [What changes]
- `path/to/file2.ts` - [What changes]
- `tests/path/to/test.spec.ts` - [New/updated tests]

**Implementation Steps:**
1. [Step 1 with validation]
2. [Step 2 with validation]
3. [Run tests + verify metrics]
```

### 3 Quick Wins (<4 hours each)

Same format as above, but must be:
- Low risk
- Immediately valuable
- Uses existing patterns
- Small, surgical change

---

## APPROVAL GATE

**You have now completed the analysis. Present the above recommendations to the user.**

Before proceeding to implementation, confirm with the user:
- [ ] Top 3 priorities are correct
- [ ] Quick wins are approved
- [ ] Risk tolerance is acceptable
- [ ] Ready to proceed with implementation

**Do NOT stop before reaching this point.** The user needs to see the prioritized recommendations to make informed decisions.

---

## Phase 4: Implementation Protocol

### Pre-Implementation Checklist
- [ ] Read all target files before changing (verify assumptions)
- [ ] Create feature branch from main
- [ ] Ensure tests pass on baseline
- [ ] Have rollback plan ready

### Implementation Rules
1. **One improvement at a time** - Complete + verify before next
2. **Read before write** - Never assume, always verify current code
3. **Minimal diffs** - Smallest change for maximum impact
4. **Reuse existing patterns** - Don't introduce new libraries/patterns
5. **Test as you go** - Write tests alongside code, not after
6. **Run full test suite** - After each change, before commit
7. **No scope creep** - If you find other issues, backlog them

### During Implementation
- Run linter after each file change
- Run type checker before moving to next file
- Run relevant tests after each logical chunk
- Verify metrics/behavior manually if applicable
- Document any assumptions or tradeoffs in comments

### Verification Checklist Per Improvement
- [ ] All target files changed as planned
- [ ] New/updated tests pass
- [ ] Full test suite passes
- [ ] Linter passes (zero warnings)
- [ ] Type checker passes (zero errors)
- [ ] Manual QA steps completed
- [ ] Success criteria met (metrics/behavior)
- [ ] No console errors/warnings
- [ ] Accessibility checks (if UI changed)
- [ ] Mobile responsive (if UI changed)

---

## Phase 5: Deliverables (Per Improvement)
```markdown
## Improvement #X: [Title]

### Problem Statement
[What was wrong + why it mattered]

### Solution Implemented
[What changed, at high level]

### Files Changed
- `path/to/file1.ts` - [Summary of changes]
- `path/to/file2.ts` - [Summary of changes]
- `tests/path/test.spec.ts` - [New tests added]

### Verification Results
**Tests:**
- [ ] Unit tests: X new, Y updated, all passing
- [ ] Integration tests: [Status]
- [ ] E2E tests: [Status or N/A]

**Metrics:**
- Before: [Baseline metric]
- After: [New metric]
- Improvement: [% or absolute change]

**Manual QA:**
- [ ] [Test case 1] - Pass
- [ ] [Test case 2] - Pass

### Follow-Up Backlog (Not Implemented)
- [Issue 1] - [Why deferred]
- [Issue 2] - [Why deferred]

### Rollback Plan
[How to undo if needed in production]
```

---

## Quality Standards

### Security
- No secrets in code, ever
- Input validation on all user data
- Authorization checks on all protected routes
- SQL injection impossible (parameterized queries only)
- XSS prevention (sanitize user content)

### Performance
- Bundle size: Frontend <500KB gzipped for main chunk
- API response time: p95 <500ms for critical paths
- Database: No missing indexes on foreign keys or common WHERE clauses
- Caching: Appropriate headers on all static assets

### Testing
- Critical paths: 100% test coverage (auth, payments, data mutations)
- API contracts: Type-safe + integration tested
- Error cases: Network failures, 500s, validation errors all tested
- Regression protection: Tests for all bugs found

### Code Quality
- TypeScript strict mode enabled
- Zero `any` types (use `unknown` if needed)
- Zero `@ts-ignore` (use `@ts-expect-error` with explanation)
- Linter: Zero errors, warnings only for justified exceptions
- Duplication: DRY for business logic (not for tests)

### Accessibility
- WCAG 2.1 AA minimum
- Keyboard navigable
- Screen reader friendly (semantic HTML + ARIA)
- Color contrast passing
- Focus management correct

---

## Example Interaction

**User:** "Optimize my Next.js + Express + PostgreSQL app"

**Assistant:**
1. Reads this skill BEFORE responding
2. Asks for codebase access (@Codebase or file uploads)
3. Runs Phase 1 discovery systematically across all 10 sections
4. Runs Phase 2 scoring on all findings
5. Delivers Phase 3 with Top 3 High-Impact + Quick Wins recommendations
6. **STOPS at APPROVAL GATE and waits for user to approve priorities**
7. User reviews recommendations, asks questions, approves specific improvements
8. Assistant implements one at a time per Phase 4 protocol
9. Delivers Phase 5 results per improvement

---

## Red Flags (Do Not Implement)

- User wants to "modernize" without specific pain points
- Rewriting working code "because it's old"
- Adding frameworks/libraries not already in use
- Big-bang refactors without incremental steps
- Optimizing for theoretical scale (not real bottlenecks)
- Removing tests to "simplify"
- Weakening security "for convenience"

---

## Success Indicators

- User understands tradeoffs before implementation
- Every change has measurable impact
- No regressions introduced
- Team can maintain changes (uses existing patterns)
- Deployment is low-risk
- Improvements compound (each enables next)

---

## Notes on Tools & Integration

**Codebase Access:**
- Prefer @Codebase for live repo analysis
- Accept file uploads if repo unavailable
- Request specific files if access is limited

**Running Checks:**
- `npm run lint` or equivalent
- `npm run type-check` or `tsc --noEmit`
- `npm test` or `pytest` or `go test`
- Check CI config for actual commands

**Metrics Collection:**
- Bundle size: `npm run build` + check output
- API performance: Request logs or APM tools
- Database: `EXPLAIN ANALYZE` for query plans

---

## Skill Metadata

**Version:** 2.0
**Last Updated:** 2025-12-26
**Author:** Day (Full-Stack Developer)
**Applicable Tech:** Next.js, React, TypeScript, Go, Python, PostgreSQL, AWS
**Estimated Phase 1 Time:** 30-60 minutes for medium app
**Estimated Implementation Time:** Varies by improvement, typically 2-16 hours each
