# Claude Code Hooks

Sharp, minimal hooks that enforce invariants without slowing you down.

## Philosophy

Hooks should:
- **Enforce invariants** (things you never want broken)
- **Prevent silent failure** (tests, types, builds)
- **Standardize output** (PRDs, commits, APIs)

Hooks should NOT:
- Make architectural decisions
- Rewrite large files automatically
- Push code or modify history without consent

---

## Tier 1 — Non-Negotiable

### repo-scan.sh
**Event:** `SessionStart`
**Purpose:** Context priming to prevent hallucinations

Scans on session start:
- README.md
- package.json / go.mod / Cargo.toml / pyproject.toml
- docker-compose.yml
- .env.example
- Infrastructure directories

### build-test-gate.sh
**Event:** `PreToolUse` (Bash git commit)
**Purpose:** Ensures build and tests pass before commits

Runs automatically:
- `npm run build` / `go build` / `cargo build`
- `npm test` / `go test` / `cargo test` / `pytest`
- `npm run lint` / `npm run typecheck`

Blocks commit if any fail.

### commit-guard.sh
**Event:** `PreToolUse` (Bash)
**Purpose:** Commit message quality and safety

Enforces:
- Conventional Commits format
- No AI references in subject line
- Max 72 char subject
- Blocks `git push` (push manually)
- Blocks destructive commands (`--force`, `reset --hard`)

### type-check.sh

**Event:** `PreToolUse` (Bash git commit)
**Purpose:** Fast type checking before commits

Runs type checking for:

- TypeScript: `tsc --noEmit` on staged files
- Python: `pyright` or `mypy` on staged files

Blocks commit if type errors exist. Faster than full build-test-gate.

---

## Tier 2 — High-Leverage Workflow

### prd-enforcement.sh
**Event:** `UserPromptSubmit`
**Purpose:** PRD-first workflow for features

Detects feature requests and suggests PRD.md first:
- Scope / Non-Goals
- Data models
- API contracts
- State management
- Edge cases
- Test strategy
- Rollback plan

Skip with "just code" in your request.

### openapi-sync.sh
**Event:** `PostToolUse` (Edit|Write)
**Purpose:** Keep OpenAPI spec in sync

Reminds to update openapi.yaml when API files change:
- New endpoints documented
- Request/response schemas
- Auth requirements
- Error responses

### test-coverage.sh
**Event:** `PostToolUse` (Write)
**Purpose:** Test expectations for new code

Detects new source files and reminds about tests:
- Unit tests for core logic
- Edge case coverage
- Integration tests if needed

---

## Tier 3 — Safety & Sanity

### security-check.sh
**Event:** `PostToolUse` (Edit|Write)
**Purpose:** Security surface awareness

Flags security-sensitive files (auth, payments, uploads, webhooks):
- [ ] Server-side auth
- [ ] Input validation
- [ ] XSS prevention
- [ ] SQL injection prevention
- [ ] No hardcoded secrets
- [ ] Rate limiting
- [ ] Webhook verification

### infra-drift.sh
**Event:** `PostToolUse` (Edit|Write)
**Purpose:** Infrastructure change awareness

Flags infra file changes:
- [ ] Dev/prod parity
- [ ] Env vars documented
- [ ] Proper secret management
- [ ] Resource limits
- [ ] Health checks
- [ ] Rollback plan

### breaking-change.sh

**Event:** `PostToolUse` (Edit|Write)
**Purpose:** Breaking change detection

Warns when modifying:

- API routes and endpoints
- OpenAPI/Swagger specs
- GraphQL schemas
- TypeScript type definitions
- Database migrations
- Protobuf definitions
- Package exports

Advisory only (does not block). Reminds to verify backward compatibility.

---

## Installation

### Option 1: User-level (all projects)

Copy hooks to `~/.claude/hooks/` and merge `settings.json` into `~/.claude/settings.json`:

```bash
# Already installed at ~/.claude/hooks/
# Add hooks config to your settings.json
```

### Option 2: Project-level

Copy hooks to `.claude/hooks/` in your project and add to `.claude/settings.json`.

### Minimal Setup

If you want the cleanest config, use only these:

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/repo-scan.sh" }] }],
    "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "~/.claude/hooks/commit-guard.sh" }] }]
  }
}
```

---

## Customization

### Disable a hook temporarily

Comment it out in settings.json or remove from the hooks array.

### Add project-specific hooks

Create `.claude/hooks/` in your project with custom scripts.

### Adjust timeouts

Default is 60s. Build/test gate uses 300s. Adjust per hook:

```json
{ "type": "command", "command": "...", "timeout": 120 }
```

---

## Hooks You Should NOT Add

- Auto-refactor entire files
- Auto-push to branches
- "Fix everything" hooks
- Opinionated architecture rewrites
- Silent formatting changes

These kill trust and slow iteration.
