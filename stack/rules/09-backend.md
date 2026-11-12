# Backend

A TypeScript backend on Bun and Nitro, Firebase preset, GraphQL through Apollo Server and Pothos,
native Firestore, Zod and branded types. Long form in the `domain` and `graphql` skills.

## Architecture

One folder per domain under `server/domain/{domain}/`: `types.ts`, `primitives.ts`,
`command.ts`, `query.ts`, optional
`business-rules.ts` (pure functions, full test coverage) and `use-case.ts` (orchestration across
domains, no business logic of its own), and `infrastructure/{repository.ts, graphql/}`.

- Commands change state, queries change nothing.
- `command.ts` and `query.ts` export bare functions, and the caller imports the module under
  the domain's name: `import * as BookCommand from '~/domain/book/command'`, then
  `BookCommand.rate(...)`. The prefix lives at the import site, so `BookCommand.rate` and
  `SeriesCommand.rate` never clash and no TypeScript `namespace` block is needed (an older
  construct the linter flags). Existing projects that use `namespace` move over through a
  migration of this package.
- The repository is bare exported functions (`import * as repository`), private to its domain. A
  domain that needs another goes through that domain's `Query` or `Command`, never its storage.
- A function's name carries the business concept, never the technical pattern: `versionToOpen`,
  not `computeVersion` or `handleX`. One concept, one word, at every layer: domain, schema, app,
  tests.
- Functional style: no class, no object interface. Polymorphism is a discriminated union on a
  literal field; on the API side a union, never an interface.

## Types

No bare primitive in a domain model: every field carries a branded type (`ts-brand`) with its
validating Zod constructor in `primitives.ts` and one GraphQL scalar per brand, which reuses the
constructor rather than restating the rule. Generic brands (user id, amount, year, percentage)
live in the shared domain. Dates stay native. Validation happens once, at the boundary, at
construction: the rest of the code works on valid values. Never `as MyType` on untrusted input.

No `null` in the domain: absence is an optional field, converted only at the API and storage
boundaries.

## Errors

A command returns the domain value or a bare string-literal outcome (`'not-found' as const`), one
distinct literal per expected failure. The resolver maps them exhaustively with
`match().exhaustive()` and the `notFound` / `badUserInput` helpers; a new outcome that is not
mapped fails to compile. `throw` only for an impossible state. If the caller can do nothing with
an absence, it is an inconsistent state, throw; if it is a normal scenario, return the outcome.

## Storage

Native Firestore through `db()`, only inside `infrastructure/repository.ts`, with the shared
helpers (converter, transactional read-modify-write, bulk save, delete in batches, per-request
memoisation).

- **Collections are flat.** Never a subcollection: every document sits in a top-level collection
  and names its owner in a `userId` field. Accounts live in `users/{userId}`. Every query filters
  on `userId`.
- A shared document (a catalogue two users converge on) holds no reference to any user and is
  keyed deterministically by what identifies it, so the paid call that produced it is paid once.
- **A field for a decided feature is added before production data exists.** Before the first
  release, adding a field costs nothing; after it, it costs a migration on every record. So a
  field a feature on the roadmap will need (a `hidden` flag for sharing planned next month) is
  added now with its default. Only for a decided feature: a field "in case" is dead weight to
  maintain in fixtures and to migrate away later.
- Renames, restructures and value changes go through a migration, see
  [11-ops.md](11-ops.md#migrations).
- Filtering, sorting and pagination happen in Firestore, never in memory after loading all.
- Multiple writes go through one batch; mass deletions through successive batches.

## Reads and cost

No nested field triggers one read per parent row. Either a per-request loader groups the reads by
parent id, or the data is denormalised on purpose (a book carries its series name and volume, so
sectioning a library reads no catalogue document). When a nested field needs the catalogue, add a
loader before shipping it. The only server-side cache is per incoming request: a domain query
called several times during one call reads once.

## Scheduled routes

A route called by Cloud Scheduler is **idempotent**: the scheduler retries on failure and a
replayed pass must neither pay a call twice nor notify twice. The route records what it did (a
document per pass or per item, keyed deterministically) and skips what is already done; a
notification carries an id that makes a second send a no-op. The route is protected by a token and
answers quickly, doing the work in bounded batches.

## Observability

Never `console.*`. One logger per component, `createLogger(tag)`. Three levels with a meaning:

| Level | Meaning | Goes to Sentry |
|---|---|---|
| `error` | Our code is broken or an invariant failed; someone must fix it | Yes |
| `warn` | Recovered, but a human should look one day (a fallback taken, a limit approached) | Yes |
| `info` | Expected, including expected failures: a third-party 503, an item a provider lacks, a cancelled request. Counted, never alerted | No |

A caught-and-recovered failure is logged at the level its meaning says, never swallowed. An
expected failure logged as `warn` creates a Sentry issue nobody can fix and trains the triage
routine to ignore warnings. Keep the message
constant and pass the rest apart (`logger.warn('cover lookup failed', { error, isbn13 })`), so
Sentry groups one problem into one issue and keeps the stack. Sentry activates only in a built
bundle with its DSN set, never in local development. The logger's extras appear under `.context`
in the event.

## Tests

Three suffixes, three CI workflows, co-located with the code:

| Suffix | Scope |
|---|---|
| `*.unit.test.ts` | Primitives and business rules, pure functions |
| `*.int.test.ts` | Commands and queries against the in-memory fake Firestore, through the real repository code: converters, date transposition, batches |
| `*.feat.test.ts` | The API contract through the built GraphQL schema: for each operation, the shape and values of its answer, its error codes, its gates, its read budget. A change in what an operation returns fails here before an app notices |

- Only `db()` is faked (`mock.module('~/system/firebase', () => ({ db: fakeDb }))`): the
  repository runs as in production, with its typed converters and its date handling, so a test
  proves the real storage code. The fake has no subcollections, matching the flat layout.
- Read budgets are asserted with the split counters `docReads` and `queryReads`, never the total.
- The per-request memoisation is active inside a test and reset between tests: reseeding between
  two calls of the same query in one test returns the stale result. Use two tests.
- Under Bun, `toMatchObject({ at: someDate })` matches any Date: assert a date with `toEqual` on
  the field.
- The three families run separately before a commit ([01-workflow.md](01-workflow.md)).

## Generated code

An exported schema, a typed client, a compiled asset belong to their generator: never edited by
hand, regenerated, committed when the repository needs them, excluded from the linter.

## Local development

A dev-only auth bypass (`DEV_USER_ID`) lets the schema explorer work without a token, and a
stub answers paid calls with a fixed result; both are `import.meta.dev` gated and tree-shaken out
of a production bundle. A dev server on real data runs real mutations. `.env.example` is updated
with every new variable, in the same commit.
