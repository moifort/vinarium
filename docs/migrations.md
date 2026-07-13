# Migration System

## Overview

Forward-only sequential migrations for the Firestore database. The current version is tracked in the Firestore collection `migration-meta`, document `state`. Migrations are **not** run at boot — there is no boot-time plugin. They run only when `POST /admin/migrate` is called, which `scripts/bootstrap.sh` invokes during provisioning (and CI invokes on deploy).

## When to Migrate

**Migration needed:**
- Renaming a field
- Changing a field's structure (e.g. flattening `giftedBy` into a nested `gift.received` object)
- Changing enum values
- Removing stale data

**No migration needed:**
- Adding a new optional (`?`) field
- Adding a new Firestore collection
- Changing query logic or resolvers

## Creating a Migration

### 1. Create the migration file

`server/system/migration/migrations/NNNN-name.ts`:

```ts
import type { DocumentReference } from 'firebase-admin/firestore'
import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

export const migration0007: Migration = {
  version: MigrationVersion(7),
  name: MigrationName('rename-foo-to-bar'),
  migrate: async ({ db }) => {
    const snap = await db.collection('beverages').get()

    const writes: { ref: DocumentReference; data: Record<string, unknown> }[] = []
    for (const doc of snap.docs) {
      const data = doc.data()
      if (!('foo' in data)) continue
      const { foo, ...rest } = data
      writes.push({ ref: doc.ref, data: { ...rest, bar: foo } })
    }

    // Firestore caps a batch at 500 operations.
    for (let start = 0; start < writes.length; start += 500) {
      const batch = db.batch()
      for (const { ref, data } of writes.slice(start, start + 500)) batch.set(ref, data)
      await batch.commit()
    }
    return { ok: true, transformed: writes.length }
  },
}
```

The `migrate` function receives a `MigrationContext` — currently just `{ db }`, the `firebase-admin` `Firestore` instance. It returns a `MigrationResult`:

```ts
type MigrationResult = { ok: true; transformed: number } | { ok: false; error: string }
```

### 2. Register in `migrations/index.ts`

```ts
import type { Migration } from '~/system/migration/types'
import { migration0001 } from './0001-backfill-beverage-type'
// … existing imports …
import { migration0007 } from './0007-rename-foo-to-bar'

export const migrations: Migration[] = [
  migration0001,
  // … existing entries …
  migration0007,
]
```

## How It Works

`server/system/migration/runner.ts`:

1. `POST /admin/migrate` calls `runMigrations(migrations)`.
2. The runner reads `migration-meta/state` to get the current version (defaulting to `MigrationVersion(0)` when absent).
3. Pending migrations (version > current) are sorted by version and applied sequentially.
4. Each migration receives a `MigrationContext` with the Firestore `db`.
5. On success, `migration-meta/state` is updated with the new version and `appliedAt`.
6. On the first failure the runner stops and returns `{ outcome: 'failed', version, error }`; the route sets HTTP 500 so the CI deploy step fails (`curl -fsS` gates on the status).

The runner wraps each migration in try/catch — **migrations don't need their own error handling**. A throw inside `migrate` is caught and reported as a failed outcome.

## Testing a Migration

Co-locate an integration test `NNNN-name.int.test.ts` next to the migration. Mock Firestore with the in-memory fake, seed the pre-migration documents, run `migrate`, then assert the transformed shape:

```ts
import { expect, mock, test } from 'bun:test'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))
const { migration0007 } = await import('./0007-rename-foo-to-bar')

test('renames foo to bar', async () => {
  const fake = resetFakeFirestore()
  fake.seed('beverages', 'b1', { id: 'b1', foo: 42 })

  const result = await migration0007.migrate({ db: fake.db })

  expect(result).toEqual({ ok: true, transformed: 1 })
  expect(fake.snapshot('beverages').get('b1')).toEqual({ id: 'b1', bar: 42 })
})
```

## Rules

- Migration `version` uses branded `MigrationVersion` (starts at 1; version 0 is the reserved sentinel for "no migrations applied yet").
- Migrations are forward-only — there is no rollback mechanism.
- Never run migrations locally against production data; they run through `POST /admin/migrate` during provisioning/deploy.
- Firestore rejects `undefined` values — when restructuring a document, only copy fields that are actually present (`if (value != null) …`).
