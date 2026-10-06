---
name: stack-nextjs
description: Set up Next.js 15 project with App Router and modern patterns. Use when bootstrapping Next.js applications.
allowed-tools: Read, Write, Edit, Bash(npm:*), Bash(pnpm:*), Bash(npx:*), Glob
context-files:
  - ~/.config/agent-config/rules/react.md
  - ~/.config/agent-config/rules/typescript.md
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Next.js Stack Setup

Configure Next.js 15 projects with App Router and modern patterns.

## When to Use

- New Next.js application setup
- Migrating from Pages to App Router
- Adding Server Components/Actions
- Setting up ShadCN UI with Next.js
- Full-stack React application

## Hard Rules

1. ALWAYS use Server Components by default
2. ONLY add 'use client' when needed (state, effects, browser APIs)
3. ALWAYS validate Server Action inputs with Zod
4. NEVER expose sensitive data in Client Components
5. ALWAYS use proper error boundaries
6. PREFER Server Actions over API routes for mutations

## Process

### Phase 1: Quick Start

```bash
pnpm create next-app@latest my-app --typescript --tailwind --eslint --app --src-dir
cd my-app
```

### Phase 2: Install Dependencies

```bash
# Data Fetching & Validation
pnpm add @tanstack/react-query zod

# Forms
pnpm add react-hook-form @hookform/resolvers

# UI Components
pnpm dlx shadcn@latest init

# Utilities
pnpm add clsx tailwind-merge date-fns lucide-react

# Database (optional)
pnpm add prisma @prisma/client
pnpm add -D prisma
```

### Phase 3: Project Structure

```
src/
├── app/
│   ├── (marketing)/          # Public pages group
│   │   ├── page.tsx          # Home
│   │   └── about/page.tsx
│   ├── (auth)/               # Auth pages group
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/          # Protected pages group
│   │   ├── layout.tsx        # Dashboard layout with auth
│   │   ├── page.tsx          # Dashboard home
│   │   └── settings/page.tsx
│   ├── api/                   # API routes (webhooks, etc.)
│   │   └── webhook/route.ts
│   ├── layout.tsx            # Root layout
│   ├── error.tsx             # Global error boundary
│   ├── loading.tsx           # Global loading
│   └── not-found.tsx         # 404 page
├── components/
│   ├── ui/                   # ShadCN components
│   ├── forms/                # Form components
│   └── layout/               # Layout components
├── lib/
│   ├── actions/              # Server Actions
│   │   ├── auth.ts
│   │   └── users.ts
│   ├── db.ts                 # Prisma client
│   ├── auth.ts               # Auth utilities
│   └── utils.ts              # Helpers
├── hooks/                    # Client-side hooks
└── types/
```

### Phase 4: Core Patterns

#### Root Layout (app/layout.tsx)

```tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { Providers } from '@/components/providers'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'My App',
  description: 'Built with Next.js 15',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
```

#### Server Component (Default)

```tsx
// app/users/page.tsx - Server Component (no 'use client')
import { db } from '@/lib/db'
import { UserList } from '@/components/user-list'

export default async function UsersPage() {
  // Direct database access - never exposed to client
  const users = await db.user.findMany({
    select: { id: true, name: true, email: true },
  })

  return (
    <div>
      <h1>Users</h1>
      <UserList users={users} />
    </div>
  )
}
```

#### Client Component (When Needed)

```tsx
// components/counter.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'

export function Counter({ initialCount = 0 }: { initialCount?: number }) {
  const [count, setCount] = useState(initialCount)

  return (
    <div className="flex items-center gap-4">
      <Button onClick={() => setCount(c => c - 1)}>-</Button>
      <span>{count}</span>
      <Button onClick={() => setCount(c => c + 1)}>+</Button>
    </div>
  )
}
```

#### Server Actions (lib/actions/users.ts)

```tsx
'use server'

import { z } from 'zod'
import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { db } from '@/lib/db'
import { getCurrentUser } from '@/lib/auth'

const createUserSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
})

export async function createUser(formData: FormData) {
  const currentUser = await getCurrentUser()
  if (!currentUser) {
    throw new Error('Unauthorized')
  }

  const parsed = createUserSchema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
  })

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors }
  }

  await db.user.create({
    data: parsed.data,
  })

  revalidatePath('/users')
  redirect('/users')
}

export async function deleteUser(id: string) {
  await db.user.delete({ where: { id } })
  revalidatePath('/users')
}
```

#### Form with Server Action

```tsx
// components/forms/create-user-form.tsx
'use client'

import { useFormStatus } from 'react-dom'
import { createUser } from '@/lib/actions/users'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

function SubmitButton() {
  const { pending } = useFormStatus()
  return (
    <Button type="submit" disabled={pending}>
      {pending ? 'Creating...' : 'Create User'}
    </Button>
  )
}

export function CreateUserForm() {
  return (
    <form action={createUser} className="space-y-4">
      <Input name="name" placeholder="Name" required />
      <Input name="email" type="email" placeholder="Email" required />
      <SubmitButton />
    </form>
  )
}
```

#### Protected Layout (app/(dashboard)/layout.tsx)

```tsx
import { redirect } from 'next/navigation'
import { getCurrentUser } from '@/lib/auth'
import { Sidebar } from '@/components/layout/sidebar'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const user = await getCurrentUser()

  if (!user) {
    redirect('/login')
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar user={user} />
      <main className="flex-1 p-6">{children}</main>
    </div>
  )
}
```

#### Loading & Error States

```tsx
// app/users/loading.tsx
import { Skeleton } from '@/components/ui/skeleton'

export default function Loading() {
  return (
    <div className="space-y-4">
      <Skeleton className="h-8 w-48" />
      <Skeleton className="h-64 w-full" />
    </div>
  )
}

// app/users/error.tsx
'use client'

import { Button } from '@/components/ui/button'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-4">
      <h2>Something went wrong!</h2>
      <Button onClick={reset}>Try again</Button>
    </div>
  )
}
```

#### Data Fetching with Caching

```tsx
// lib/queries/users.ts
import { unstable_cache } from 'next/cache'
import { db } from '@/lib/db'

export const getUsers = unstable_cache(
  async () => {
    return db.user.findMany({
      orderBy: { createdAt: 'desc' },
    })
  },
  ['users'],
  { revalidate: 60, tags: ['users'] }
)

export const getUser = unstable_cache(
  async (id: string) => {
    return db.user.findUnique({ where: { id } })
  },
  ['user'],
  { revalidate: 60, tags: ['users'] }
)
```

### Phase 5: Middleware (middleware.ts)

```typescript
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value
  const isAuthPage = request.nextUrl.pathname.startsWith('/login')
  const isDashboard = request.nextUrl.pathname.startsWith('/dashboard')

  if (isDashboard && !token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (isAuthPage && token) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/login', '/register'],
}
```

### Phase 6: Environment & Config

```typescript
// lib/env.ts
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(1),
  NEXTAUTH_URL: z.string().url(),
})

export const env = envSchema.parse(process.env)
```

## Output Format

```markdown
## Next.js Project Setup: [name]

### Created Structure
- src/app/ - App Router pages and layouts
- src/components/ - React components
- src/lib/actions/ - Server Actions
- src/lib/ - Database, auth, utilities

### Key Patterns
- Server Components by default
- Server Actions for mutations
- Route groups for organization
- Proper loading/error states

### Available Commands

| Command | Description |
|---------|-------------|
| pnpm dev | Start dev server |
| pnpm build | Build for production |
| pnpm lint | Run ESLint |
| pnpm db:push | Push Prisma schema |

### Next Steps
1. Set up database: `pnpm prisma init`
2. Add auth: `pnpm add next-auth`
3. Add ShadCN components: `pnpm dlx shadcn@latest add`
```
