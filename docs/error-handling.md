# Error Handling

## Principle

We use **string-literal outcomes** (a lightweight discriminated union) instead of exceptions for domain-level errors. Exceptions are reserved for truly unexpected failures.

This implements Wlashin's **Railway-Oriented Programming**: each command returns a union where every expected outcome is an explicit track. The caller (a GraphQL resolver) must handle all tracks via `match().exhaustive()`, making error handling visible and compiler-enforced.

## Result Philosophy

Outcomes are **rare and business-oriented**. Use them only when the domain has multiple legitimate outcomes the caller must handle. Most queries simply return the data or `'not-found'`.

**Outcomes are bare string literals** — `'not-found'`, `'color-required'`, `'subtype-invalid'`. Never error objects, never nested structures. On success a command returns the domain value directly (or `undefined` when there is nothing to return, e.g. a delete). This makes the success/failure split a `typeof result === 'string'` check.

```ts
return 'not-found' as const              // expected failure, no payload
return await repository.save(beverage)   // success — the Beverage itself
return undefined                          // success with nothing to return (remove)
```

## Pattern

### Domain Commands Return String-Literal Outcomes

```ts
export namespace BeverageCommand {
  export const add = async (
    userId: UserId,
    name: BeverageName,
    beverageType: BeverageType,
    data: BeverageData,
  ) => {
    if (requiresColor(beverageType) && !data.wine?.color) return 'color-required' as const
    if (data.subtype && !subtypeAllowed(beverageType, data.subtype)) return 'subtype-invalid' as const
    // … assemble …
    return await repository.save(beverage) // returns the Beverage
  }

  export const remove = async (userId: UserId, id: BeverageId, batch?: WriteBatch) => {
    const existing = await repository.findBy(userId, id)
    if (!existing) return 'not-found' as const
    await repository.remove(id, batch)
    return undefined
  }
}
```

Key points:
- Always use `as const` on literal returns for type narrowing.
- Each failure is a distinct string discriminant.
- No exceptions thrown for expected failures.

### GraphQL Resolvers Map Outcomes to Errors

Resolvers use `match().exhaustive()` from `ts-pattern` and the `never`-returning helpers from `server/domain/shared/graphql/errors.ts` (`notFound`, `badUserInput`, `domainError`). The success arm matches "not a string" and returns the domain value:

```ts
import { match, P } from 'ts-pattern'
import { badUserInput, notFound } from '~/domain/shared/graphql/errors'

builder.mutationField('updateBeverage', (t) =>
  t.field({
    type: BeverageType,
    args: { /* … */ },
    resolve: async (_root, { id, input }, { userId }) => {
      const result = await BeverageUseCase.update(userId, id, toData(input))
      return match(result)
        .with('not-found', () => notFound('Beverage not found'))
        .with('color-required', () => badUserInput('A wine requires a color'))
        .with('subtype-invalid', () => badUserInput('This subtype does not fit the beverage type'))
        .with(P.not(P.string), (beverage) => beverage)
        .exhaustive()
    },
  }),
)
```

The error helpers throw a `GraphQLError` with an `extensions.code`:

```ts
export const domainError = (code: string, message: string): never => {
  throw new GraphQLError(message, { extensions: { code } })
}
export const notFound = (message: string): never => domainError('NOT_FOUND', message)
export const badUserInput = (message: string): never => domainError('BAD_USER_INPUT', message)
```

Their `never` return type lets them sit in `match()` arms while the success arm keeps the resolver's inferred type.

### Always Use `match().exhaustive()`

**Never use `switch`.** `.exhaustive()` forces every outcome to be handled — adding a new outcome to a command becomes a compile error in every resolver, not a silent bug.

> **Wlashin:** totality — every possible case must be handled. The compiler guarantees no outcome is silently ignored.

## Error Handling Levels

1. **Domain layer** — Returns string-literal outcomes for expected business failures (no try/catch). Throws for impossible states (data that should exist but doesn't).
2. **GraphQL layer** — Maps outcomes to `GraphQLError`s via `match().exhaustive()` and the shared error helpers.
3. **Framework layer** — Apollo/Nitro/Sentry catch thrown errors → a `500`-class GraphQL error + Sentry alert. The migration runner catches migration throws and reports them as failed outcomes.

## Throw for Impossible States

If a piece of data should exist (referenced by another domain, the result of a previous flow) and it doesn't — that's a bug, an incoherent state. **Throw immediately**, don't return an outcome.

```ts
// Bad — treating an impossible state as a business outcome
const tasting = await TastingQuery.byId(userId, tastingId)
if (tasting === 'not-found') return 'not-found' as const

// Good — this tasting was just referenced, it must exist
const tasting = await TastingQuery.byId(userId, tastingId)
if (tasting === 'not-found') throw new Error(`Tasting ${tastingId} not found — incoherent state`)
```

**Rule of thumb:** if the caller can't meaningfully recover from the absence, it's an impossible state → throw. If the absence is a normal scenario the user triggered (deleting a beverage that may not exist) → return `'not-found'`.

## Zod / Scalar Validation Errors

Invalid input never reaches a command: every branded GraphQL scalar validates and brands its value at parse time (`server/domain/shared/graphql/scalars.ts`). A malformed value throws a `GraphQLError` with `extensions.code: 'BAD_USER_INPUT'` before the resolver runs, so resolvers receive pre-validated branded args and never call `Primitive(value)` themselves.
