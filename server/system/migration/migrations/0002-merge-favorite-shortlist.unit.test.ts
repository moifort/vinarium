import { beforeEach, describe, expect, test } from 'bun:test'
import { createFakeFirestore, type FakeFirestore } from '~/test/fake-firestore'
import { migration0002 } from './0002-merge-favorite-shortlist'

let fake: FakeFirestore

beforeEach(() => {
  fake = createFakeFirestore()
})

describe('migration 0002 merge-favorite-shortlist', () => {
  test('turns 5-star tastings into favorites and drops the shortlist field', async () => {
    fake.seed('tasting', 'u_w1', { userId: 'u', wineId: 'w1', rating: 5 })
    fake.seed('tasting', 'u_w2', { userId: 'u', wineId: 'w2', rating: 3, shortlist: true })
    fake.seed('tasting', 'u_w3', { userId: 'u', wineId: 'w3', rating: 3, shortlist: false })

    const result = await migration0002.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 3 })
    expect(fake.snapshot('tasting').get('u_w1')).toEqual({
      userId: 'u',
      wineId: 'w1',
      rating: 5,
      favorite: true,
    })
    expect(fake.snapshot('tasting').get('u_w2')).toEqual({
      userId: 'u',
      wineId: 'w2',
      rating: 3,
      favorite: true,
    })
    // shortlist:false with a non-favorite rating: field dropped, no favorite added
    expect(fake.snapshot('tasting').get('u_w3')).toEqual({
      userId: 'u',
      wineId: 'w3',
      rating: 3,
    })
  })

  test('leaves untouched tastings that are neither 5-star nor shortlisted', async () => {
    fake.seed('tasting', 'u_w1', { userId: 'u', wineId: 'w1', rating: 4 })

    const result = await migration0002.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 0 })
    expect(fake.snapshot('tasting').get('u_w1')).toEqual({
      userId: 'u',
      wineId: 'w1',
      rating: 4,
    })
  })

  test('writes updates in a single committed batch', async () => {
    fake.seed('tasting', 'u_w1', { userId: 'u', wineId: 'w1', rating: 5 })
    fake.seed('tasting', 'u_w2', { userId: 'u', wineId: 'w2', shortlist: true })

    await migration0002.migrate({ db: fake.db })

    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.directWrites).toEqual([])
  })

  test('transforms nothing when the collection is empty', async () => {
    const result = await migration0002.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 0 })
  })

  test('splits writes into several batches beyond the Firestore 500-op limit', async () => {
    for (let i = 0; i < 501; i++) {
      fake.seed('tasting', `u_w${i}`, { userId: 'u', wineId: `w${i}`, rating: 5 })
    }

    const result = await migration0002.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 501 })
    expect(fake.batches).toHaveLength(2)
    expect(fake.batches.every((batch) => batch.ops.length <= 500)).toBe(true)
  })
})
