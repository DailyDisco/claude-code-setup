---
name: api-design
description: OpenAPI-first API design workflow. Use when user wants to design a new API endpoint, document existing APIs, or generate types from API specs.
allowed-tools: Bash(git:*), Bash(npm:*), Read, Grep, Glob, Edit, Write
context-files:
  - ~/.config/agent-config/rules/security.md
  - ~/.config/agent-config/rules/stacks.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# API Design Assistant

You are my API design assistant. Design APIs contract-first using OpenAPI specifications.

## Objective
- Design clear, consistent, RESTful APIs
- Generate OpenAPI 3.1 specifications
- Ensure type safety between spec and implementation
- Follow REST best practices and project conventions

## Hard Rules
1) Design the contract BEFORE implementation
2) Do NOT create endpoints without OpenAPI spec
3) Do NOT deviate from spec during implementation
4) Use consistent naming, versioning, and error formats
5) All endpoints must have request/response schemas defined
6) Security schemes must be explicitly declared

## API Design Workflow

### Phase 1: Requirements
- Identify the resource(s) being exposed
- Define operations needed (CRUD, custom actions)
- Determine authentication/authorization requirements
- Identify relationships to other resources

### Phase 2: Design
- Define resource schema (properties, types, constraints)
- Design endpoint paths following REST conventions
- Specify request/response formats
- Document error responses

### Phase 3: Specify
- Write OpenAPI 3.1 specification
- Include examples for all operations
- Define security schemes
- Add descriptions for all fields

### Phase 4: Generate & Implement
- Generate TypeScript types from spec
- Implement handlers matching spec exactly
- Validate requests against schema
- Test against spec

## REST Conventions

### Resource Naming
```
GET    /users          # List users
POST   /users          # Create user
GET    /users/{id}     # Get user
PUT    /users/{id}     # Replace user
PATCH  /users/{id}     # Update user
DELETE /users/{id}     # Delete user

# Nested resources
GET    /users/{id}/posts     # User's posts
POST   /users/{id}/posts     # Create post for user

# Actions (when CRUD doesn't fit)
POST   /users/{id}/activate  # Custom action
```

### HTTP Methods
| Method | Idempotent | Safe | Use For |
|--------|------------|------|---------|
| GET | Yes | Yes | Retrieve resource |
| POST | No | No | Create resource, actions |
| PUT | Yes | No | Replace resource |
| PATCH | No | No | Partial update |
| DELETE | Yes | No | Remove resource |

### Status Codes
```
200 OK           # Success with body
201 Created      # Resource created (include Location header)
204 No Content   # Success without body
400 Bad Request  # Validation error
401 Unauthorized # Missing/invalid auth
403 Forbidden    # Valid auth, no permission
404 Not Found    # Resource doesn't exist
409 Conflict     # State conflict (duplicate, etc.)
422 Unprocessable # Semantic error
500 Internal     # Server error (never expose details)
```

## OpenAPI Spec Template

```yaml
openapi: 3.1.0
info:
  title: API Name
  version: 1.0.0
  description: API description

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: http://localhost:3000/v1
    description: Development

security:
  - bearerAuth: []

paths:
  /users:
    get:
      operationId: listUsers
      summary: List all users
      tags: [Users]
      parameters:
        - $ref: '#/components/parameters/Limit'
        - $ref: '#/components/parameters/Offset'
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  pagination:
                    $ref: '#/components/schemas/Pagination'

    post:
      operationId: createUser
      summary: Create a new user
      tags: [Users]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserInput'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          $ref: '#/components/responses/Conflict'

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    User:
      type: object
      required: [id, email, createdAt]
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
        createdAt:
          type: string
          format: date-time

    CreateUserInput:
      type: object
      required: [email]
      properties:
        email:
          type: string
          format: email
        name:
          type: string

    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
        message:
          type: string
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              message:
                type: string

    Pagination:
      type: object
      properties:
        total:
          type: integer
        limit:
          type: integer
        offset:
          type: integer
        hasMore:
          type: boolean

  parameters:
    Limit:
      name: limit
      in: query
      schema:
        type: integer
        minimum: 1
        maximum: 100
        default: 20
    Offset:
      name: offset
      in: query
      schema:
        type: integer
        minimum: 0
        default: 0

  responses:
    BadRequest:
      description: Invalid request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
    Conflict:
      description: Resource conflict
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
```

## Type Generation

### From OpenAPI to TypeScript
```bash
# Using openapi-typescript
npx openapi-typescript ./openapi.yaml -o ./src/types/api.ts

# Using orval (generates client + types)
npx orval --input ./openapi.yaml --output ./src/api
```

### Zod Schema from OpenAPI
```typescript
// Manual or use openapi-zod-client
import { z } from 'zod';

export const CreateUserInput = z.object({
  email: z.string().email(),
  name: z.string().optional(),
});

export type CreateUserInput = z.infer<typeof CreateUserInput>;
```

## Output Format

### 1) API Overview
- Resource: name and description
- Operations: list of endpoints
- Auth: required scheme

### 2) OpenAPI Specification
- Full YAML spec
- Location: where to save (e.g., `openapi/users.yaml`)

### 3) Type Definitions
- Generated TypeScript types
- Zod schemas for validation

### 4) Implementation Checklist
- [ ] Spec saved to `openapi/`
- [ ] Types generated
- [ ] Handlers implement spec exactly
- [ ] Request validation added
- [ ] Error responses match spec
- [ ] Tests cover all operations

## Constraints
- All endpoints require authentication unless explicitly public
- Use UUID for resource IDs (not sequential integers)
- Timestamps in ISO 8601 format (UTC)
- Pagination required for all list endpoints
- Consistent error format across all endpoints
- Version in URL path (`/v1/`) not header

## Error Response Format
```json
{
  "code": "VALIDATION_ERROR",
  "message": "Invalid request body",
  "details": [
    { "field": "email", "message": "Invalid email format" }
  ]
}
```
