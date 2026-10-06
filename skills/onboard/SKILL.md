---
name: onboard
description: Generate an onboarding guide for new developers joining this project
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git branch:*), Bash(npm run:*), Bash(cat:*), Bash(ls:*), Write
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Developer Onboarding Guide Generator

Create a comprehensive onboarding guide for new developers joining the project.

## Hard Rules

1. ALWAYS analyze the actual codebase — never assume stack or structure
2. ALWAYS verify commands work before documenting them
3. NEVER include secrets or sensitive values in the guide
4. ALWAYS include troubleshooting for common setup issues
5. PREFER practical examples over abstract explanations

## Process

### Phase 1: Discovery

Analyze the codebase to understand:

```bash
# Detect package managers and dependencies
ls -la package.json go.mod requirements.txt pyproject.toml Cargo.toml 2>/dev/null

# Check for environment templates
ls -la .env.example .env.template .env.sample 2>/dev/null

# Find available scripts
cat package.json | jq '.scripts' 2>/dev/null
cat Makefile 2>/dev/null | grep -E "^[a-zA-Z_-]+:"

# Check for Docker setup
ls -la Dockerfile docker-compose*.yml 2>/dev/null

# Review project structure
find . -type d -maxdepth 2 | grep -v node_modules | grep -v .git | head -30

# Recent git activity (understand active areas)
git log --oneline -20
git shortlog -sn --since="3 months ago" | head -10
```

### Phase 2: Stack Detection

Identify the tech stack and patterns:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js/JavaScript/TypeScript |
| `go.mod` | Go |
| `requirements.txt` / `pyproject.toml` | Python |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle` | Java |
| `next.config.js` | Next.js |
| `vite.config.ts` | Vite |
| `tsconfig.json` | TypeScript |
| `tailwind.config.js` | TailwindCSS |
| `prisma/schema.prisma` | Prisma ORM |
| `drizzle.config.ts` | Drizzle ORM |

### Phase 3: Generate Guide

Create `ONBOARDING.md` with all sections below.

## Output Format

```markdown
# Onboarding Guide: [Project Name]

> Last updated: [Date]
> Estimated setup time: [X minutes]

## Quick Start (5-minute setup)

```bash
# 1. Clone
git clone [repo-url]
cd [project-name]

# 2. Install dependencies
[package-manager] install

# 3. Set up environment
cp .env.example .env
# Edit .env with your values (see Environment Variables below)

# 4. Start development
[start-command]
```

Visit http://localhost:[port] to verify it's working.

---

## Prerequisites

### Required Software

| Tool | Version | Installation |
|------|---------|-------------|
| Node.js | 20+ | `nvm install 20` |
| [Database] | X.X | `brew install [db]` |
| Docker | Latest | [docker.com](https://docker.com) |

### Required Accounts/Access

- [ ] GitHub access to this repo
- [ ] [Cloud provider] account (for deployment)
- [ ] [Service] API key (for [feature])

---

## Environment Variables

| Variable | Description | Where to Get |
|----------|-------------|--------------|
| `DATABASE_URL` | PostgreSQL connection string | Local: see below |
| `API_KEY` | External service key | Request from team lead |
| `JWT_SECRET` | Auth token signing | Generate: `openssl rand -hex 32` |

### Local Development Values

```bash
# .env.local
DATABASE_URL="postgresql://user:pass@localhost:5432/dbname"
API_KEY="dev_key_for_local_testing"
```

---

## Project Structure

```
[project]/
├── src/
│   ├── app/           # [Framework] app router / pages
│   ├── components/    # React components
│   │   ├── ui/        # Base UI components (buttons, inputs)
│   │   └── features/  # Feature-specific components
│   ├── lib/           # Utilities and helpers
│   ├── hooks/         # Custom React hooks
│   └── types/         # TypeScript type definitions
├── api/               # Backend API (if separate)
├── prisma/            # Database schema and migrations
├── tests/             # Test files
└── scripts/           # Build and utility scripts
```

### Key Files

| File | Purpose |
|------|---------|
| `src/app/layout.tsx` | Root layout, providers, global styles |
| `src/lib/db.ts` | Database client singleton |
| `src/lib/auth.ts` | Authentication utilities |
| `.env.example` | Environment variable template |

---

## Development Workflow

### Daily Development

```bash
# Start all services
[start-command]

# Run in watch mode (tests)
[test-watch-command]

# Check types
[typecheck-command]
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/[ticket-id]-brief-description

# Make changes, then commit
git add .
git commit -m "feat: add user profile page"

# Push and create PR
git push -u origin HEAD
gh pr create --fill
```

### Commit Message Convention

```
type(scope): description

Types: feat, fix, docs, refactor, test, chore
Examples:
- feat(auth): add OAuth login
- fix(api): handle null user response
- docs(readme): update setup instructions
```

---

## Common Tasks

### Adding a New API Endpoint

1. Create route file: `src/app/api/[resource]/route.ts`
2. Define handler:
```typescript
export async function GET(request: Request) {
  // Implementation
}
```
3. Add validation with Zod
4. Write tests in `tests/api/[resource].test.ts`

### Creating a New Component

1. Create file: `src/components/[category]/[ComponentName].tsx`
2. Follow naming pattern: PascalCase for components
3. Co-locate styles if using CSS modules
4. Export from `src/components/index.ts`

### Running Database Migrations

```bash
# Create migration
[migration-create-command]

# Apply migrations
[migration-run-command]

# Reset database (caution!)
[migration-reset-command]
```

---

## Testing

```bash
# Run all tests
[test-command]

# Run specific test file
[test-command] [path]

# Run with coverage
[test-coverage-command]
```

### Writing Tests

```typescript
describe('UserService', () => {
  it('should create a new user', async () => {
    // Arrange
    const userData = { email: 'test@example.com' };

    // Act
    const user = await UserService.create(userData);

    // Assert
    expect(user.email).toBe(userData.email);
  });
});
```

---

## Troubleshooting

### "Module not found" errors

```bash
# Clear node_modules and reinstall
rm -rf node_modules
[package-manager] install
```

### Database connection refused

```bash
# Check if database is running
docker ps | grep postgres

# Start database
docker compose up -d db
```

### Port already in use

```bash
# Find process using port
lsof -i :[port]

# Kill it
kill -9 [PID]
```

### Environment variables not loading

- Ensure `.env.local` exists (not just `.env.example`)
- Restart dev server after changing env vars
- Check for typos in variable names

---

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| [State management choice] | [Why this over alternatives] |
| [Database choice] | [Why this fits our needs] |
| [Auth approach] | [Security/UX considerations] |

See `docs/adr/` for detailed Architecture Decision Records.

---

## Resources

### Documentation

- [Project Wiki](link)
- [API Documentation](link)
- [Design System](link)

### Team

- **Tech Lead:** [Name] - Architecture questions
- **Product:** [Name] - Requirements clarification
- **DevOps:** [Name] - Infrastructure/deployment

### Useful Commands Cheatsheet

```bash
# Development
[dev-command]              # Start dev server
[test-command]             # Run tests
[lint-command]             # Lint code
[format-command]           # Format code

# Database
[db-push-command]          # Push schema changes
[db-studio-command]        # Open database GUI
[db-seed-command]          # Seed with test data

# Deployment
[build-command]            # Build for production
[deploy-command]           # Deploy to staging
```

---

## First Week Checklist

### Day 1
- [ ] Complete environment setup
- [ ] Run the app locally
- [ ] Read this guide fully

### Day 2-3
- [ ] Review key code files (see Key Files above)
- [ ] Complete a small "good first issue"
- [ ] Attend team standup

### Day 4-5
- [ ] Pick up your first real ticket
- [ ] Submit your first PR
- [ ] Schedule 1:1 with tech lead

---

*Questions? Ask in #[team-channel] or reach out to your onboarding buddy.*
```

## Stack-Specific Additions

### React/Next.js Projects

Add sections for:
- Component patterns (client vs server components)
- State management approach
- Styling conventions (Tailwind, CSS Modules)
- Data fetching patterns (Server Actions, TanStack Query)

### Go Projects

Add sections for:
- Project layout (`cmd/`, `internal/`, `pkg/`)
- Error handling conventions
- Testing patterns (`_test.go` files)
- Makefile targets

### Python Projects

Add sections for:
- Virtual environment setup
- Package management (pip, poetry, uv)
- Type hints usage
- Testing with pytest

## Delivery

1. Generate `ONBOARDING.md` in project root
2. Verify all commands work
3. Ask user to review before committing
