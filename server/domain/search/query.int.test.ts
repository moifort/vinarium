import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { SearchQuery } = await import('~/domain/search/query')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

const seed = () => {
  fake.seed('beverages', 'w1', {
    id: 'w1',
    userId,
    name: 'Château Margaux',
    beverageType: 'wine',
    producer: 'Château Margaux',
    region: 'Bordeaux',
    wine: { color: 'red', vintage: 2015 },
    createdAt: new Date('2026-01-03'),
    updatedAt: new Date('2026-01-03'),
  })
  fake.seed('beverages', 'w2', {
    id: 'w2',
    userId,
    name: 'Pouilly-Fumé',
    beverageType: 'wine',
    wine: { color: 'white', vintage: 2021 },
    createdAt: new Date('2026-01-02'),
    updatedAt: new Date('2026-01-02'),
  })
  fake.seed('beverages', 'w3', {
    id: 'w3',
    userId,
    name: 'Porto Vintage',
    beverageType: 'wine',
    subtype: 'porto',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  })
  fake.seed('cellar', `${userId}_w1`, {
    userId,
    beverageId: 'w1',
    row: 0,
    col: 0,
    createdAt: new Date('2026-01-03'),
    updatedAt: new Date('2026-01-03'),
  })
  fake.seed('tasting', `${userId}_w2`, {
    userId,
    beverageId: 'w2',
    favorite: true,
    consumedDate: new Date('2026-02-01'),
  })
  fake.seed('gift', `${userId}_w3`, {
    userId,
    beverageId: 'w3',
    received: { from: 'Alice Martin' },
    given: { date: new Date('2026-01-01'), recipientName: 'Bob Durand' },
  })
}

const run = (query: string, filters = {}, limit = 50) =>
  SearchQuery.acrossCollections(userId, { query, filters, limit })

describe('SearchQuery.acrossCollections', () => {
  test('matches wine name and attaches satellites', async () => {
    seed()
    const { hits, totalCount } = await run('margaux')
    expect(totalCount).toBe(1)
    expect(String(hits[0]?.item.id)).toBe('w1')
    expect(hits[0]?.matchedFields).toContain('name')
    // Cellar satellite attached, so the GraphQL resolver skips the fallback.
    expect(hits[0]?.item.cellar).not.toBeNull()
  })

  test('matches a person across gift satellites', async () => {
    seed()
    const byGiver = await run('alice')
    expect(byGiver.hits.map((hit) => String(hit.item.id))).toEqual(['w3'])
    expect(byGiver.hits[0]?.matchedFields).toContain('gifted-by')

    const byRecipient = await run('bob')
    expect(byRecipient.hits.map((hit) => String(hit.item.id))).toEqual(['w3'])
    expect(byRecipient.hits[0]?.matchedFields).toContain('gift-recipient')
  })

  test('matches subtype and numeric vintage', async () => {
    seed()
    expect((await run('porto')).hits.map((hit) => String(hit.item.id))).toEqual(['w3'])
    expect((await run('2015')).hits.map((hit) => String(hit.item.id))).toEqual(['w1'])
  })

  test('ranks by relevance', async () => {
    fake.seed('beverages', 'a', {
      id: 'a',
      userId,
      name: 'Château Margaux',
      beverageType: 'wine',
      createdAt: new Date('2026-01-02'),
      updatedAt: new Date('2026-01-02'),
    })
    fake.seed('beverages', 'b', {
      id: 'b',
      userId,
      name: 'Margaux',
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })
    const { hits } = await run('margaux')
    expect(hits.map((hit) => String(hit.item.id))).toEqual(['b', 'a'])
  })

  test('filters browse the collection when the query is empty', async () => {
    seed()
    const { hits } = await run('', { colors: ['white'] })
    expect(hits.map((hit) => String(hit.item.id))).toEqual(['w2'])
    expect(hits[0]?.matchedFields).toEqual([])
  })

  test('empty query without filters returns nothing', async () => {
    seed()
    const { hits, totalCount } = await run('')
    expect(hits).toEqual([])
    expect(totalCount).toBe(0)
  })

  test('limit caps hits but totalCount stays full', async () => {
    seed()
    const { hits, totalCount } = await run('', { status: 'all', colors: ['red', 'white'] }, 1)
    expect(hits).toHaveLength(1)
    expect(totalCount).toBe(2)
  })

  test('reads each collection once (5 scans, no per-wine fallback)', async () => {
    seed()
    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    await run('margaux')
    // Five collection scans: beverages, cellar, tasting, gift, recommendation.
    expect(fake.queryReads - before.queryReads).toBe(5)
    // Plus the memoized household-scope probe: one bounded membership doc get,
    // shared by allVisibleTo and householdPlacements within the request.
    expect(fake.docReads - before.docReads).toBe(1)
  })
})

describe('SearchQuery.acrossCollections — household visibility', () => {
  const householdMember = (id: string) => ({
    userId: id,
    householdId: 'h1',
    displayName: id,
    role: id === userId ? 'owner' : 'member',
    joinedAt: new Date('2026-01-01'),
  })

  // The viewer shares a household with 'marie'. Her m-in wine is in the shared
  // cellar; her m-out wine is not; she has a gift record naming a person.
  const seedHousehold = () => {
    fake.seed('household-members', userId, householdMember(userId))
    fake.seed('household-members', 'marie', householdMember('marie'))
    fake.seed('beverages', 'm-in', {
      id: 'm-in',
      userId: 'marie',
      name: 'Clos Marie',
      beverageType: 'wine',
      createdAt: new Date('2026-01-02'),
      updatedAt: new Date('2026-01-02'),
    })
    fake.seed('beverages', 'm-out', {
      id: 'm-out',
      userId: 'marie',
      name: 'Clos Cachet',
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })
    fake.seed('cellar', 'marie_m-in', { userId: 'marie', beverageId: 'm-in', row: 0, col: 0 })
    fake.seed('gift', 'marie_m-in', {
      userId: 'marie',
      beverageId: 'm-in',
      received: { from: 'Sofia Rossi' },
    })
  }

  test('finds a housemate’s in-cellar wine but not their out-of-cellar one', async () => {
    seedHousehold()
    expect((await run('clos')).hits.map((hit) => String(hit.item.id))).toEqual(['m-in'])
  })

  test('a housemate’s own gift/journal never produces a person match', async () => {
    seedHousehold()
    // 'Sofia' only appears in Marie's private gift record — off-limits to the viewer.
    expect((await run('sofia')).hits).toEqual([])
  })
})
