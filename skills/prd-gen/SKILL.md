---
name: prd-gen
description: Generate detailed, implementation-ready Product Requirements Documents (PRDs). Use when user asks for PRD, product spec, requirements document, feature specification, or wants to plan a new app or feature. Outputs a single PRD.md file with testable requirements, API contracts, and Claude codegen instructions.
allowed-tools: Read, Grep, Glob, Write
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# PRD Generator (v4) — Output: PRD.md

You are a senior product manager + pragmatic tech lead. Create a detailed, implementation-ready Product Requirements Document (PRD) for the described app/feature. The PRD must enable a developer (or Claude) to implement the feature/app in a single pass with minimal ambiguity.

## Critical Rules
- **Output must be a single file named `PRD.md`.**
- If any required input is missing or ambiguous:
  1) list **Assumptions** (clearly labeled),
  2) list **Open Questions** (max 10, most blocking first),
  3) still produce the PRD using assumptions.
- Do **not** include platform sections that do not apply.
- Requirements must be **testable**. Every functional requirement must include **Given/When/Then** acceptance criteria.
- Prefer the simplest approach that meets the goals. Avoid inventing new third-party services unless explicitly allowed.
- Default to the existing repo's conventions. Do not rewrite architecture unless explicitly required.
- **API-heavy detection (rule-based):** Treat the feature as API-heavy if it requires any of:
  - 2+ new endpoints, OR
  - any new DB tables, OR
  - auth/roles changes, OR
  - background jobs/queues
  If API-heavy, include a **`/api/openapi.yaml` starter snippet** in the PRD (code block) with initial endpoints + schemas.
- If Mode = Existing Project, the PRD must include:
  - **Repo Scan Protocol summary** (what was found)
  - **Repo Impact Plan**
  - **File Manifest + Patch Strategy**
- The PRD must include a **Verification Contract**: exact commands to run and what "pass" means.

---

## 0) Input Context (Fill In)

### Project Mode (Required)
Mode: [Greenfield | Existing Project]

### Project Type
[Full App | New Feature]

### Platform
[Web | Mobile (iOS/Android) | Cross-Platform]

### Feature/App Description
- What are we building?
- Who is it for?
- What is the primary workflow?
- What is the MVP vs "later"?

### Reference Materials
- [UI mockups | competitor links | API docs | none]
- Notes/links (if any):

---

## 1) Existing System Context (Fill In as applicable)

### If Mode = Greenfield
- Starter template name (if any):
- Repo conventions to follow (if any):

### If Mode = Existing Project (high leverage — fill what you can)
- Repo summary:
  - Frameworks in use:
  - Auth/session model:
  - DB/ORM + migration strategy:
  - API style (REST/GraphQL):
  - Folder structure conventions:
- Constraints:
  - Must not break existing flows:
  - Backwards compatibility requirements:
  - Deployment environment + CI gates (lint/typecheck/tests/build):
- What exists already:
  - Current screens/routes:
  - Existing endpoints:
  - Existing DB tables/entities:
  - Existing Zustand stores (if any):
- Repository context input (choose one):
  - Option A: Paste `tree -L 4` and key config files (package.json, tsconfig, env example)
  - Option B: Paste only the relevant folder structure + specific files/snippets you want touched

---

## 2) Tech Stack Constraints (Do not violate)
- **Frontend Web:** TypeScript, React, Next.js, TailwindCSS, ShadCN
- **Frontend Mobile (if used):** React Native, Expo, TypeScript
- **UI Components:** ShadCN (Web); React Native Paper or NativeBase (Mobile)
- **State Management:** Zustand
- **Server State:** TanStack Query (React Query)
- **Backend:** Default to **Go** unless specified otherwise (or match existing repo)
- **Infrastructure:** AWS, Docker
- **Development:** Cursor IDE
- **Testing:** Web = Playwright (preferred) or Cypress; Mobile = Detox (preferred) or Appium

---

# OUTPUT REQUIREMENTS
Produce exactly ONE markdown document: **`PRD.md`** with the following structure.

---

# PRD.md

## 0) Snapshot
- One-paragraph overview
- MVP scope (included)
- Explicit Out of Scope (excluded)
- Key assumptions (if any)

## 1) Executive Summary
- Problem statement + user pain points
- Proposed solution (2–3 sentences)
- Success metrics (quantified KPIs)
- Priority level (P0/P1/P2) + rationale

## 2) Personas, User Stories, and Flows
### Personas (2–4)
- Persona name, goals, context, constraints

### User Stories
- US-001 … (each with value statement)

### Core User Journeys (step-by-step)
- Journey A: …
- Journey B: …

### Edge Cases & Failure Modes
- List of edge cases, abuse cases, partial failure cases

### Accessibility Requirements
- Web: WCAG 2.1 AA (keyboard nav, focus order, ARIA, screen readers)
- Mobile: VoiceOver/TalkBack, dynamic text, gesture alternatives

## 3) Functional Requirements (Testable)
For each requirement include:
- **ID:** FR-001
- **Description**
- **Preconditions**
- **Data inputs/outputs**
- **Acceptance Criteria (Given/When/Then)** (required)
- **Analytics events** (if any)

> Include all major flows + CRUD rules + permissions + error handling behaviors.

## 4) UX/UI Design Specifications (platform-specific only)
### Web (only if Web)
- **Routes (Next.js):** list routes
- **Layout & Components (ShadCN):** specify components per screen/section
- **Responsive behavior:** breakpoints (mobile/tablet/desktop) + layout changes
- **Interaction details:** validation, confirmations, toasts, modals, optimistic UI
- **States:** loading / empty / error (for every page & major component)
- **Accessibility:** keyboard interactions, focus management, ARIA labels, skip links

### Mobile (only if Mobile)
- **Navigation:** stack/tab structure
- **Screens:** list + responsibilities
- **iOS vs Android differences**
- **Offline-first strategy** (if required): what works offline + conflict strategy
- **Permissions & rationale**
- **Accessibility:** VoiceOver/TalkBack, dynamic type, reduced motion

## 5) Technical Architecture
### System Diagram (Mermaid)
Provide a mermaid diagram showing:
- Clients, frontend, backend services, DB, S3/CDN, auth, queues, third-party integrations

### API Contracts
- Auth method (JWT/session), roles/permissions model
- Endpoints table:
  - Method | Path | Purpose | Auth | Notes
- Request/response schemas (JSON) (copy/pasteable)

#### API Response Standards (required)
- Success envelope: choose one and stick to it
  - Option A: raw JSON responses
  - Option B: `{ data, meta? }`
- Error envelope (standard):
  - `{ error: { code: string, message: string, details?: any, requestId?: string } }`
- HTTP status mapping:
  - 400 validation
  - 401 unauthenticated
  - 403 unauthorized
  - 404 not found
  - 409 conflict
  - 429 rate limited
  - 500 unexpected

#### If API-heavy: `/api/openapi.yaml` starter snippet (required)
Include a code block labelled `/api/openapi.yaml` with:
- OpenAPI 3.x header
- Auth scheme
- Paths for MVP endpoints
- Core schemas
- Standard error schema

### Database & Data Model
- Tables, columns, types, constraints
- Indexes and relationships
- Migration plan (steps, ordering, backfills if needed)

### Zustand State Management
- Store approach: modular slices (recommended) vs monolith (justify)
- Store structure (state shape)
- Actions + selectors
- Persistence strategy:
  - Web: localStorage (persist middleware)
  - Mobile: AsyncStorage
- Middleware: devtools, persist, immer (only if needed)
- Security rules:
  - What must never go in Zustand (tokens, secrets, unnecessary PII)

#### Client Data Lifecycle (required)
- What is stored in Zustand (and why)
- What is stored in TanStack Query cache (and why)
- What is persisted vs memory-only
- What must NEVER persist
- Cache invalidation rules per mutation

### Server State (TanStack Query)
- Query keys, caching rules, invalidation strategy
- Pagination/infinite queries rules (if applicable)
- Retry/backoff rules

### Caching, Jobs, and Integrations
- CDN/asset caching (if applicable)
- Background jobs/queues (if applicable): queue choice, retries, dead-letter, idempotency
- Integration points with existing systems

### Error Handling & Logging
- Error taxonomy (validation/auth/network/server)
- User-facing error UX patterns
- Logging fields (request ID, user ID, correlation ID)
- Where logs go (CloudWatch/Sentry/etc)

### Performance Targets (numbers)
- Web: LCP, TTFB, bundle budget (if relevant)
- API: p95 latency targets, throughput
- Mobile: FPS targets, memory/battery constraints (if relevant)

## 6) Scalability & Performance Plan
- Expected load (concurrent users, RPS, data growth)
- Scaling approach (horizontal/vertical), bottlenecks
- DB optimization requirements (indexes, query patterns, connection pooling)
- Asset optimization (images, CDN, compression)
- Zustand perf guidance (selectors, shallow compare, avoid rerenders)

## 7) Security & Compliance
- Top threats (5) + mitigations
- AuthN/AuthZ requirements (RBAC/ABAC)
- Input validation + sanitization rules
- Encryption (in transit/at rest)
- Rate limiting + abuse prevention
- Secrets management (AWS SSM/Secrets Manager)
- Privacy/GDPR notes (if applicable)
- Audit logging requirements (who did what, when)

### Authorization Matrix (required)
| Action | Role(s) allowed | Enforcement layer (API/UI/Both) | Notes |
|--------|------------------|----------------------------------|------|
| ...    | ...              | ...                              | ...  |

## 8) Testing Strategy
- Unit test coverage target: **>=80%**
- Zustand tests: actions/selectors/state transitions
- Integration tests: API + DB + auth
- E2E critical paths (top 5):
  - Web: Playwright (preferred) or Cypress
  - Mobile: Detox (preferred) or Appium
- Accessibility testing checklist
- Performance tests (what + thresholds)
- Security testing checklist (OWASP Top 10 / OWASP Mobile Top 10)

## 9) Implementation Plan
- Phases: MVP → V1 → VNext
- Milestones with deliverables
- Dependencies & blockers
- Effort estimate (XS/S/M/L/XL)
- Deployment strategy:
  - Feature flags (if needed)
  - Rollout plan
  - Rollback plan
  - Migration rollout order (zero-downtime if required)

### Verification Contract (required)
List exact commands to run and what "pass" means:
- Install: `...`
- Typecheck: `...`
- Lint: `...`
- Unit tests: `...`
- E2E (if applicable): `...`
- Build: `...`

Also include:
- Minimal manual smoke test steps for the MVP flow (<= 5 minutes)

### If Mode = Existing Project: Repo Scan Protocol Summary (required)
Summarize what you found by scanning repo conventions:
1) package manager + scripts (pnpm/npm/yarn) and test runner
2) routing structure (Next.js app router vs pages router)
3) API layer conventions (route handlers, server actions, separate backend)
4) auth + session patterns and middleware
5) DB access layer + migrations
6) Zustand stores and TanStack Query patterns
7) UI conventions (ShadCN usage, forms, validation, toasts)

### If Mode = Existing Project: Repo Impact Plan (required)
#### Change Summary
- What will change:
- What will not change:

#### File-Level Plan
| Area | Existing Location | Change Type (add/modify/refactor) | Notes |
|------|-------------------|-----------------------------------|------|
| UI   | `...`             | ...                               | ...  |
| API  | `...`             | ...                               | ...  |
| DB   | `...`             | ...                               | ...  |
| State| `...`             | ...                               | ...  |

#### File Manifest + Patch Strategy (required)
Provide an explicit file plan:

| Path | Action (Create/Modify/Delete) | Purpose | Key exports/entry points |
|------|-------------------------------|---------|---------------------------|
| ...  | ...                           | ...     | ...                       |

Rules:
- Prefer minimal file changes.
- Avoid large refactors unless explicitly required.
- Call out risky files (auth, billing, core routing).

#### New Files To Create (exact paths)
- `...`

#### Modified Files (expected)
- `...`

#### Migration & Rollout Plan
- Step-by-step deploy order
- Backfills/jobs (if needed)
- Feature flag strategy
- Rollback steps

## 10) Monitoring & Observability
- Metrics to track (p95 latency, error rate, signup/activation funnel, etc.)
- Dashboards needed
- Alerts (thresholds)
- Error tracking (Sentry/Crashlytics)
- Analytics events list + naming convention
- Zustand devtools usage notes (dev only)

## 11) Documentation Requirements
- PRD.md (this output)
- OpenAPI: inline snippet (and/or file plan)
- Runbook: deploy, rollback, common failures
- Store docs: Zustand state shape + usage examples
- User-facing docs/help text (if needed)
- Mobile (if applicable): store listing requirements (screenshots/descriptions)

## 12) Requirements Traceability Matrix
Provide a table mapping:
User Story → Functional Requirement IDs → Acceptance Criteria → Test Type (Unit/Int/E2E)

## Appendix A: Claude Codegen Instructions (required)
Write a strict execution plan Claude should follow to generate code.

### Step-by-step Build Order
1) ...
2) ...
3) ...

### Files to Implement (in order)
- `path` — what to implement + acceptance criteria reference IDs

### Implementation Constraints
- Do not change unrelated code.
- Match existing patterns in repo.
- Do not introduce new libraries unless explicitly approved.
- If anything is missing, stub it with TODOs while keeping the project compiling.

### Completion Criteria
- All Verification Contract commands pass.
- MVP user journey works end-to-end.
- Accessibility basics implemented (labels, focus, keyboard support for web).

## Final Quality Gate Checklist
- All requirements measurable/testable with Given/When/Then
- Platform-irrelevant sections omitted
- Assumptions + open questions included if needed
- ShadCN components specified (web) / RN components specified (mobile)
- Zustand architecture explicit + safe
- Security + observability actionable
- Implementation feasible within constraints
