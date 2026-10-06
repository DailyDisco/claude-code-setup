---
name: stack-typescript
description: Set up TypeScript configuration and patterns for a project. Use when bootstrapping TypeScript or reviewing TS configuration.
allowed-tools: Read, Write, Edit, Bash(npm:*), Bash(pnpm:*), Bash(yarn:*), Glob
context-files:
  - ~/.config/agent-config/rules/typescript.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# TypeScript Stack Setup

Configure TypeScript with strict, production-ready settings.

## When to Use

- New TypeScript project setup
- Reviewing/upgrading tsconfig.json
- Adding TypeScript to existing JS project
- Fixing type-safety issues
- Migrating from loose to strict mode

## Hard Rules

1. ALWAYS enable strict mode — loose configs hide bugs
2. NEVER use `any` without documented justification
3. ALWAYS prefer `unknown` over `any` for external data
4. NEVER disable type checking with @ts-ignore (use @ts-expect-error)
5. ALWAYS validate external data at runtime boundaries

## Process

### Phase 1: Analyze Current State

```bash
# Check existing configuration
cat tsconfig.json 2>/dev/null

# Check TypeScript version
npx tsc --version

# Count current type errors
npx tsc --noEmit 2>&1 | grep -c "error TS"

# Find any/unknown usage
grep -r "any\|unknown" --include="*.ts" --include="*.tsx" src/
```

### Phase 2: Apply Configuration

#### Base Configuration (All Projects)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,

    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,

    "isolatedModules": true,
    "esModuleInterop": true,
    "skipLibCheck": true,

    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

#### Framework-Specific Extensions

**React/Vite:**
```json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "noEmit": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

**Next.js:**
```json
{
  "compilerOptions": {
    "jsx": "preserve",
    "noEmit": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"]
}
```

**Node.js/Backend:**
```json
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### Phase 3: Type Patterns

#### Discriminated Unions (State Management)

```typescript
// Instead of optional properties
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error }

function handleState<T>(state: RequestState<T>) {
  switch (state.status) {
    case 'success':
      return state.data // TypeScript knows data exists
    case 'error':
      return state.error.message
  }
}
```

#### Type Guards

```typescript
// Runtime type checking
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  )
}

// Usage with unknown
const data: unknown = await response.json()
if (isUser(data)) {
  console.log(data.email) // Safe access
}
```

#### Branded Types

```typescript
// Prevent mixing similar types
type UserId = string & { readonly brand: unique symbol }
type OrderId = string & { readonly brand: unique symbol }

function createUserId(id: string): UserId {
  return id as UserId
}

function getUser(id: UserId) { /* ... */ }

const userId = createUserId('123')
const orderId = '456' as OrderId

getUser(userId)  // OK
getUser(orderId) // Error: Argument of type 'OrderId' not assignable to 'UserId'
```

#### Utility Types Reference

| Type | Use Case |
|------|----------|
| `Partial<T>` | All properties optional |
| `Required<T>` | All properties required |
| `Pick<T, K>` | Select specific properties |
| `Omit<T, K>` | Remove specific properties |
| `Record<K, V>` | Object with key-value types |
| `NonNullable<T>` | Remove null/undefined |
| `ReturnType<F>` | Get function return type |
| `Parameters<F>` | Get function parameters |
| `Awaited<T>` | Unwrap Promise type |

#### Zod Integration (Runtime Validation)

```typescript
import { z } from 'zod'

// Define schema
const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(['admin', 'user']),
  createdAt: z.coerce.date(),
})

// Infer TypeScript type from schema
type User = z.infer<typeof UserSchema>

// Validate at runtime
function parseUser(data: unknown): User {
  return UserSchema.parse(data) // Throws if invalid
}

// Safe parse (returns result object)
const result = UserSchema.safeParse(data)
if (result.success) {
  console.log(result.data.email)
} else {
  console.error(result.error.issues)
}
```

### Phase 4: Migration Strategy

#### Incremental Strictness (Large Codebases)

```json
{
  "compilerOptions": {
    "strict": false,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitAny": false
  }
}
```

Enable flags one at a time:
1. `strictNullChecks` — Most impactful, fix null errors
2. `strictFunctionTypes` — Function parameter safety
3. `noImplicitAny` — Require explicit types
4. `strict` — Enable all remaining flags

#### Finding Type Holes

```bash
# Find @ts-ignore comments
grep -r "@ts-ignore\|@ts-expect-error" --include="*.ts" --include="*.tsx" src/

# Find explicit any usage
grep -r ": any\|as any\|<any>" --include="*.ts" --include="*.tsx" src/

# Find type assertions
grep -r "as [A-Z]" --include="*.ts" --include="*.tsx" src/
```

## Output Format

### Configuration Review

```markdown
## TypeScript Configuration Review

### Current State
- Version: X.X.X
- Strict mode: [enabled/disabled]
- Type errors: [count]

### Recommendations

| Setting | Current | Recommended | Impact |
|---------|---------|-------------|--------|
| strict | false | true | High - catches nullability issues |
| noUncheckedIndexedAccess | false | true | Medium - safer array access |

### Type Holes Found
| File | Line | Issue |
|------|------|-------|
| src/api.ts | 42 | Uses `any` for API response |

### Migration Plan
1. Enable `strictNullChecks`
2. Fix null-related errors (~X files)
3. Enable remaining strict flags
```

## Common Issues & Fixes

| Error | Fix |
|-------|-----|
| "Type 'X' is not assignable to 'Y'" | Check for null/undefined, use type guard |
| "Object is possibly 'undefined'" | Add null check or use optional chaining |
| "Element implicitly has 'any' type" | Add index signature or use noUncheckedIndexedAccess |
| "Cannot find module" | Check moduleResolution, add declaration file |
