import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'
import type { BeverageId } from './types'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { BeverageQuery } = await import('./query')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const seedWine = (id: string, over: Record<string, unknown> = {}) =>
  fake.seed('beverages', id, {
    id,
    userId,
    name: id,
    beverageType: 'wine',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...over,
  })

const defaults = { mode: 'all', status: 'all', sort: 'createdAt', order: 'desc' } as const

describe('BeverageQuery.list — paginated default view', () => {
  test('returns a bounded page of full wines ordered by the sort field, with hasMore', async () => {
    seedWine('w1', { createdAt: new Date('2026-01-03') })
    seedWine('w2', { createdAt: new Date('2026-01-02') })
    seedWine('w3', { createdAt: new Date('2026-01-01') })

    const first = await BeverageQuery.list(userId, { ...defaults, limit: 2 })
    expect(first.items.map(({ id }) => String(id))).toEqual(['w1', 'w2'])
    expect(first.hasMore).toBe(true)

    const next = await BeverageQuery.list(userId, {
      ...defaults,
      limit: 2,
      after: 'w2' as BeverageId,
    })
    expect(next.items.map(({ id }) => String(id))).toEqual(['w3'])
    expect(next.hasMore).toBe(false)
  })

  test('reads only limit+1 documents (bounded, not the whole collection)', async () => {
    for (let i = 0; i < 10; i++) seedWine(`w${i}`, { createdAt: new Date(2026, 0, i + 1) })
    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    await BeverageQuery.list(userId, { ...defaults, limit: 3 })
    // one query get(); the fake counts a query as one read regardless of matches
    expect(fake.queryReads - before.queryReads).toBe(1)
    expect(fake.docReads - before.docReads).toBe(0)
  })
})

describe('BeverageQuery.list — filtered views', () => {
  test('facet filters match on the wine documents alone (no satellite reads)', async () => {
    seedWine('w1', { wine: { color: 'red' } })
    seedWine('w2', { wine: { color: 'white' } })
    seedWine('w3', { wine: { color: 'red' } })

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40, color: 'red' })

    expect(result.items.map(({ id }) => String(id)).toSorted()).toEqual(['w1', 'w3'])
    expect(result.hasMore).toBe(false)
    expect(result.totalCount).toBe(2)
    // A pure facet view costs the single memoized wines scan — nothing else.
    expect(fake.queryReads - before.queryReads).toBe(1)
    expect(fake.docReads - before.docReads).toBe(0)
  })

  test('the in-cellar status adds exactly one cellar scan', async () => {
    seedWine('w1')
    seedWine('w2')
    fake.seed('cellar', `${userId}_w1`, { userId, beverageId: 'w1', row: 0, col: 0 })

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40, status: 'in-cellar' })

    expect(result.items.map(({ id }) => String(id))).toEqual(['w1'])
    expect(fake.queryReads - before.queryReads).toBe(2) // wines scan + cellar scan
    expect(fake.docReads - before.docReads).toBe(0)
  })

  test('the favorites mode adds exactly one tasting scan', async () => {
    seedWine('w1')
    seedWine('w2')
    fake.seed('tasting', `${userId}_w2`, { userId, beverageId: 'w2', favorite: true })

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await BeverageQuery.list(userId, {
      ...defaults,
      limit: 40,
      mode: 'favorites',
    })

    expect(result.items.map(({ id }) => String(id))).toEqual(['w2'])
    expect(fake.queryReads - before.queryReads).toBe(2) // wines scan + tasting scan
    expect(fake.docReads - before.docReads).toBe(0)
  })
})
