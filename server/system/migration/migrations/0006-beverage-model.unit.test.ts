import { beforeEach, describe, expect, test } from 'bun:test'
import { createFakeFirestore, type FakeFirestore } from '~/test/fake-firestore'
import { migration0006 } from './0006-beverage-model'

let fake: FakeFirestore

beforeEach(() => {
  fake = createFakeFirestore()
})

describe('migration 0006 beverage-model', () => {
  test('moves a wine into beverages with its wine-only fields nested and domain renamed', async () => {
    fake.seed('wines', 'w1', {
      id: 'w1',
      userId: 'u1',
      name: 'Margaux',
      beverageType: 'wine',
      domain: 'Château Margaux',
      region: 'Bordeaux',
      color: 'red',
      vintage: 2015,
      grapeVarieties: ['Merlot'],
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    await migration0006.migrate({ db: fake.db })

    expect(fake.snapshot('wines').size).toBe(0)
    expect(fake.snapshot('beverages').get('w1')).toEqual({
      id: 'w1',
      userId: 'u1',
      name: 'Margaux',
      beverageType: 'wine',
      producer: 'Château Margaux',
      region: 'Bordeaux',
      wine: { color: 'red', vintage: 2015, grapeVarieties: ['Merlot'] },
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })
  })

  test('moves a non-wine without attaching a wine sub-object', async () => {
    fake.seed('wines', 'b1', {
      id: 'b1',
      userId: 'u1',
      name: 'Chouffe',
      beverageType: 'beer',
      subtype: 'blonde',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    await migration0006.migrate({ db: fake.db })

    const saved = fake.snapshot('beverages').get('b1')
    expect(saved).not.toHaveProperty('wine')
    expect(saved).toMatchObject({ beverageType: 'beer', subtype: 'blonde' })
  })

  test('renames the wineId field to beverageId in every satellite collection', async () => {
    fake.seed('cellar', 'u1_w1', { userId: 'u1', wineId: 'w1', row: 0, col: 0 })
    fake.seed('tasting', 'u1_w1', { userId: 'u1', wineId: 'w1', favorite: true })
    fake.seed('gift', 'u1_w1', { userId: 'u1', wineId: 'w1', received: { from: 'Alice' } })
    fake.seed('recommendation', 'u1_w1', { userId: 'u1', wineId: 'w1', comment: 'Top' })
    fake.seed('journal', 'j1', { userId: 'u1', wineId: 'w1', type: 'in', row: 0, col: 0 })

    await migration0006.migrate({ db: fake.db })

    for (const collection of ['cellar', 'tasting', 'gift', 'recommendation'] as const) {
      const doc = fake.snapshot(collection).get('u1_w1')
      expect(doc).not.toHaveProperty('wineId')
      expect(doc).toMatchObject({ beverageId: 'w1' })
    }
    const entry = fake.snapshot('journal').get('j1')
    expect(entry).not.toHaveProperty('wineId')
    expect(entry).toMatchObject({ beverageId: 'w1' })
  })

  test('reports the number of transformed documents', async () => {
    fake.seed('wines', 'w1', { id: 'w1', userId: 'u1', name: 'Margaux', beverageType: 'wine' })
    fake.seed('tasting', 'u1_w1', { userId: 'u1', wineId: 'w1', favorite: true })

    const result = await migration0006.migrate({ db: fake.db })

    expect(result).toEqual({ ok: true, transformed: 2 })
  })
})
