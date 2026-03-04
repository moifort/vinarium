import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import { runMigrations } from '~/system/migration/runner'
import type {
  Migration,
  MigrationMeta,
  MigrationName,
  MigrationVersion,
} from '~/system/migration/types'

const migration = (
  version: number,
  result: { ok: true; transformed: number } | { ok: false; error: string },
): Migration => ({
  version: make<MigrationVersion>()(version),
  name: make<MigrationName>()(`test-migration-${version}`),
  migrate: async () => result,
})

const throwingMigration = (version: number): Migration => ({
  version: make<MigrationVersion>()(version),
  name: make<MigrationName>()(`throwing-migration-${version}`),
  migrate: async () => {
    throw new Error('Migration exploded')
  },
})

describe('runMigrations', () => {
  test('no pending migrations returns up-to-date', async () => {
    const result = await runMigrations([])
    expect(result.outcome).toBe('up-to-date')
  })

  test('applies migrations in version order', async () => {
    const applied: number[] = []
    const migrations: Migration[] = [
      {
        version: make<MigrationVersion>()(2),
        name: make<MigrationName>()('second'),
        migrate: async () => {
          applied.push(2)
          return { ok: true, transformed: 0 }
        },
      },
      {
        version: make<MigrationVersion>()(1),
        name: make<MigrationName>()('first'),
        migrate: async () => {
          applied.push(1)
          return { ok: true, transformed: 0 }
        },
      },
    ]

    const result = await runMigrations(migrations)
    expect(result.outcome).toBe('migrated')
    expect(applied).toEqual([1, 2])
    if (result.outcome === 'migrated') {
      expect(result.from as number).toBe(0)
      expect(result.to as number).toBe(2)
      expect(result.applied).toBe(2)
    }
  })

  test('stops and returns failed when migration fails', async () => {
    const migrations = [
      migration(1, { ok: true, transformed: 5 }),
      migration(2, { ok: false, error: 'bad data' }),
      migration(3, { ok: true, transformed: 0 }),
    ]

    const result = await runMigrations(migrations)
    expect(result.outcome).toBe('failed')
    if (result.outcome === 'failed') {
      expect(result.version as number).toBe(2)
      expect(result.error).toBe('bad data')
    }
  })

  test('catches exceptions and returns failed', async () => {
    const migrations = [throwingMigration(1)]

    const result = await runMigrations(migrations)
    expect(result.outcome).toBe('failed')
    if (result.outcome === 'failed') {
      expect(result.error).toBe('Migration exploded')
    }
  })

  test('updates meta state after each migration', async () => {
    const migrations = [
      migration(1, { ok: true, transformed: 1 }),
      migration(2, { ok: true, transformed: 2 }),
    ]

    await runMigrations(migrations)

    const meta = await useStorage('migration-meta').getItem<MigrationMeta>('state')
    expect(meta).not.toBeNull()
    expect(meta?.version as number).toBe(2)
  })

  test('skips already applied migrations', async () => {
    // Pre-seed meta to version 1
    await useStorage('migration-meta').setItem<MigrationMeta>('state', {
      version: make<MigrationVersion>()(1),
      appliedAt: new Date(),
    })

    const applied: number[] = []
    const migrations: Migration[] = [
      {
        version: make<MigrationVersion>()(1),
        name: make<MigrationName>()('already-done'),
        migrate: async () => {
          applied.push(1)
          return { ok: true, transformed: 0 }
        },
      },
      {
        version: make<MigrationVersion>()(2),
        name: make<MigrationName>()('new-one'),
        migrate: async () => {
          applied.push(2)
          return { ok: true, transformed: 0 }
        },
      },
    ]

    const result = await runMigrations(migrations)
    expect(result.outcome).toBe('migrated')
    expect(applied).toEqual([2])
  })
})
