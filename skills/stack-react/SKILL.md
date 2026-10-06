---
name: stack-react
description: Set up React project with Vite, TanStack, and modern tooling. Use when bootstrapping React SPAs.
allowed-tools: Read, Write, Edit, Bash(npm:*), Bash(pnpm:*), Bash(npx:*), Glob
context-files:
  - ~/.config/agent-config/rules/react.md
  - ~/.config/agent-config/rules/typescript.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# React Stack Setup (Vite)

Configure React projects with Vite, TypeScript, and modern patterns.

## When to Use

- New React SPA setup
- Adding TanStack Router/Query
- Setting up ShadCN UI
- Configuring Tailwind CSS
- Adding state management

## Hard Rules

1. ALWAYS use TypeScript with strict mode
2. ALWAYS co-locate related files (component + test + styles)
3. NEVER use `any` — prefer `unknown` with type guards
4. ALWAYS use TanStack Query for server state
5. PREFER Server Components when using Next.js
6. AVOID prop drilling — use composition or context

## Process

### Phase 1: Quick Start

```bash
pnpm create vite@latest my-app --template react-ts
cd my-app
pnpm install
```

### Phase 2: Install Dependencies

```bash
# Routing & State
pnpm add @tanstack/react-router @tanstack/react-query

# Forms & Validation
pnpm add react-hook-form @hookform/resolvers zod

# Styling
pnpm add -D tailwindcss postcss autoprefixer
pnpm add class-variance-authority clsx tailwind-merge lucide-react

# UI Components
pnpm dlx shadcn@latest init

# Dev tools
pnpm add -D @tanstack/react-query-devtools
```

### Phase 3: Project Structure

```
src/
├── components/
│   ├── ui/                  # ShadCN base components
│   │   ├── button.tsx
│   │   └── input.tsx
│   ├── forms/               # Form components
│   │   └── login-form.tsx
│   └── layout/              # Layout components
│       ├── header.tsx
│       └── sidebar.tsx
├── hooks/
│   ├── use-auth.ts
│   └── use-users.ts         # TanStack Query hooks
├── lib/
│   ├── api.ts               # API client
│   ├── utils.ts             # cn() and utilities
│   └── validations.ts       # Zod schemas
├── routes/
│   ├── __root.tsx           # Root layout
│   ├── index.tsx            # Home page
│   └── users/
│       ├── index.tsx        # /users
│       └── $userId.tsx      # /users/:userId
├── stores/                   # Zustand stores (if needed)
│   └── ui-store.ts
├── types/
│   └── api.ts               # API types
├── main.tsx
└── routeTree.gen.ts
```

### Phase 4: Core Patterns

#### TanStack Router Setup

```tsx
// routes/__root.tsx
import { createRootRoute, Outlet } from '@tanstack/react-router'
import { TanStackRouterDevtools } from '@tanstack/router-devtools'

export const Route = createRootRoute({
  component: () => (
    <>
      <Header />
      <main className="container py-6">
        <Outlet />
      </main>
      <TanStackRouterDevtools />
    </>
  ),
})

// routes/index.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: HomePage,
})

function HomePage() {
  return <h1>Welcome</h1>
}

// routes/users/$userId.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/users/$userId')({
  component: UserPage,
  loader: ({ params }) => fetchUser(params.userId),
})

function UserPage() {
  const { userId } = Route.useParams()
  const user = Route.useLoaderData()
  return <UserProfile user={user} />
}
```

#### TanStack Query Setup

```tsx
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
})

createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <RouterProvider router={router} />
    <ReactQueryDevtools />
  </QueryClientProvider>
)

// hooks/use-users.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '@/lib/api'
import type { User, CreateUserInput } from '@/types/api'

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.get<User[]>('/users'),
  })
}

export function useUser(id: string) {
  return useQuery({
    queryKey: ['users', id],
    queryFn: () => api.get<User>(`/users/${id}`),
    enabled: !!id,
  })
}

export function useCreateUser() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (data: CreateUserInput) => api.post<User>('/users', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })
}
```

#### API Client (lib/api.ts)

```typescript
const BASE_URL = import.meta.env.VITE_API_URL || '/api'

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`${BASE_URL}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
    ...options,
  })

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`)
  }

  return response.json()
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, data: unknown) =>
    request<T>(path, { method: 'POST', body: JSON.stringify(data) }),
  put: <T>(path: string, data: unknown) =>
    request<T>(path, { method: 'PUT', body: JSON.stringify(data) }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' }),
}
```

#### Form with React Hook Form + Zod

```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

type FormData = z.infer<typeof schema>

export function LoginForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  })

  const onSubmit = async (data: FormData) => {
    await login(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <Input {...register('email')} placeholder="Email" />
        {errors.email && <p className="text-red-500 text-sm">{errors.email.message}</p>}
      </div>
      <div>
        <Input {...register('password')} type="password" placeholder="Password" />
        {errors.password && <p className="text-red-500 text-sm">{errors.password.message}</p>}
      </div>
      <Button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Loading...' : 'Login'}
      </Button>
    </form>
  )
}
```

#### Utility Functions (lib/utils.ts)

```typescript
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

#### Component Pattern with CVA

```tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        outline: 'border border-input bg-background hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        default: 'h-10 px-4 py-2',
        sm: 'h-9 px-3',
        lg: 'h-11 px-8',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
)

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

export function Button({ className, variant, size, ...props }: ButtonProps) {
  return <button className={cn(buttonVariants({ variant, size }), className)} {...props} />
}
```

### Phase 5: Testing

```typescript
// components/button.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from './button'

describe('Button', () => {
  it('renders with text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument()
  })

  it('calls onClick when clicked', async () => {
    const onClick = vi.fn()
    render(<Button onClick={onClick}>Click</Button>)
    await userEvent.click(screen.getByRole('button'))
    expect(onClick).toHaveBeenCalledOnce()
  })
})
```

## Output Format

```markdown
## React Project Setup: [name]

### Created Structure
- src/components/ - UI and feature components
- src/hooks/ - TanStack Query hooks
- src/routes/ - TanStack Router pages
- src/lib/ - API client and utilities

### Dependencies Installed
- Vite + React 19 + TypeScript
- TanStack Router + Query
- React Hook Form + Zod
- Tailwind + ShadCN UI

### Available Commands

| Command | Description |
|---------|-------------|
| pnpm dev | Start dev server |
| pnpm build | Build for production |
| pnpm test | Run Vitest |
| pnpm lint | Run ESLint |

### Next Steps
1. Run `pnpm dev`
2. Add routes in `src/routes/`
3. Add ShadCN components: `pnpm dlx shadcn@latest add button`
```
