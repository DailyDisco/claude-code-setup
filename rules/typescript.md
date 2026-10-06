---
paths: "**/*.{ts,tsx,mts,cts}"
---

# TypeScript Rules

## Configuration

Use strict mode with these compiler options:
- `strict: true`
- `noUncheckedIndexedAccess: true`
- `noImplicitOverride: true`
- `exactOptionalPropertyTypes: true`

---

## Type Safety

- No `any` without explicit justification - use `unknown` instead
- No `@ts-ignore` - use `@ts-expect-error` with explanation
- Validate at system boundaries with Zod

---

## Type vs Interface

Prefer `type` over `interface` unless extending:

```tsx
// Good: Type alias
type User = { id: string; name: string };

// Use interface when extending
interface ExtendedUser extends User {
  email: string;
}
```

---

## Utility Types

```tsx
Pick<User, 'id' | 'name'>       // Select subset
Omit<User, 'id' | 'createdAt'>  // Remove properties
Partial<User>                    // Make optional
Record<string, string[]>         // Type-safe dictionaries
ReturnType<typeof fn>            // Extract return type
Awaited<Promise<T>>              // Unwrap Promise
```

---

## Type Guards

```tsx
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    typeof value.id === 'string'
  );
}
```

---

## Discriminated Unions

```tsx
type State<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

---

## Branded Types

```tsx
type UserId = string & { readonly __brand: 'UserId' };

function createUserId(id: string): UserId {
  return id as UserId;
}
```

---

## Common Pitfalls

- Don't use `Function` - use `(...args: unknown[]) => unknown`
- Don't use `Object` - use `object` or `Record<string, unknown>`
- Don't use `Boolean`/`Number`/`String` - use primitives
- Enable `noUncheckedIndexedAccess` for array safety
