import { beforeEach, describe, expect, test } from 'bun:test'
import { createFakeFirestore, type FakeFirestore } from '~/test/fake-firestore'
import { migration0004 } from './0004-wine-sub-objects'

let fake: FakeFirestore

beforeEach(() => {
  fake = createFakeFirestore()
})

describe('migration 0004 wine-sub-objects', () => {
  test('groups the flat purchase / drink-window / place fields and drops them', async () => {
    fake.seed('wines', 'w1', {
      name: 'Margaux',
      beverageType: 'wine',
      purchasePrice: 42,
      purchaseDate: '2024-05-01',
      drinkFrom: 2028,
      drinkUntil: 2035,
      latitude: 44.8,
      longitude: -0.6,
      placeName: 'Caviste Bordeaux',
    })

    const result = await migration0004.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 1 })
    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Margaux',
      beverageType: 'wine',
      purchase: { price: 42, date: '2024-05-01' },
      drinkWindow: { from: 2028, until: 2035 },
      place: { latitude: 44.8, longitude: -0.6, name: 'Caviste Bordeaux' },
    })
  })

  test('creates a sub-object from a single set field and omits absent ones', async () => {
    fake.seed('wines', 'w1', { name: 'Chinon', beverageType: 'wine', drinkUntil: 2030 })

    await migration0004.migrate({ db: fake.db })

    expect(fake.snapshot('wines').get('w1')).toEqual({
      name: 'Chinon',
      beverageType: 'wine',
      drinkWindow: { until: 2030 },
    })
  })

  test('leaves already-migrated documents untouched', async () => {
    fake.seed('wines', 'w1', {
      name: 'Chouffe',
      beverageType: 'beer',
      purchase: { price: 3 },
    })

    const result = await migration0004.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 0 })
    expect(fake.batches).toHaveLength(0)
  })

  test('splits writes beyond the Firestore 500-op limit', async () => {
    for (let i = 0; i < 501; i++) {
      fake.seed('wines', `w${i}`, { name: `Beverage ${i}`, beverageType: 'wine', drinkFrom: 2030 })
    }

    const result = await migration0004.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 501 })
    expect(fake.batches).toHaveLength(2)
    expect(fake.batches.every((batch) => batch.ops.length <= 500)).toBe(true)
  })
})
