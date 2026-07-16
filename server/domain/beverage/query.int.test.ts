import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { HouseholdId, HouseholdMember } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
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
    // Plus the household-scope probe (a single membership doc get) — memoized in a
    // real request, so it stays one bounded read per request.
    expect(fake.docReads - before.docReads).toBe(1)
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
    // A pure facet view costs the single memoized wines scan, plus the
    // household-scope membership probe (one bounded doc get).
    expect(fake.queryReads - before.queryReads).toBe(1)
    expect(fake.docReads - before.docReads).toBe(1)
  })

  test('the in-cellar status adds exactly one cellar scan', async () => {
    seedWine('w1')
    seedWine('w2')
    fake.seed('cellar', `${userId}_w1`, { userId, beverageId: 'w1', row: 0, col: 0 })

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40, status: 'in-cellar' })

    expect(result.items.map(({ id }) => String(id))).toEqual(['w1'])
    expect(fake.queryReads - before.queryReads).toBe(2) // wines scan + cellar scan
    // Plus the memoized household-scope probe (one bounded membership doc get,
    // shared by allVisibleTo and householdPlacements within the request).
    expect(fake.docReads - before.docReads).toBe(1)
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
    // Plus the household-scope membership probe (one bounded doc get).
    expect(fake.docReads - before.docReads).toBe(1)
  })
})

describe('BeverageQuery.list — household visibility', () => {
  const householdMember = (id: string): HouseholdMember => ({
    userId: id as UserId,
    householdId: 'h1' as HouseholdId,
    displayName: id as PersonName,
    role: id === 'user-1' ? 'owner' : 'member',
    joinedAt: new Date('2026-01-01'),
  })

  const marieWine = (id: string, over: Record<string, unknown> = {}) =>
    fake.seed('beverages', id, {
      id,
      userId: 'marie',
      name: id,
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
      ...over,
    })

  // The viewer (user-1) and 'marie' share a household. Marie's m-in wine sits in
  // the shared cellar; her m-out wine does not. The viewer owns w1 (no bottle).
  const seedHousehold = () => {
    fake.seed('household-members', 'user-1', householdMember('user-1'))
    fake.seed('household-members', 'marie', householdMember('marie'))
    seedWine('w1', { createdAt: new Date('2026-01-03') })
    marieWine('m-in', { createdAt: new Date('2026-01-02') })
    marieWine('m-out', { createdAt: new Date('2026-01-01') })
    fake.seed('cellar', 'marie_m-in', { userId: 'marie', beverageId: 'm-in', row: 0, col: 0 })
  }

  test('the default view adds a housemate’s in-cellar wine but not their out-of-cellar one', async () => {
    seedHousehold()
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40 })
    expect(result.items.map(({ id }) => String(id))).toEqual(['w1', 'm-in'])
  })

  test('paginates the merged, sorted set by cursor', async () => {
    seedHousehold()
    seedWine('w0', { createdAt: new Date('2026-01-04') }) // a second owner wine
    // Three visible wines newest-first: w0 (01-04), w1 (01-03), m-in (marie, 01-02).
    const page1 = await BeverageQuery.list(userId, { ...defaults, limit: 2 })
    expect(page1.items.map(({ id }) => String(id))).toEqual(['w0', 'w1'])
    expect(page1.hasMore).toBe(true)

    const page2 = await BeverageQuery.list(userId, {
      ...defaults,
      limit: 2,
      after: 'w1' as BeverageId,
    })
    expect(page2.items.map(({ id }) => String(id))).toEqual(['m-in'])
    expect(page2.hasMore).toBe(false)
  })

  test('the in-cellar status shows a housemate’s placed wine even when the viewer has none', async () => {
    seedHousehold()
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40, status: 'in-cellar' })
    expect(result.items.map(({ id }) => String(id))).toEqual(['m-in'])
  })

  test('favorites hides a housemate’s wine the viewer has not favorited (even if she has)', async () => {
    seedHousehold()
    // Marie's own favorite must not leak her wine into the viewer's favorites.
    fake.seed('tasting', 'marie_m-in', { userId: 'marie', beverageId: 'm-in', favorite: true })
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40, mode: 'favorites' })
    expect(result.items).toHaveLength(0)
  })

  test('favorites includes a housemate’s in-cellar wine once the viewer favorites it', async () => {
    seedHousehold()
    fake.seed('tasting', `${userId}_m-in`, { userId, beverageId: 'm-in', favorite: true })
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40, mode: 'favorites' })
    expect(result.items.map(({ id }) => String(id))).toEqual(['m-in'])
  })

  test('the read budget stays bounded by the shared cellar, not the housemate’s library', async () => {
    seedHousehold()
    // 20 extra out-of-cellar wines for Marie: none may be fetched.
    for (let i = 0; i < 20; i++) marieWine(`m-extra-${i}`)

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await BeverageQuery.list(userId, { ...defaults, limit: 40 })

    // Still only the viewer's library plus Marie's single placed wine.
    expect(result.items.map(({ id }) => String(id))).toEqual(['w1', 'm-in'])
    // Three scans: the household members, the viewer's wines, the shared cellar.
    expect(fake.queryReads - before.queryReads).toBe(3)
    // One membership doc (memoized scope) + a getAll of exactly Marie's ONE placed
    // wine — never her 21-bottle shelf. This count is invariant to her library size.
    expect(fake.docReads - before.docReads).toBe(2)
  })
})
