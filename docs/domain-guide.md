# Adding a New Domain

Step-by-step guide to adding a new domain to the backend. Each step corresponds to a DDD building block from Evans (*Domain-Driven Design*) or Wlashin (*Domain Modeling Made Functional*).

## 1. Create the Domain Directory

```
server/domain/tasting/
├── types.ts
├── primitives.ts
├── command.ts
├── query.ts
└── infrastructure/
    ├── repository.ts
    └── graphql/
        ├── types.ts
        ├── queries.ts
        ├── mutations.ts
        └── inputs.ts
```

## 2. Define Types (`types.ts`)

> **Evans:** Value Objects (types defined by their value, not an identity) and Entities (types with an `id`). **Wlashin:** types as documentation — the type definition IS the domain model specification.

```ts
import type { Brand } from 'ts-brand'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

export type Rating = Brand<number, 'Rating'>

export type TastingNote = {
  userId: UserId
  beverageId: BeverageId
  rating?: Rating
  favorite?: boolean
  consumedDate?: Date
  createdAt: Date
}
```

## 3. Create Primitives (`primitives.ts`)

> **Wlashin:** making illegal states unrepresentable — if a value passes the Zod constructor, it is guaranteed valid throughout the system. No downstream code re-validates.

```ts
import { make } from 'ts-brand'
import { z } from 'zod'
import type { Rating as RatingType } from '~/domain/tasting/types'

export const Rating = (value: unknown) => {
  const v = z.number().int().min(1).max(5).parse(value)
  return make<RatingType>()(v)
}
```

Union types (string-literal unions) are validated here too, with `z.enum(...)`. **Never use `as MyType`** at a boundary — always go through the Zod constructor. See [branded-types.md](./branded-types.md).

## 4. Create Repository (`infrastructure/repository.ts`)

> **Evans:** Repository pattern — a collection-like interface over Firestore, hiding persistence details. Private to the bounded context.

A repository is a module of **bare exported functions** (not a namespace). Open the collection with `db()` and `genericDataConverter<T>()`, which turns Firestore `Timestamp`s back into `Date` on read:

```ts
import type { WriteBatch } from 'firebase-admin/firestore'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'
import type { TastingNote } from '~/domain/tasting/types'
import { db } from '~/system/firebase'
import { memoizedPerRequest } from '~/system/request-cache'
import { genericDataConverter } from '~/utils/firestore'

const tastings = () => db().collection('tasting').withConverter(genericDataConverter<TastingNote>())

// Satellite collections are keyed by the deterministic id `${userId}_${beverageId}`.
const docId = (userId: UserId, beverageId: BeverageId) => `${userId}_${beverageId}`

export const findAllByUser = (userId: UserId): Promise<TastingNote[]> =>
  memoizedPerRequest(`tasting:all:${userId}`, async () => {
    const snap = await tastings().where('userId', '==', userId).get()
    return snap.docs.map((doc) => doc.data())
  })

export const findBy = async (userId: UserId, beverageId: BeverageId) => {
  const doc = await tastings().doc(docId(userId, beverageId)).get()
  return doc.data() ?? null
}

export const save = async (note: TastingNote) => {
  await tastings().doc(docId(note.userId, note.beverageId)).set(note)
  return note
}

export const remove = async (userId: UserId, beverageId: BeverageId, batch?: WriteBatch) => {
  const ref = tastings().doc(docId(userId, beverageId))
  if (batch) batch.delete(ref)
  else await ref.delete()
}
```

For a collection with the standard `${userId}_${beverageId}` shape, you can skip the boilerplate and use `userBeverageRecordRepository<T>('tasting')` from `server/utils/firestore.ts`, which returns `findAllByUser`, `findBy`, `findManyByBeverageIds`, `save`, `remove`, `removeAllByUser` out of the box.

**Read-budget helpers** (all from `~/utils/firestore`): `atomically` (single-batch commit), `deleteInBatches`, `bulkSave`. Wrap expensive scans in `memoizedPerRequest` so a request reads once. See [architecture.md](./architecture.md#storage).

## 5. Create Query (`query.ts`)

> **Evans:** the Query namespace is the bounded context's public read interface. Other domains interact through this contract, never through the repository.

```ts
import * as repository from '~/domain/tasting/infrastructure/repository'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'

export namespace TastingQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byId = async (userId: UserId, beverageId: BeverageId) => {
    const note = await repository.findBy(userId, beverageId)
    if (!note) return 'not-found' as const
    return note
  }
}
```

## 6. Create Command (`command.ts`)

> **Evans:** Command as the public write interface. **Wlashin:** Railway-Oriented Programming — each outcome is a track, made explicit as a string-literal union.
>
> **Outcomes are rare and business-oriented.** They are bare strings (`'not-found'`), returned only when the domain has multiple legitimate outcomes. Success returns the domain value directly (or `undefined`). If a state is functionally impossible → `throw`, don't return an outcome. See [error-handling.md](./error-handling.md).

```ts
import type { WriteBatch } from 'firebase-admin/firestore'
import * as repository from '~/domain/tasting/infrastructure/repository'
import type { BeverageId } from '~/domain/beverage/types'
import type { Rating, TastingNote } from '~/domain/tasting/types'
import type { UserId } from '~/domain/shared/types'

export namespace TastingCommand {
  export const rate = async (userId: UserId, beverageId: BeverageId, rating: Rating) => {
    const existing = await repository.findBy(userId, beverageId)
    const note: TastingNote = { ...(existing ?? { userId, beverageId, createdAt: new Date() }), rating }
    return await repository.save(note)
  }

  export const removeBeverage = async (userId: UserId, beverageId: BeverageId, batch?: WriteBatch) => {
    await repository.remove(userId, beverageId, batch)
  }
}
```

## 7. Add the GraphQL Layer (`infrastructure/graphql/`)

- Object type in `types.ts` referencing the domain type as the Pothos backing model (`builder.objectRef<TastingNote>('TastingNote')`). Satellite fields are grafted onto `BeverageType` with `builder.objectField` and resolve through the per-request loaders in `server/domain/shared/graphql/loaders.ts`.
- Query fields in `queries.ts` delegating to the domain `Query`.
- Mutation fields in `mutations.ts` delegating to the domain `Command`/`UseCase`, mapping outcomes with `match().exhaustive()`.
- Input types in `inputs.ts`; enums in `enums.ts`.
- Register the module by importing it in `server/domain/shared/graphql/schema.ts`.
- Add a custom scalar in `scalars.ts` (and the `Scalars` map in `builder.ts`) for every new branded type. See [api-patterns.md](./api-patterns.md).
- Run `bun run generate:graphql` to regenerate `shared/schema.graphql`, then `cd ios && apollo-ios-cli generate`.

## Optional: Use Case (`use-case.ts`)

> **Evans:** Application Service — orchestrates operations across multiple bounded contexts without owning business logic itself.

When a resolver needs to coordinate several domains (e.g. add a beverage AND record who gave it, or delete a beverage AND every satellite), extract a use case:

```ts
export namespace BeverageUseCase {
  export const removeCompletely = async (userId: UserId, id: BeverageId) =>
    await atomically(async (batch) => {
      const error = await BeverageCommand.remove(userId, id, batch)
      if (error === 'not-found') return 'not-found' as const
      await Promise.all([
        CellarCommand.eraseBeverage(userId, id, batch),
        TastingCommand.removeBeverage(userId, id, batch),
        GiftCommand.removeBeverage(userId, id, batch),
      ])
      return undefined
    })
}
```

**Rules:**
- Names carry business intent (`addWithTasting`, `removeCompletely` — never `handleX`, `processX`).
- No direct storage access — go through commands/queries (`atomically` is the one exception: multi-domain deletes enlist into a single batch for atomicity).

## Optional: Business Rules (`business-rules.ts`)

> **Wlashin:** pure domain functions — all business logic is expressed as pure functions with no IO, making it trivially testable.

```ts
export const beverageStatus = (context: {
  inCellar: boolean
  gifted: boolean
  recommended: boolean
}): BeverageStatus => {
  if (context.inCellar) return 'in-cellar'
  if (context.gifted) return 'gifted'
  if (context.recommended) return 'recommended'
  return 'consumed'
}
```

**Rules:**
- Function names ARE the business concept (`beverageStatus`, `readyToDrink` — never `computeX`, `getX`).
- No IO, no async, no `db()` — pure input/output.
- Must have 100% test coverage (`business-rules.unit.test.ts`).

## Tests

Co-locate tests next to the file under test (no `__test__/` directories). Suffixes, highest to lowest level:

- **`*.feat.test.ts`** — feature tests: business scenarios at the GraphQL boundary (execute a query/mutation against the assembled schema).
- **`*.int.test.ts`** — integration tests: domain queries/commands with Firestore mocked via the in-memory fake.
- **`*.unit.test.ts`** — unit tests: primitives and pure `business-rules.ts` functions (no IO).

Mock Firestore with the shared fake so file ordering doesn't matter, and assert read budgets with `fake.docReads` / `fake.queryReads`:

```ts
import { beforeEach, expect, mock, test } from 'bun:test'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))
const { TastingCommand } = await import('~/domain/tasting/command')

let fake = resetFakeFirestore()
beforeEach(() => { fake = resetFakeFirestore() })

test('rating a beverage persists a note', async () => {
  const note = await TastingCommand.rate('user-1' as UserId, beverageId, Rating(4))
  expect(note.rating).toBe(4)
  expect(fake.snapshot('tasting').size).toBe(1)
})
```

Feature-level scenarios can use the BDD DSL from `server/test/bdd.ts` (`feature`, `scenario`, `given`, `when`, `then`, `and`) for readability — they are thin aliases over `describe`/`test` plus documentation markers.

## Checklist

- [ ] `types.ts` with branded types and discriminated unions
- [ ] `primitives.ts` with Zod constructors
- [ ] `infrastructure/repository.ts` (private, bare functions, `db()` + `genericDataConverter`)
- [ ] `query.ts` (public `Query` namespace)
- [ ] `command.ts` (public `Command` namespace)
- [ ] `infrastructure/graphql/` types/queries/mutations/inputs, imported in `schema.ts`
- [ ] Custom scalar in `scalars.ts` + `Scalars` map in `builder.ts` for each new branded type
- [ ] Tests: `.int.test.ts` for command/query, `.feat.test.ts` for GraphQL operations, `.unit.test.ts` for primitives/business rules
- [ ] Read budgets asserted (`fake.docReads` / `fake.queryReads`)
- [ ] Schema regenerated (`bun run generate:graphql`) and Apollo iOS codegen re-run
- [ ] `bunx nitro prepare && bun tsc --noEmit` passes
- [ ] (optional) `use-case.ts` if multi-domain orchestration is needed
- [ ] (optional) `business-rules.ts` with 100% coverage if logic is complex
