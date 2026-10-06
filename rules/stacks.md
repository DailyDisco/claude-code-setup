# Preferred Tech Stacks & Libraries

When starting new projects or choosing dependencies, prefer these options unless the project already uses alternatives.

---

## Primary Full-Stack: React + Go

### Frontend
- React 19 + TypeScript (strict mode)
- TanStack Router (type-safe, file-based routing)
- TanStack Query (async state management)
- TailwindCSS + ShadCN UI (styling & components)
- Lucide Icons (icon library)
- Zod (validation)
- Vitest (testing)
- Vite (build tooling)

### Backend
- Go 1.25+ with Chi router
- GORM + PostgreSQL
- JWT Authentication
- Role-Based Access Control (RBAC)

### Email
- Nodemailer + React Email (templates)

### DevOps
- Docker (multi-stage builds)
- Caddy (reverse proxy / HTTPS)
- Husky + lint-staged (git hooks)
- GitHub Actions (CI/CD)

---

## Alternative Frontend: Next.js

- Next.js 15 + React 19
- Same styling/state stack as above

---

## Mobile: React Native + Expo

### Framework
- Expo SDK (managed workflow)
- Expo Router (file-based navigation)
- TypeScript (strict mode)
- EAS Build (production builds)

### Libraries
| Category | Preferred |
|----------|-----------|
| Navigation | Expo Router |
| Data Fetching | TanStack Query |
| State | Zustand |
| Forms | react-hook-form + Zod |
| Lists | @shopify/flash-list |
| Images | expo-image |
| Icons | @expo/vector-icons |
| Storage | expo-secure-store (sensitive), AsyncStorage (prefs) |
| Styling | StyleSheet.create, NativeWind |

---

## JavaScript/TypeScript Libraries

| Category | Preferred | Avoid |
|----------|-----------|-------|
| Framework | Next.js or Vite + React | CRA |
| Routing | TanStack Router (Vite) / App Router (Next.js) | React Router (unless existing) |
| Data Fetching | TanStack Query | manual useEffect, SWR |
| State | `zustand` or React Context | Redux (unless complex) |
| Forms | `react-hook-form` + `zod` | `formik` |
| Validation | `zod` | `yup`, `joi` |
| CSS | TailwindCSS | CSS-in-JS (unless existing) |
| Components | ShadCN UI | Material UI (unless existing) |
| Icons | Lucide Icons | Font Awesome, Heroicons |
| Dates | `date-fns` | `moment` (deprecated) |
| HTTP Client | `fetch` (native) or `ky` | `axios` (unless existing) |
| Email | Nodemailer + React Email | SendGrid SDK |
| Testing | `vitest` | `jest` (unless existing) |
| ORM | Prisma or Drizzle | raw SQL (for apps) |
| Git Hooks | Husky + lint-staged | pre-commit scripts |

---

## Go Libraries

| Category | Preferred |
|----------|-----------|
| HTTP Router | Chi |
| ORM | GORM |
| Database | PostgreSQL |
| Logging | `zerolog` |
| Config | `envconfig` or `viper` |
| Testing | stdlib + `testify` |
| Migrations | golang-migrate |
| Background Jobs | River (PostgreSQL-backed) |
| Payments | Stripe |
| Validation | `go-playground/validator` |
| Caching/Sessions | `go-redis` |
| Object Storage | AWS SDK (S3) |
| 2FA/TOTP | `pquerna/otp` |
| Email | `wneessen/go-mail` |
| WebSockets | `nhooyr.io/websocket` |
| Metrics | Prometheus client |
| Error Tracking | Sentry |

---

## Python Libraries

| Category | Preferred |
|----------|-----------|
| Web | `fastapi` |
| HTTP | `httpx` |
| Validation | `pydantic` |
| Testing | `pytest` |
| Linting | `ruff` |

---

## Starter Kit

For new React + Go projects, use: https://github.com/DailyDisco/react-golang-starter-kit
