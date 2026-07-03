import { beforeEach, describe, expect, test } from 'bun:test'
import { createFakeFirestore, type FakeFirestore } from '~/test/fake-firestore'
import { migration0001 } from './0001-backfill-beverage-type'

let fake: FakeFirestore

beforeEach(() => {
  fake = createFakeFirestore()
})

describe('migration 0001 backfill-beverage-type', () => {
  test('sets beverageType to wine on documents missing it', async () => {
    fake.seed('wines', 'w1', { name: 'Margaux', color: 'red' })
    fake.seed('wines', 'w2', { name: 'Chouffe', beverageType: 'beer' })

    const result = await migration0001.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 1 })
    expect(fake.snapshot('wines').get('w1')?.beverageType).toBe('wine')
    expect(fake.snapshot('wines').get('w2')?.beverageType).toBe('beer')
  })

  test('preserves existing fields on transformed documents', async () => {
    fake.seed('wines', 'w1', { name: 'Margaux', color: 'red', vintage: 2015 })

    await migration0001.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Margaux',
      color: 'red',
      vintage: 2015,
      beverageType: 'wine',
    })
  })

  test('writes all updates in a single committed batch', async () => {
    fake.seed('wines', 'w1', { name: 'A' })
    fake.seed('wines', 'w2', { name: 'B' })

    const result = await migration0001.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 2 })
    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.directWrites).toEqual([])
  })

  test('transforms nothing when the collection is empty', async () => {
    const result = await migration0001.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 0 })
  })

  test('splits writes into several batches beyond the Firestore 500-op limit', async () => {
    for (let i = 0; i < 501; i++) {
      fake.seed('wines', `w${i}`, { name: `Wine ${i}` })
    }

    const result = await migration0001.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 501 })
    expect(fake.batches).toHaveLength(2)
    expect(fake.batches.every((batch) => batch.ops.length <= 500)).toBe(true)
    expect(fake.batches.every((batch) => batch.commits === 1)).toBe(true)
  })
})
