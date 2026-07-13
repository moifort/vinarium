# API Patterns (GraphQL)

The public API is **GraphQL only** — a single `POST /graphql` served by Apollo Server, plus the operational `POST /admin/migrate`. There are no REST resource routes. The schema is code-first with [Pothos](https://pothos-graphql.dev/); each domain contributes its types/queries/mutations from `server/domain/{domain}/infrastructure/graphql/`, all registered on the shared `builder` and assembled in `server/domain/shared/graphql/schema.ts`.

## The Endpoint

`server/routes/graphql.ts` builds a fresh context per request — the H3 `event`, the authenticated `userId` (set by middleware on `event.context`), and a fresh per-request loader set:

```ts
const context = async () => ({ event, userId, loaders: beverageSatelliteLoaders(userId) })
```

A missing `userId` yields a `401` before Apollo runs.

## Query — List

Delegate to the domain `Query` namespace. Args carry `defaultValue`s and Pothos descriptions (visible in Apollo Sandbox):

```ts
builder.queryField('beverages', (t) =>
  t.field({
    type: BeveragesType,
    description: 'A page of the current user’s beverage list, filtered and sorted per view',
    args: {
      mode: t.arg({ type: BeverageListModeEnum, defaultValue: 'all', description: 'List preset' }),
      sort: t.arg({ type: BeverageSortEnum, defaultValue: 'updatedAt', description: 'Order field' }),
      limit: t.arg.int({ defaultValue: 40, description: 'Maximum beverages returned' }),
      after: t.arg({ type: 'BeverageId', description: 'Cursor: the beverage id to page after' }),
    },
    resolve: async (_root, args, { userId }) =>
      BeverageQuery.list(userId, {
        mode: args.mode ?? 'all',
        sort: args.sort ?? 'updatedAt',
        limit: args.limit ?? 40,
        after: args.after ?? undefined,
      }),
  }),
)
```

## Query — Single (nullable)

`DefaultFieldNullability` is `false`, so a field that may be absent opts in with `nullable: true`. Map a `'not-found'` outcome to `null` for a plain lookup:

```ts
builder.queryField('beverage', (t) =>
  t.field({
    type: BeverageType,
    nullable: true,
    description: 'Get a single beverage by ID — the viewer’s own or a household member’s',
    args: { id: t.arg({ type: 'BeverageId', required: true, description: 'Beverage to fetch' }) },
    resolve: async (_root, { id }, { userId }) => {
      const beverage = await BeverageQuery.byIdForViewer(userId, id)
      return beverage === 'not-found' ? null : beverage
    },
  }),
)
```

## Mutation — Create / Update / Delete

Delegate to a domain `Command` or a `UseCase`, then map string-literal outcomes with `match().exhaustive()`. The success arm matches "not a string" (`P.not(P.string)`) and returns the domain value; failure arms throw via the shared error helpers:

```ts
import { match, P } from 'ts-pattern'
import { badUserInput, notFound } from '~/domain/shared/graphql/errors'

builder.mutationField('addBeverage', (t) =>
  t.field({
    type: BeverageType,
    description: 'Add a new beverage to the catalog',
    args: {
      input: t.arg({ type: AddBeverageInput, required: true, description: 'New beverage fields' }),
    },
    resolve: async (_root, { input }, { userId }) => {
      const clean = stripNulls(input)
      const result = await BeverageUseCase.add(userId, clean.name, clean.beverageType ?? 'wine', toData(clean))
      return match(result)
        .with('color-required', () => badUserInput('A wine requires a color'))
        .with('subtype-invalid', () => badUserInput('This subtype does not fit the beverage type'))
        .with(P.not(P.string), (beverage) => beverage)
        .exhaustive()
    },
  }),
)
```

A delete returns a `Boolean` and matches `undefined` (the command's success value):

```ts
resolve: async (_root, { id }, { userId }) => {
  const result = await BeverageUseCase.removeCompletely(userId, id)
  return match(result)
    .with('not-found', () => notFound('Beverage not found'))
    .with(undefined, () => true)
    .exhaustive()
}
```

## Nested Resolvers & the N+1 Rule

Satellite fields on an object type (`Beverage.cellar`, `.consumption`, `.gift`, `.recommendation`, `.history`) are grafted on by their own domains via `builder.objectField`. They **must never** scan a collection or read one doc per parent row. Each resolves through the matching per-request loader (`server/domain/shared/graphql/loaders.ts`), which memoizes and micro-batches by `beverageId`:

```ts
builder.objectField(BeverageType, 'cellar', (t) =>
  t.field({
    type: CellarBottleType,
    nullable: true,
    resolve: (beverage, _args, { loaders }) => loaders.cellar.load(beverage),
  }),
)
```

A page of 40 beverages selecting `cellar` costs **one** 40-ref batched read; an unselected satellite costs nothing. Enforce this in feature tests with the read-budget counters (`fake.docReads`, `fake.queryReads`).

## Input Validation at the Boundary

Every branded value has a custom Pothos scalar in `server/domain/shared/graphql/scalars.ts` that validates and brands at parse time. Resolvers therefore receive **pre-validated branded args** — never call `Primitive(value)` inside a resolver. Invalid input becomes a `BAD_USER_INPUT` error before the resolver runs. See [branded-types.md](./branded-types.md).

## Key Rules

1. **Validate at the scalar boundary** — branded scalars translate raw input into trusted domain types. Evans: Anti-Corruption Layer.
2. **Never re-validate inside the domain** — if it's branded, illegal states are already unrepresentable.
3. **Map outcomes with `match().exhaustive()`** — every command outcome maps to a value or a `GraphQLError`. Wlashin: Railway-Oriented Programming meets the transport.
4. **Nested fields go through loaders** — no collection scans, no per-row reads.
5. **Document everything** — every type, field, enum and argument gets a Pothos `description`.
6. **Domain-first changes** — GraphQL type changes must be reflected in `types.ts`/`primitives.ts` first; the domain is the source of truth. See [domain-guide.md](./domain-guide.md).
