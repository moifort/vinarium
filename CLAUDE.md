# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cave à Vin (Wine Cellar) is a Nuxt 4 application built with Vue 3, TypeScript, and @nuxt/ui. The project uses Bun as the package manager and Biome for linting/formatting.

## Development Commands

```bash
# Start development server
bun run dev

# Build for production
bun run build

# Preview production build
bun run preview

# Type-check the codebase
bun run typecheck

# Lint and format (Biome)
bunx biome check .
bunx biome check --write .  # Auto-fix
```

## Architecture

### Nuxt 4 Directory Structure

This project uses Nuxt 4's `app/` directory as the default `srcDir`:

- **`app/`** - Application source code (components, pages, composables, etc.)
- **`server/`** - Nitro server routes and API endpoints (outside app/)
- **`public/`** - Static assets served from root
- **`shared/`** - Code shared between app and server contexts

The `~` alias points to `app/` (e.g., `~/components` → `app/components/`).

### Key Configuration

- **UI**: @nuxt/ui with TailwindCSS, primary color: green, neutral: slate
- **Formatting**: Biome (tabs, single quotes, auto-organize imports)
- **Icons**: Lucide and Simple Icons via @iconify-json

### Auto-imports

Nuxt auto-imports from these directories:
- `app/components/` - Vue components
- `app/composables/` - Composables (use `use` prefix: `useAuth`, `useWine`)
- `app/utils/` - Utility functions
- Vue/Nuxt APIs: `ref`, `computed`, `useState`, `useFetch`, `useRoute`

## Code Patterns

### State Management

Use `useState` for shared state (SSR-safe), not `ref`:

```typescript
// composables/useWines.ts
export const useWines = () => {
  const wines = useState<Wine[]>('wines', () => [])
  return { wines }
}
```

### Data Fetching

Use `useFetch` for API calls (handles SSR/hydration automatically):

```typescript
const { data, error, pending } = await useFetch('/api/wines')
```

### Server Routes

API routes go in `server/api/` with method suffixes:

```typescript
// server/api/wines/index.get.ts
export default defineEventHandler(async (event) => {
  return await db.wines.findMany()
})
```

## CI/CD

GitHub Actions runs on every push:
1. Lint check (Biome)
2. TypeScript type-check (vue-tsc)

Note: CI uses pnpm while local development uses Bun.
