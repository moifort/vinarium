# Code Style Guide

Many of these rules implement DDD principles from Evans (*Domain-Driven Design*) and functional modeling principles from Wlashin (*Domain Modeling Made Functional*).

## Formatter

Biome with:
- Spaces (2), single quotes, no semicolons
- Line width: 100

Run: `bunx biome check` (add `--write` to auto-fix). Runtime is always `bun`/`bunx`, never `npm`/`npx`.

## TypeScript Rules

### Never type return values

Let TypeScript infer:

```ts
// Bad
export const findAll = async (userId: UserId): Promise<Beverage[]> => { ... }

// Good
export const findAll = async (userId: UserId) => { ... }
```

### Full variable names

> **Evans:** Ubiquitous Language — code reads like the domain language. `migration` says what it is; `m` says nothing.

```ts
// Bad
migrations.filter((m) => m.version > fromVersion)

// Good
migrations.filter((migration) => migration.version > fromVersion)
```

### Destructure in callbacks

```ts
// Bad
sortBy(migrations, (m) => m.version)

// Good
sortBy(migrations, ({ version }) => version)
```

### Inline single-line guards

```ts
// Bad
if (!existing) {
  return 'not-found' as const
}

// Good
if (!existing) return 'not-found' as const
```

### `as const` on all literal returns

```ts
// Bad
return 'color-required'

// Good
return 'color-required' as const
```

### Use `Date` type, not `string`

Firestore `Timestamp`s are converted to `Date` on read by `genericDataConverter` — model dates as `Date`, never `string`.

```ts
// Bad
type Purchase = { date?: string }

// Good
type Purchase = { date?: Date }
```

### Branded types are primitives at runtime

Never wrap a branded value with `String()` or `Number()` — `BeverageName` IS a `string`, `Rating` IS a `number`. The brand is compile-time only. See [branded-types.md](./branded-types.md).

### Error handling at caller level

```ts
// Bad — try/catch in each unit
export const migrate = async () => {
  try { ... } catch (e) { ... }
}

// Good — try/catch in the runner/orchestrator
for (const migration of pending) {
  try {
    const result = await migration.migrate({ db })
  } catch (error) { ... }
}
```

### Use lodash-es

```ts
import { sortBy, keyBy, uniq, chunk } from 'lodash-es'

// Prefer keyBy over new Set + map
const byId = keyBy(beverages, ({ id }) => id)

// Prefer uniq over new Set
const colors = uniq(beverages.map(({ color }) => color))
```

### All union types validated in `primitives.ts`

> **Wlashin:** making illegal states unrepresentable — every union value is validated through a Zod constructor, so invalid variants cannot exist at runtime.

```ts
// Bad
const color = input.color as WineColor

// Good
const color = WineColor(input.color)
```

### Never `switch` — use `match().exhaustive()`

> **Wlashin:** totality — `.exhaustive()` forces every case to be handled. Adding a new outcome becomes a compile error, not a silent bug.

```ts
import { match, P } from 'ts-pattern'

// Bad
switch (result) { ... }

// Good
match(result)
  .with('not-found', () => notFound('Beverage not found'))
  .with(P.not(P.string), (beverage) => beverage)
  .exhaustive()
```

### Never `for`/`while` loops — use functional style

> **Wlashin:** functional composition — `map`/`filter`/`reduce` express intent declaratively.

```ts
// Bad
for (const beverage of beverages) { ... }

// Good
beverages.map((beverage) => ...)
beverages.filter((beverage) => ...)
sortBy(beverages, ({ createdAt }) => createdAt)
```

(A bounded `for` loop over Firestore batch chunks is the pragmatic exception — batching writes under the 500-op cap is inherently sequential.)

### Arrays never optional

> **Wlashin:** every value of the type is valid — `[]` is a perfectly valid array. Optional arrays create two representations of "empty" (`undefined` vs `[]`), an illegal state.

```ts
// Bad
type Beverage = { grapeVarieties?: string[] }  // inside an always-present object

// Good
history: JournalEntry[]  // [] is the neutral state
```

This applies to both backend TypeScript and iOS Swift.

### No boolean derivable from another field

Never add a boolean when its truth is derivable (e.g. `consumedDate` already implies "consumed"). Derive it in a pure function or a resolver instead.

## Naming

Function names carry the **business concept**, not the technical pattern. The name IS the rule or action: `beverageStatus`, `readyToDrink`, `removeCompletely` — never `computeStatus`, `handleCreate`, `processDelete`.

## Language

All code, comments, commit messages, and documentation are in **English**. The only French in the repo is user-facing copy (`CHANGELOG.md` and the iOS app's on-screen text).

## Swift Rules

- `@MainActor` on all ViewModels
- `Sendable` on all model types
- `@Observable` (not `ObservableObject`)
- Components take primitives, not full domain objects
- Write actual UTF-8 characters in strings (`"Série"`, not `"S\u{00E9}rie"`)

See [ios-guide.md](./ios-guide.md).
