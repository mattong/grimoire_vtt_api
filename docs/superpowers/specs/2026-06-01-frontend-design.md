# Frontend SPA Design

> **Date:** 2026-06-01
> **Status:** Design (pre-implementation)
> **Version:** 0.6.0-alpha target

**Goal:** Build a React SPA that consumes the full Grimoire VTT API — auth, games, resource templates, and resources.

**Prerequisites:** Backend CORS must be configured to allow `http://localhost:5173` (see `docs/superpowers/specs/2026-06-01-cors-design.md`).

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | React 19 (SPA, no Next.js) |
| Build | Vite 6 |
| Language | TypeScript (strict mode) |
| Styling | Tailwind CSS 4 |
| Components | shadcn/ui (Radix + Tailwind) |
| Routing | React Router v7 |
| Server state | TanStack Query v5 |
| Forms | React Hook Form v7 + Zod |
| HTTP | Native `fetch` (no Axios) |

## Code Conventions

All functions use arrow syntax: `const fnName = () => { ... }`. No `function` keyword. `const` over `let` unless reassignment is required.

---

## Project Structure

```
grimoire-vtt/
  src/
    api/
      client.ts            # fetch wrapper — JWT injection, 401 handling
      auth.ts              # signup, login, logout calls
      games.ts             # fetchGames, createGame, updateGame, archiveGame
      resource-templates.ts
      resources.ts

    features/
      auth/
        AuthContext.tsx     # { user, token, login, signup, logout }
        LoginPage.tsx
        SignupPage.tsx
      games/
        hooks.ts           # useMyGmGames, useMyPlayerGames, useGame, createGame, etc.
        GameListPage.tsx    # tabs: GMing / Playing
        GameDetailPage.tsx  # tabs: Templates / Resources
        GameForm.tsx        # create/edit dialog
      templates/
        hooks.ts           # useTemplates, useTemplate, createTemplate, etc.
        TemplateList.tsx
        TemplateDetailPage.tsx
        TemplateForm.tsx
      resources/
        hooks.ts           # useResources, useResource, createResource, etc.
        ResourceList.tsx
        ResourceDetailPage.tsx
        ResourceForm.tsx    # dynamic form from schema.fields
        DynamicField.tsx    # single field control rendered from field definition
        TemplateSelectDialog.tsx  # pick a template before creating a resource

    components/
      ui/                  # shadcn/ui generated primitives
      Layout.tsx           # sidebar + main content outlet
      Sidebar.tsx          # game navigation
      ProtectedRoute.tsx   # redirects to /login if no token
      ErrorBanner.tsx      # error display with retry
      Skeleton.tsx         # loading placeholder

    types/
      api.ts               # TypeScript interfaces matching API contract

    App.tsx
    main.tsx
```

---

## Routing Table

```
Path                              Component           Auth   Layout
/login                            LoginPage           No     None
/signup                           SignupPage          No     None
/                                 GameListPage        Yes    App
/games/:slug                      GameDetailPage      Yes    App
/games/:slug/templates            TemplateList        Yes    App
/games/:slug/templates/:tslug     TemplateDetailPage  Yes    App
/games/:slug/resources            ResourceList        Yes    App
/games/:slug/resources/:rslug     ResourceDetailPage  Yes    App
```

---

## API Client Design

### `api/client.ts`

A single fetch wrapper that:

1. Reads JWT from localStorage (`grimoire_jwt` key)
2. Injects `Authorization: Bearer <token>` header
3. On 401 response: clears localStorage, redirects to `/login`
4. On non-OK response: parses error body and throws `ApiError`
5. On success: returns parsed JSON

```ts
const TOKEN_KEY = 'grimoire_jwt'

const getToken = (): string | null => localStorage.getItem(TOKEN_KEY)
const setToken = (token: string) => localStorage.setItem(TOKEN_KEY, token)
const clearToken = () => localStorage.removeItem(TOKEN_KEY)

class ApiError extends Error {
  status: number
  constructor(message: string, status: number) {
    super(message)
    this.status = status
  }
}

const apiFetch = async <T>(path: string, options: RequestInit = {}): Promise<T> => {
  const token = getToken()
  const res = await fetch(`${import.meta.env.VITE_API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })

  if (res.status === 401) {
    clearToken()
    window.location.href = '/login'
    throw new ApiError('Unauthorized', 401)
  }

  if (!res.ok) {
    const body = await res.json()
    throw new ApiError(
      body.error || body.errors?.join(', ') || 'Unknown error',
      res.status
    )
  }

  return res.json()
}
```

### `api/auth.ts`

```ts
const login = async (username: string, password: string) => {
  const res = await fetch(`${import.meta.env.VITE_API_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ user: { username, password } }),
  })
  if (!res.ok) {
    const body = await res.json()
    throw new ApiError(body.error || 'Login failed', res.status)
  }
  const token = res.headers.get('Authorization')?.replace('Bearer ', '')
  const data = await res.json()
  return { token, user: data.user }
}
```

> **Note:** `/api/auth/login` and `/api/auth/signup` return the JWT in the `Authorization` response **header** (not the body). The login/signup functions must read it from `res.headers.get('Authorization')`.

### API modules

`api/games.ts`, `api/resource-templates.ts`, `api/resources.ts` — each exports pure async functions that call `apiFetch`:

```ts
// api/games.ts
const fetchGames = (role: 'gm' | 'player'): Promise<Game[]> =>
  apiFetch(`/api/games?role=${role}`)

const fetchGame = (slug: string): Promise<Game> =>
  apiFetch(`/api/games/${slug}`)

const createGame = (data: CreateGameInput): Promise<Game> =>
  apiFetch('/api/games', {
    method: 'POST',
    body: JSON.stringify({ game: data }),
  })

const updateGame = (slug: string, data: UpdateGameInput): Promise<Game> =>
  apiFetch(`/api/games/${slug}`, {
    method: 'PATCH',
    body: JSON.stringify({ game: data }),
  })

const archiveGame = (slug: string): Promise<{ message: string; archived_at: string }> =>
  apiFetch(`/api/games/${slug}`, { method: 'DELETE' })
```

---

## Auth Context

```ts
// features/auth/AuthContext.tsx
interface AuthState {
  user: { username: string } | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (username: string, password: string) => Promise<void>
  signup: (username: string, password: string, passwordConfirmation: string) => Promise<void>
  logout: () => Promise<void>
}
```

**Mount behavior:**
1. Read token from localStorage
2. If token exists, set it (no user info fetched — the user info is only in the auth response)
3. If no token, redirect to `/login`

Actually — since the API doesn't have a "get current user" endpoint, the user data is only returned on login/signup. We store the `{ username }` in AuthContext alongside the token.

**Login flow:**
1. Call `api/login` → get back `{ token, user: { username } }`
2. Store token in localStorage, user in state
3. Navigate to `/`

**Logout flow:**
1. Call `DELETE /api/auth/logout` via `apiFetch`
2. Clear localStorage, clear state
3. Navigate to `/login`

---

## Page Components

### Layout (`components/Layout.tsx`)

```
┌──────────────────────────────────────────┐
│  Sidebar (fixed, w-64)    │  <Outlet />   │
│                           │               │
│  User: <username>         │  Page content │
│  ───────────────────      │               │
│  My Games                 │               │
│  ├ curse-of-strahd        │               │
│  └ stormkings-thunder     │               │
│                           │               │
│  Logout                   │               │
└──────────────────────────────────────────┘
```

### GameListPage (`features/games/GameListPage.tsx`)

```
┌──────────────────────────────────────┐
│  Tabs: [GMing] [Playing]             │
│                                      │
│  ┌─── GMing ─────────────────────┐   │
│  │                                │   │
│  │  curse-of-strahd        [Edit]│   │
│  │  D&D 5e · 4 members          │   │
│  │                               │   │
│  │  stormkings-thunder     [Edit]│   │
│  │  D&D 5e · 2 members          │   │
│  │                               │   │
│  │  [+ New Game]                │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌─── Playing ──────────────────┐   │
│  │                               │   │
│  │  descent-into-avernus  [View]│   │
│  │  D&D 5e · 6 members          │   │
│  │                               │   │
│  └──────────────────────────────┘   │
└──────────────────────────────────────┘
```

**Data flow:**
```ts
const { data: gmGames, isLoading: gmLoading } = useMyGmGames()
const { data: playerGames, isLoading: playerLoading } = useMyPlayerGames()
```

### GameDetailPage (`features/games/GameDetailPage.tsx`)

Top: game title, description, system. Then tabs:

```
┌─────────┐ ┌───────────┐
│Templates│ │  Resources │  ← tab bar
└─────────┘ └───────────┘
┌─────────────────────────────┐
│ Content depends on tab      │
│ ...                         │
└─────────────────────────────┘
```

### TemplateList (`features/templates/TemplateList.tsx`)

```
┌──────────────────────────────────────────┐
│  [+ New Template]  (GM only)             │
│                                          │
│  Name        │ Type      │ Created By    │
│  ─────────── │ ────────  │ ──────────    │
│  Character   │ character │ GM            │
│  Items       │ item      │ GM            │
│  Conditions  │ status    │ All           │
│                                          │
│  (Click row → Template Detail)           │
└──────────────────────────────────────────┘
```

### TemplateDetailPage (`features/templates/TemplateDetailPage.tsx`)

Shows template name, type, creatable_by. Below that, the schema field list as a table:

```
┌──────────────────────────────────────────┐
│  Template: Character                     │
│  Type: character · Creatable by: GM      │
│  [Edit] [Delete]  (GM only)              │
│                                          │
│  Schema Fields:                          │
│  Field Key   │ Label        │ Input Type │
│  ─────────── │ ──────────── │ ─────────  │
│  strength    │ Strength     │ number     │
│  dexterity   │ Dexterity    │ number     │
│  backstory   │ Backstory    │ textarea   │
│  class       │ Class        │ select     │
└──────────────────────────────────────────┘
```

### ResourceList (`features/resources/ResourceList.tsx`)

```
┌──────────────────────────────────────────┐
│  [+ New Resource]                        │
│                                          │
│  Filter by template: [All ▼]             │
│                                          │
│  Name        │ Template   │ Owner        │
│  ─────────── │ ─────────  │ ─────────    │
│  Aragorn     │ Character  │ matt         │
│  Longsword   │ Items      │ —            │
│  Poisoned    │ Conditions │ matt         │
│                                          │
│  (Click row → Resource Detail)           │
└──────────────────────────────────────────┘
```

### ResourceDetailPage (`features/resources/ResourceDetailPage.tsx`)

```
┌──────────────────────────────────────────┐
│  Resource: Aragorn                       │
│  Template: Character                     │
│  Owner: matt                             │
│  [Edit] [Delete]  (owner or GM only)     │
│                                          │
│  ┌─ Data ─────────────────────────────┐  │
│  │                                     │  │
│  │  Strength     18                    │  │
│  │  Dexterity    14                    │  │
│  │  Backstory    Orphaned by orcs...   │  │
│  │  Class        Ranger                │  │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

Data fields are rendered by iterating over `resource.resource_template.schema.fields` and looking up each `field_key` in `resource.data`.

### ResourceForm — Dynamic Form (`features/resources/ResourceForm.tsx`)

When creating, the user first selects a template (opens `TemplateSelectDialog`). The form then renders the dynamic fields from `template.schema.fields`:

```tsx
const ResourceForm = ({ template, resource, onSubmit }) => {
  const { control, handleSubmit } = useForm({
    defaultValues: {
      name: resource?.name ?? '',
      data: resource?.data ?? {},
    },
  })

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Input {...register('name')} label="Name" />

      {template.schema.fields.map((fieldDef) => (
        <DynamicField key={fieldDef.field_key} fieldDef={fieldDef} control={control} />
      ))}

      <Button type="submit">Save</Button>
    </form>
  )
}
```

### DynamicField (`features/resources/DynamicField.tsx`)

```tsx
interface FieldDef {
  field_key: string
  label: string
  input_type: string
}

const inputTypeMap: Record<string, string> = {
  text: 'text',
  number: 'number',
  textarea: 'textarea',
  select: 'select',
  boolean: 'checkbox',
}

const DynamicField = ({ fieldDef, control }) => {
  const { field } = useController({
    name: `data.${fieldDef.field_key}`,
    control,
  })

  const type = inputTypeMap[fieldDef.input_type] ?? 'text'

  switch (type) {
    case 'textarea':
      return <Textarea {...field} label={fieldDef.label} />
    case 'select':
      return <Select {...field} label={fieldDef.label} options={/* future: options from fieldDef */} />
    case 'checkbox':
      return <Checkbox {...field} label={fieldDef.label} />
    default:
      return <Input {...field} type={type} label={fieldDef.label} />
  }
}
```

---

## Error Handling

### Query errors (TanStack Query)

Each query hook returns `{ data, isLoading, isError, error, refetch }`. Pages render:

```tsx
if (isLoading) return <Skeleton />
if (isError) return <ErrorBanner message={error.message} onRetry={refetch} />
```

### Mutation errors (forms)

422 responses return `{ "errors": ["Name can't be blank", ...] }`. These are caught in the mutation's `onError` handler and surfaced as a banner:

```tsx
const mutation = useMutation({
  mutationFn: (data) => createGame(data),
  onError: (err) => {
    if (err.status === 422) setFormErrors(err.message.split(', '))
    else showToast(err.message)
  },
})
```

---

## Sidebar Navigation

The sidebar shows the current user's game list (GM + player combined, with a small badge) so the user can switch games without going back to the dashboard. The current game is highlighted.

---

## Dependency Tracking

This frontend spec depends on the following backend changes (each in its own spec):

| Dependency | Spec | Why |
|---|---|---|
| CORS | `2026-06-01-cors-design.md` | Port 5173 cannot reach port 3000 without CORS headers |
| Slugs | `2026-06-01-slugs-design.md` | Routes use slugs (`/games/curse-of-strahd`) instead of UUIDs |
| Game role filtering | `2026-06-01-game-role-filtering-design.md` | Tabbed game list (GMing/Playing) fetches from `?role=gm` / `?role=player` |

### Fallback Without Role Filtering

If the game role filtering backend change is not yet available, the frontend can fall back to fetching `GET /api/games` (all games) and splitting by role client-side using the `game_memberships` data. The tabbed UI structure remains the same — only the data source changes.
