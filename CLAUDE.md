# Cave-a-Vin - Project Directives

## Build & Verification Commands

- **Backend typecheck**: `bun tsc --noEmit`
- **Regenerate types** (if routes changed): `bunx nitro prepare` (run before `bun tsc`)
- **iOS build**:
  ```
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
  ```
- **Unit tests**: `bun test`
- **Test coverage**: `bun test --coverage`
- **Linter**: `bunx biome check`
- **Runtime**: always use `bun`/`bunx`, never `npm`/`npx`

## Development Workflow

1. Always verify the build before committing (backend `bun tsc --noEmit` + `xcodebuild` depending on what was touched)
2. Run `bunx nitro prepare` before `bun tsc` if routes were added/modified
3. After each completed task: run an expert code review (`superpowers:requesting-code-review`) before proposing the commit
4. After each completed task: request user validation BEFORE committing

## Skills

- Use the `swiftui-expert-skill` skill for all SwiftUI code
- Use the `nitro-backend` skill for all backend Nitro/H3 code
- Use the `superpowers:requesting-code-review` skill for all code reviews

## Backend Patterns (TypeScript/Nitro)

- Domain architecture: `server/domain/{domain}/types.ts`, `primitives.ts`, `repository.ts`, `command.ts`, `query.ts`
- **`business-rules.ts`** (optional): pure functions (no IO, no async) extracted from complex commands. Function names ARE the business concept (`wineStatus`, `readyToDrink` — never `computeX`, `getX`, `calculateX`). Must have 100% test coverage (`business-rules.unit.test.ts`)
- **`use-case.ts`** (optional): multi-domain orchestrations when a route needs to coordinate several commands/queries. Names carry business intent (`addWithTasting`, `removeCompletely` — never `handleX`, `processX`). No direct storage access.
- **Read models**: `server/read-model/{domain}/` — composite views assembling multiple domains for display needs. Mirror the `domain/` structure. Only import public Query/Command namespaces, never repositories.
- Branded types with `ts-brand` + Zod validation constructors in `primitives.ts`
- Discriminated unions for errors (no exceptions)
- File-based storage: `useStorage('wines')`, `useStorage('cellar')`, etc.
- **Naming**: function names carry the business concept, not the technical pattern. The name IS the rule or action.
- **BDD DSL**: `server/test/bdd.ts` — `feature()`, `scenario()`, `given()`, `when()`, `then()`, `and()` over `bun:test`. Feature tests use `.feat.test.ts` suffix.
- Formatter: Biome (spaces, single quotes, no semicolons, line width 100)

## Database Migrations

- Location: `server/system/migration/`
- Forward-only sequential migrations, no rollback
- Meta tracked in `useStorage('migration-meta')` (key `state`)
- Nitro plugin (`server/plugins/migration.ts`) runs migrations at boot, `process.exit(1)` on failure
- To add a migration: create `server/system/migration/migrations/NNNN-name.ts`, register in `migrations/index.ts`
- Migration `version` uses branded `MigrationVersion` (starts at 1, version 0 is reserved sentinel)
- Migrations receive a `MigrationContext` with `storage()` accessor, return `MigrationResult`
- Runner wraps each migration in try/catch — migrations don't need their own error handling
- Test reset (`server/routes/test/reset.post.ts`) clears `migration-meta` so migrations re-run
- **When to migrate**: renaming a field, changing a field's structure, changing enum values, removing stale data
- **No migration needed**: adding a new optional (`?`) field, adding a new storage namespace, changing query logic/routes

## iOS Patterns (SwiftUI)

- Target: iOS 26.0, Swift 6 (strict concurrency)
- `@MainActor` on ViewModels, `Sendable` on model types
- Feature structure: `ios/CaveAVin/Features/{Feature}/` with `pages/`, `organisms/`, `molecules/` subdirectories
- Shared atoms: `ios/CaveAVin/Shared/Components/` — cross-feature reusable views (badges, ratings, labeled rows)
- **Primitive-first views**: leaf views receive only primitives (`String`, `Int`, `Bool`, `Date?`, `WineColor`, closures) — never domain structs (`Wine`, `UserWineDetail`, `CellarBottle`). Use nested `Item` structs for 5+ parameters
- **Previews as Storybook**: every component below page level must be previewable without a running server
- **Pages = coordinators**: handle loading, error, sheets, toolbar, API calls. Map domain models to primitives for children
- **Organisms as mapping boundaries**: can accept domain structs when they break them down into primitives for child sections
- Xcode uses `fileSystemSynchronizedGroups` (no need to manually add files)
- `DEVELOPER_DIR` required because `xcode-select` points to CommandLineTools

## API Token

The API token is used for authentication when `NITRO_API_TOKEN` is set. To rotate the token, update it in:
- `.env` (`NITRO_API_TOKEN=...`)
- `ios/CaveAVin/Shared/Secrets.swift` (gitignored)
- `ios/CaveAVinUITests/Support/TestSecrets.swift` (gitignored)

See `.example` files next to the Secrets files for the expected format.

## iOS Simulator

- Device: iPhone 17, OS 26.2


