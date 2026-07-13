# Branded Types + Zod

## Overview

We use [ts-brand](https://github.com/kourge/ts-brand) to create nominal types that prevent accidental mixing of semantically different values (e.g. `BeverageId` vs `UserId`, `Eur` vs `Year`), combined with [Zod](https://zod.dev/) for runtime validation.

This implements two DDD concepts: Evans' **Value Objects** (types defined by their value, immutable, no identity) and Wlashin's **making illegal states unrepresentable** (if a value exists as a branded type, it has already been validated — no downstream checks needed).

## Pattern

### 1. Define the branded type (`types.ts`)

```ts
import type { Brand } from 'ts-brand'

export type BeverageId = Brand<string, 'BeverageId'>
export type BeverageName = Brand<string, 'BeverageName'>
export type Celsius = Brand<number, 'Celsius'>
```

### 2. Create the Zod constructor (`primitives.ts`)

```ts
import { make } from 'ts-brand'
import { z } from 'zod'
import type { BeverageId as BeverageIdType } from '~/domain/beverage/types'

export const BeverageId = (value: unknown) => {
  const v = z.string().uuid().parse(value)
  return make<BeverageIdType>()(v)
}

// A convenience minting helper is fine when the domain generates ids itself:
export const randomBeverageId = () => BeverageId(crypto.randomUUID())
```

### 3. Use at domain boundaries

> **Evans:** the Anti-Corruption Layer in action — raw external data is validated and translated into domain types at the boundary, protecting the domain model from invalid state.

In this codebase the boundary is the **GraphQL custom scalar** — see below — so resolvers already receive branded values. You still call the constructor directly in migrations, tests, or any code that ingests raw data:

```ts
const id = BeverageId(rawValue) // validates + brands; id is now BeverageId, not string
```

## Branded types are primitives at runtime

The brand is **compile-time only**. `BeverageName` IS a `string`, `Celsius` IS a `number` at runtime — never wrap them with `String()` or `Number()`. A branded `Year` is directly assignable to `number` in arithmetic (that is how `business-rules.ts` does drink-window math on plain numbers).

## Union Types

String-literal unions are validated in `primitives.ts` too:

```ts
// types.ts
export type WineColor = 'red' | 'white' | 'rosé'

// primitives.ts
export const WineColor = (value: unknown) =>
  z.enum(['red', 'white', 'rosé']).parse(value) as WineColor
```

**Never use a bare `as MyType`** to coerce untrusted input — always parse through the Zod constructor. (The `as WineColor` above is applied to a value Zod just proved is one of the members.)

## Numeric Types with String Coercion

For values that may arrive as strings, preprocess before validating:

```ts
export const Celsius = (value: unknown) => {
  const v = z
    .preprocess((v) => (typeof v === 'string' ? Number(v) : v), z.number().min(-50).max(100))
    .parse(value)
  return make<CelsiusType>()(v)
}
```

## Every Brand Gets a GraphQL Scalar

Every branded type used in the schema has a matching custom scalar in `server/domain/shared/graphql/scalars.ts` and an entry in the `Scalars` map in `builder.ts`. The scalar validates and brands input at parse time, so resolvers receive **pre-validated branded args** and never call the constructor themselves. Invalid input becomes a `BAD_USER_INPUT` GraphQL error before the resolver runs:

```ts
builder.scalarType('BeverageId', {
  description: 'Beverage unique identifier (UUID v4)',
  serialize: (value) => value as string,
  parseValue: validatedParse('BeverageId', BeverageId),
})
```

When you add a new branded type, also update the Apollo iOS codegen scalar mapping under `ios/Vinarium/Generated/GraphQL/`. See [api-patterns.md](./api-patterns.md).

## Shared Types

Cross-domain branded types live in `server/domain/shared/types.ts`, with their constructors in `server/domain/shared/primitives.ts`:

- `UserId` — Firebase Auth user identifier
- `Eur` — Euro amount (non-negative)
- `Year` — calendar year (integer >= 1800)
- `Country`, `Region` — place names (non-empty strings)
- `PersonName`, `PlaceName` — names (1–200 chars)
- `Latitude`, `Longitude` — geographic coordinates
- `Percentage` — a percentage (0..100)
- `Count`, `Month` — reporting/aggregation values

Domain-scoped brands (e.g. `BeverageId`, `BeverageName`, `Producer`, `Celsius`, `Rating`) live in the domain that owns them.
