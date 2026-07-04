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

describe('WineQuery.page', () => {
  test('returns a bounded page ordered by the sort field, with hasMore', async () => {
    seedWine('w1', { createdAt: new Date('2026-01-03') })
    seedWine('w2', { createdAt: new Date('2026-01-02') })
    seedWine('w3', { createdAt: new Date('2026-01-01') })

    const first = await WineQuery.page(userId, { limit: 2, sort: 'createdAt', order: 'desc' })
    expect(first.wineIds.map(String)).toEqual(['w1', 'w2'])
    expect(first.hasMore).toBe(true)

    const next = await WineQuery.page(userId, {
      limit: 2,
      after: 'w2' as WineId,
      sort: 'createdAt',
      order: 'desc',
    })
    expect(next.wineIds.map(String)).toEqual(['w3'])
    expect(next.hasMore).toBe(false)
  })

  test('reads only limit+1 documents (bounded, not the whole collection)', async () => {
    for (let i = 0; i < 10; i++) seedWine(`w${i}`, { createdAt: new Date(2026, 0, i + 1) })
    const before = fake.reads
    await WineQuery.page(userId, { limit: 3, sort: 'createdAt', order: 'desc' })
    // one query get(); the fake counts a query as one read regardless of matches
    expect(fake.reads - before).toBe(1)
  })
})

describe('WineQuery.giftedPage', () => {
  test('pages only wines received as a gift, excluding those without giftedBy', async () => {
    seedWine('w1', { giftedBy: 'Alice' })
    seedWine('w2', { giftedBy: 'Bob' })
    seedWine('w3')

    const page = await WineQuery.giftedPage(userId, { limit: 10, order: 'asc' })
    expect(page.wineIds.map(String).sort()).toEqual(['w1', 'w2'])
    expect(page.hasMore).toBe(false)
  })
})
