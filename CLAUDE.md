# Vinarium - Project Directives

## Language

Everything versioned and technical is written in **English**: commit messages, code, code comments, and documentation (README, this file). The **only** French in the repo is user-facing copy — `CHANGELOG.md` entries and the iOS app's on-screen text. Never mix languages in a commit message or a comment.

## Build & Verification Commands

- **Backend typecheck**: `bun tsc --noEmit`
- **Regenerate types** (if routes changed): `bunx nitro prepare` (run before `bun tsc`)
- **iOS build**:
  ```
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Vinarium.xcodeproj -scheme Vinarium -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
  ```
- **Unit tests**: `bun test`
- **Test coverage**: `bun test --coverage`
- **Linter**: `bunx biome check`
- **Runtime**: always use `bun`/`bunx`, never `npm`/`npx`
- **GraphQL codegen** (if the schema changed): `bun run generate:graphql` (regenerates `shared/schema.graphql`), then `cd ios && apollo-ios-cli generate` (config `ios/apollo-codegen-config.json`)

## Development Workflow

1. Always verify the build before committing (backend `bun tsc --noEmit` + `xcodebuild` depending on what was touched)
2. Run `bunx nitro prepare` before `bun tsc` if routes were added/modified
3. After each completed task: run an expert code review (`superpowers:requesting-code-review`) before committing
4. **Commit freely**: group and commit changes as you see fit without asking the user — don't ask about grouping, you decide.
5. **Never push until the user explicitly says "push".** Commits accumulate locally; pushing is user-gated.

### Push protocol (only when the user says "push")

Before pushing, update the user-facing surfaces, then push:

1. **README** (`README.md`): update the Features list / Tech Stack if the pushed work changed them.
2. **README previews** (`screenshots/*.png`): regenerate the affected screenshots if the touched UI changed visually.
3. **Changelog** (`CHANGELOG.md`): add user-facing entries (in French) under `## Unreleased`, then run `bun run generate:assets` to regenerate `server/system/changelog-content.ts` (the iOS-facing asset served via GraphQL — never edit it by hand).
4. Push.

## Skills

- Use the `swiftui-expert-skill` skill for all SwiftUI code
- Use the `nitro-backend` skill for all backend Nitro/H3 code
- Use the `superpowers:requesting-code-review` skill for all code reviews

## Backend Patterns (TypeScript/Nitro)

- Domain architecture: `server/domain/{domain}/types.ts`, `primitives.ts`, `command.ts`, `query.ts`, `infrastructure/repository.ts`, `infrastructure/graphql/`
- **`business-rules.ts`** (optional): pure functions (no IO, no async) extracted from complex commands. Function names ARE the business concept (`wineStatus`, `readyToDrink` — never `computeX`, `getX`, `calculateX`). Must have 100% test coverage (`business-rules.unit.test.ts`)
- **`use-case.ts`** (optional): multi-domain orchestrations when a route needs to coordinate several commands/queries. Names carry business intent (`addWithTasting`, `removeCompletely` — never `handleX`, `processX`). No direct storage access.
- Branded types with `ts-brand` + Zod validation constructors in `primitives.ts`
- Discriminated unions for errors (no exceptions)
- **Storage: native Firestore** (`firebase-admin`) via `db()` from `server/system/firebase.ts`, only inside `infrastructure/repository.ts`. Helpers in `server/utils/firestore.ts`: `genericDataConverter<T>()` (Timestamp→Date), `atomically(batch => ...)` (single-batch commits), `deleteInBatches(refs)`, `userWineRecordRepository<T>(collection)` (satellite collections keyed `${userId}_${wineId}`: tasting/gift/recommendation)
- **GraphQL** (Apollo Server + Pothos, single endpoint `POST /graphql`): nested `WineType` fields (cellar, consumption, gift, recommendation, history) must never scan a collection or read one doc per parent row (N+1). They resolve through the per-request loaders in `server/domain/shared/graphql/loaders.ts` (memoized + micro-batched by `wineId`, built per request on the GraphQL context) — a page of 40 wines costs one batched read per selected satellite, an unselected satellite costs nothing. Read budgets are asserted in tests via `fake.docReads`/`fake.queryReads`
- **Naming**: function names carry the business concept, not the technical pattern. The name IS the rule or action.
- **Tests**: `*.unit.test.ts` with `bun:test`. Firestore is mocked via `server/test/fake-firestore.ts` (`mock.module('~/system/firebase', () => ({ db: fakeDb }))`) — records batches, direct writes and read counts (`fake.reads`) to assert atomicity and read budgets
- Formatter: Biome (spaces, single quotes, no semicolons, line width 100)

## Database Migrations

- Location: `server/system/migration/`
- Forward-only sequential migrations, no rollback
- Meta tracked in the Firestore collection `migration-meta` (doc `state`)
- Triggered by `POST /admin/migrate` (`server/routes/admin/migrate.post.ts`), called by `scripts/bootstrap.sh` during provisioning — no boot-time plugin
- To add a migration: create `server/system/migration/migrations/NNNN-name.ts`, register in `migrations/index.ts`
- Migration `version` uses branded `MigrationVersion` (starts at 1, version 0 is reserved sentinel)
- Migrations receive a `MigrationContext` with the Firestore `db`, return `MigrationResult`
- Runner wraps each migration in try/catch — migrations don't need their own error handling
- **When to migrate**: renaming a field, changing a field's structure, changing enum values, removing stale data
- **No migration needed**: adding a new optional (`?`) field, adding a new collection, changing query logic/routes

## iOS Patterns (SwiftUI)

- Target: iOS 26.0, Swift 6 (strict concurrency)
- `@MainActor` on ViewModels, `Sendable` on model types
- Feature structure: `ios/Vinarium/Features/{Feature}/` with `pages/`, `organisms/`, `molecules/` subdirectories
- Shared atoms: `ios/Vinarium/Shared/Components/` — cross-feature reusable views (badges, ratings, labeled rows)
- **Primitive-first views**: leaf views receive only primitives (`String`, `Int`, `Bool`, `Date?`, `WineColor`, closures) — never domain structs (`Wine`, `UserWineDetail`, `CellarBottle`). Use nested `Item` structs for 5+ parameters
- **Previews as Storybook**: every component below page level must be previewable without a running server
- **Pages = coordinators**: handle loading, error, sheets, toolbar, API calls. Map domain models to primitives for children
- **Organisms as mapping boundaries**: can accept domain structs when they break them down into primitives for child sections
- Xcode uses `fileSystemSynchronizedGroups` (no need to manually add files)
- `DEVELOPER_DIR` required because `xcode-select` points to CommandLineTools

## API Token

The API token is used for authentication when `NITRO_API_TOKEN` is set. To rotate the token, update it in:
- `.env` (`NITRO_API_TOKEN=...`)
- `ios/Vinarium/Shared/Secrets.swift` (gitignored)
- `ios/VinariumUITests/Support/TestSecrets.swift` (gitignored)

See `.example` files next to the Secrets files for the expected format.

## iOS Simulator

- Device: iPhone 17, OS 26.2


