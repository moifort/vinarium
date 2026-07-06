import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'
import type { WineId } from './types'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { WineQuery } = await import('./query')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const seedWine = (id: string, over: Record<string, unknown> = {}) =>
  fake.seed('wines', id, {
    id,
    userId,
    name: id,
    beverageType: 'wine',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...over,
  })

const defaults = { mode: 'all', status: 'all', sort: 'createdAt', order: 'desc' } as const

describe('WineQuery.list — paginated default view', () => {
  test('returns a bounded page of full wines ordered by the sort field, with hasMore', async () => {
    seedWine('w1', { createdAt: new Date('2026-01-03') })
    seedWine('w2', { createdAt: new Date('2026-01-02') })
    seedWine('w3', { createdAt: new Date('2026-01-01') })

    const first = await WineQuery.list(userId, { ...defaults, limit: 2 })
    expect(first.items.map(({ id }) => String(id))).toEqual(['w1', 'w2'])
    expect(first.hasMore).toBe(true)

    const next = await WineQuery.list(userId, { ...defaults, limit: 2, after: 'w2' as WineId })
    expect(next.items.map(({ id }) => String(id))).toEqual(['w3'])
    expect(next.hasMore).toBe(false)
  })

  test('reads only limit+1 documents (bounded, not the whole collection)', async () => {
    for (let i = 0; i < 10; i++) seedWine(`w${i}`, { createdAt: new Date(2026, 0, i + 1) })
    const before = fake.reads
    await WineQuery.list(userId, { ...defaults, limit: 3 })
    // one query get(); the fake counts a query as one read regardless of matches
    expect(fake.reads - before).toBe(1)
  })
})

describe('WineQuery.list — filtered views', () => {
  test('facet filters match on the wine documents alone (no satellite reads)', async () => {
    seedWine('w1', { color: 'red' })
    seedWine('w2', { color: 'white' })
    seedWine('w3', { color: 'red' })

    const before = fake.reads
    const result = await WineQuery.list(userId, { ...defaults, limit: 40, color: 'red' })

    expect(result.items.map(({ id }) => String(id)).toSorted()).toEqual(['w1', 'w3'])
    expect(result.hasMore).toBe(false)
    expect(result.totalCount).toBe(2)
    // A pure facet view costs the single memoized wines scan — nothing else.
    expect(fake.reads - before).toBe(1)
  })

  test('the in-cellar status adds exactly one cellar scan', async () => {
    seedWine('w1')
    seedWine('w2')
    fake.seed('cellar', `${userId}_w1`, { userId, wineId: 'w1', row: 0, col: 0 })

    const before = fake.reads
    const result = await WineQuery.list(userId, { ...defaults, limit: 40, status: 'in-cellar' })

    expect(result.items.map(({ id }) => String(id))).toEqual(['w1'])
    expect(fake.reads - before).toBe(2) // wines scan + cellar scan
  })

  test('the favorites mode adds exactly one tasting scan', async () => {
    seedWine('w1')
    seedWine('w2')
    fake.seed('tasting', `${userId}_w2`, { userId, wineId: 'w2', favorite: true })

    const before = fake.reads
    const result = await WineQuery.list(userId, {
      ...defaults,
      limit: 40,
      mode: 'favorites',
    })

    expect(result.items.map(({ id }) => String(id))).toEqual(['w2'])
    expect(fake.reads - before).toBe(2) // wines scan + tasting scan
  })
})
