---
name: types-gen
description: Generate TypeScript/Go types from OpenAPI specs, JSON schemas, or database schemas. Use when creating or updating type definitions to ensure frontend/backend contract alignment.
allowed-tools: Bash(npx:*), Bash(go:*), Bash(npm:*), Read, Grep, Glob, Edit, Write
context-files:
  - ~/.config/agent-config/rules/typescript.md
  - ~/.config/agent-config/rules/api.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Type Generation Assistant

Generate strongly-typed interfaces from various schema sources to prevent contract drift between systems.

## Objective
- Generate TypeScript types from OpenAPI/Swagger specs
- Generate Go structs from OpenAPI specs or JSON schemas
- Extract types from database schemas (PostgreSQL, Prisma, Drizzle)
- Ensure type consistency across frontend and backend
- Detect and report type drift between sources

## Hard Rules
1. NEVER generate types without reading the source schema first
2. ALWAYS validate generated types compile successfully
3. ALWAYS preserve existing custom type extensions
4. NEVER overwrite manually-added type annotations without confirmation
5. Generated types MUST include JSDoc/GoDoc comments from schema descriptions

## Type Generation Workflow

### Phase 1: Source Analysis
- Identify schema source type (OpenAPI, JSON Schema, Prisma, database)
- Read and parse the source schema
- Identify existing generated types (look for `// Generated` markers)
- Check for custom extensions that need preservation

### Phase 2: Generation Strategy

#### From OpenAPI Spec
```bash
# TypeScript (using openapi-typescript)
npx openapi-typescript ./openapi.yaml -o ./src/types/api.ts

# Go (using oapi-codegen)
go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@latest
oapi-codegen -package api -generate types openapi.yaml > api/types.go
```

#### From JSON Schema
```bash
# TypeScript (using json-schema-to-typescript)
npx json-schema-to-typescript schema.json > types.ts
```

#### From Prisma Schema
```bash
# Types are auto-generated, but for custom types:
npx prisma generate
# Then import from @prisma/client
```

#### From Database (PostgreSQL)
```bash
# Using kysely-codegen
npx kysely-codegen --out-file src/types/db.ts

# Using pgtyped
npx pgtyped -c pgtyped.config.json
```

### Phase 3: Type Enhancement
After generation, enhance types with:
- Zod schemas for runtime validation
- Utility types (Partial, Required, Pick, Omit variants)
- Form types (for react-hook-form integration)
- API response wrappers

### Phase 4: Validation
- Run TypeScript compiler to verify types
- Check for any `any` types that need refinement
- Verify imports resolve correctly
- Run existing tests to catch regressions

## Output Structure

### TypeScript Types
```typescript
// =============================================================================
// AUTO-GENERATED - DO NOT EDIT DIRECTLY
// Source: openapi.yaml
// Generated: 2025-01-15T10:30:00Z
// =============================================================================

/** User account information */
export interface User {
  /** Unique identifier */
  id: string;
  /** Email address */
  email: string;
  /** Display name */
  name: string;
  /** Account creation timestamp */
  createdAt: string;
}

/** Request body for creating a user */
export interface CreateUserRequest {
  email: string;
  name: string;
  password: string;
}

/** API response wrapper */
export interface ApiResponse<T> {
  data: T;
  meta?: {
    page?: number;
    perPage?: number;
    total?: number;
  };
}

// =============================================================================
// Zod Schemas (for runtime validation)
// =============================================================================

import { z } from 'zod';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1).max(100),
  createdAt: z.string().datetime(),
});

export const CreateUserRequestSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  password: z.string().min(8),
});
```

### Go Types
```go
// Code generated from OpenAPI spec. DO NOT EDIT.
// Source: openapi.yaml
// Generated: 2025-01-15T10:30:00Z

package api

import "time"

// User represents a user account
type User struct {
    // Unique identifier
    ID string `json:"id"`
    // Email address
    Email string `json:"email"`
    // Display name
    Name string `json:"name"`
    // Account creation timestamp
    CreatedAt time.Time `json:"createdAt"`
}

// CreateUserRequest is the request body for creating a user
type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Name     string `json:"name" validate:"required,min=1,max=100"`
    Password string `json:"password" validate:"required,min=8"`
}
```

## Drift Detection

When updating types, check for drift:

```bash
# Compare OpenAPI spec types vs current TypeScript types
# Report any mismatches in:
# - Field names
# - Field types
# - Required/optional status
# - Enum values
```

### Drift Report Format
```
Type Drift Report
═════════════════════════════════════════════════════════════════

Source: openapi.yaml (modified: 2025-01-15)
Target: src/types/api.ts (modified: 2025-01-10)

⚠️  DRIFT DETECTED

User type:
  + role: string (new in spec, missing in types)
  ~ createdAt: Date → string (type changed)

CreateUserRequest type:
  - confirmPassword: string (in types, not in spec)

Recommendation: Regenerate types and update consuming code
```

## Integration Patterns

### With TanStack Query
```typescript
// types/api.ts
export interface GetUsersResponse {
  users: User[];
  meta: PaginationMeta;
}

// hooks/useUsers.ts
import { useQuery } from '@tanstack/react-query';
import type { GetUsersResponse } from '@/types/api';

export function useUsers() {
  return useQuery<GetUsersResponse>({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  });
}
```

### With react-hook-form
```typescript
// types/forms.ts
import type { CreateUserRequest } from './api';

export type CreateUserForm = CreateUserRequest & {
  confirmPassword: string;
};
```

## Required Inputs
- Schema source (OpenAPI spec path, database connection, Prisma schema)
- Output directory for generated types
- Target language (TypeScript, Go)

## Constraints
- Generated files must have clear "DO NOT EDIT" markers
- Preserve any `// @custom` annotated sections
- Maximum file size: 5000 lines (split if larger)
- Include generation timestamp and source reference
