# Cave-a-Vin - Project Directives

## Build & Verification Commands

- **Backend typecheck**: `bun tsc --noEmit`
- **Regenerate types** (if routes changed): `bunx nitro prepare` (run before `bun tsc`)
- **iOS build**:
  ```
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/CaveAVin.xcodeproj -scheme CaveAVin -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build
  ```
- **Linter**: `bunx biome check`
- **Runtime**: always use `bun`/`bunx`, never `npm`/`npx`

## Development Workflow

1. Always verify the build before committing (backend `bun tsc --noEmit` + `xcodebuild` depending on what was touched)
2. Run `bunx nitro prepare` before `bun tsc` if routes were added/modified
3. After each completed task: request user validation BEFORE committing
4. After each completed task: run an expert code review (`superpowers:requesting-code-review`) before proposing the commit

## Skills

- Use the `swiftui-expert-skill` skill for all SwiftUI code
- Use the `nitro-backend` skill for all backend Nitro/H3 code

## Backend Patterns (TypeScript/Nitro)

- Domain architecture: `server/{domain}/types.ts`, `primitives.ts`, `repository.ts`, `command.ts`, `query.ts`
- Branded types with `ts-brand` + Zod validation constructors in `primitives.ts`
- Discriminated unions for errors (no exceptions)
- File-based storage: `useStorage('wines')`, `useStorage('cellar')`, etc.
- Formatter: Biome (spaces, single quotes, no semicolons, line width 100)

## iOS Patterns (SwiftUI)

- Target: iOS 26.0, Swift 6 (strict concurrency)
- `@MainActor` on ViewModels, `Sendable` on model types
- Feature structure: `ios/CaveAVin/Features/{Feature}/`
- Xcode uses `fileSystemSynchronizedGroups` (no need to manually add files)
- `DEVELOPER_DIR` required because `xcode-select` points to CommandLineTools

## iOS Simulator

- Device: iPhone 17, OS 26.2
