---
paths: "**/*.{jsx,tsx}"
---

# React Rules

## Component Structure

- Functional components only (no class components)
- One component per file (co-located with tests)
- Props interface defined above component

```tsx
interface UserCardProps {
  user: User;
  onSelect?: (user: User) => void;
}

export function UserCard({ user, onSelect }: UserCardProps) {
  return (
    <div onClick={() => onSelect?.(user)}>
      {user.name}
    </div>
  );
}
```

---

## Hooks

- Custom hooks for reusable logic (prefix with `use`)
- Keep hooks at top level, never conditional
- Use TanStack Query for server state
- Use Zustand or Context for client state

```tsx
function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });
}
```

---

## State Management

| Type | Solution |
|------|----------|
| Server state | TanStack Query |
| Form state | react-hook-form |
| URL state | TanStack Router |
| Global UI state | Zustand or Context |
| Local UI state | useState |

---

## Performance

- Memoize expensive computations with `useMemo`
- Memoize callbacks passed to children with `useCallback`
- Use `React.memo` for pure components that re-render often
- Lazy load routes and heavy components

---

## Forms with react-hook-form + Zod

```tsx
const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

type FormData = z.infer<typeof schema>;

function LoginForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <input {...form.register('email')} />
      {form.formState.errors.email && (
        <span>{form.formState.errors.email.message}</span>
      )}
    </form>
  );
}
```

---

## Next.js Specifics

- Server Components by default
- Use `"use client"` only when needed (interactivity, hooks)
- Server Actions for mutations
- Parallel data fetching with `Promise.all`

---

## Styling

- TailwindCSS for utility classes
- ShadCN UI for components
- Consistent spacing scale
- Mobile-first responsive design
