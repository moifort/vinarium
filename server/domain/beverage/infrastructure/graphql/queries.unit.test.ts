import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId

// The BeverageId scalar validates UUIDs — deterministic ones keep assertions readable.
const wid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

// No resolver on the tested paths reads the H3 event — only userId matters.
// A fresh loader set per execution mirrors the per-request context of the route.
const execute = (source: string) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const seedWine = (id: string, over: Record<string, unknown> = {}) =>
  fake.seed('beverages', id, {
    id,
    userId,
    name: `Beverage ${id}`,
    beverageType: 'wine',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...over,
  })

// Satellite collections key their single record per (user, wine) as `${userId}_${beverageId}`.
const seedSatellites = (beverageId: string) => {
  fake.seed('tasting', `${userId}_${beverageId}`, { userId, beverageId, rating: 4, favorite: true })
  fake.seed('gift', `${userId}_${beverageId}`, {
    userId,
    beverageId,
    given: { date: new Date('2026-02-01'), recipientName: 'Alice' },
  })
  fake.seed('recommendation', `${userId}_${beverageId}`, { userId, beverageId, comment: 'Superbe' })
  fake.seed('cellar', `${userId}_${beverageId}`, {
    userId,
    beverageId,
    row: 2,
    col: 3,
    createdAt: new Date('2026-01-15'),
    updatedAt: new Date('2026-01-15'),
  })
}

const detailQuery = (id: string) => `
  query {
    beverage(id: "${id}") {
      id
      name
      cellar { row col rowLabel colLabel }
      consumption { rating favorite }
      gift { given { recipientName } }
      recommendation { comment }
    }
  }
`

describe('wine(id) detail query', () => {
  test('resolves the wine with its satellites', async () => {
    seedWine(wid(1))
    seedSatellites(wid(1))

    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    expect(result.data?.beverage).toEqual({
      id: wid(1),
      name: `Beverage ${wid(1)}`,
      cellar: { row: 2, col: 3, rowLabel: 'C', colLabel: 4 },
      consumption: { rating: 4, favorite: true },
      gift: { given: { recipientName: 'Alice' } },
      recommendation: { comment: 'Superbe' },
    })
  })

  test('costs 5 keyed doc reads and never scans a collection', async () => {
    seedWine(wid(1))
    seedSatellites(wid(1))
    // A busy cellar: the read budget must not grow with collection sizes.
    for (let i = 2; i <= 20; i++) {
      seedWine(wid(i))
      seedSatellites(wid(i))
    }

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    // 1 wine + 4 satellites, each a keyed get on doc `${userId}_${beverageId}`.
    // The viewer owns the wine, so no household scope is resolved.
    expect(fake.docReads - before.docReads).toBe(5)
    expect(fake.queryReads - before.queryReads).toBe(0)
  })

  test('resolves absent satellites to null, at the same read budget', async () => {
    seedWine(wid(1))

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    expect(result.data?.beverage).toEqual({
      id: wid(1),
      name: `Beverage ${wid(1)}`,
      cellar: null,
      consumption: null,
      gift: null,
      recommendation: null,
    })
    // 1 wine + 4 satellite probes, all on the viewer's own docs.
    expect(fake.docReads - before.docReads).toBe(5)
    expect(fake.queryReads - before.queryReads).toBe(0)
  })

  test('returns null for a wine owned by another user', async () => {
    fake.seed('beverages', wid(1), {
      id: wid(1),
      userId: 'someone-else',
      name: `Beverage ${wid(1)}`,
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    expect(result.data?.beverage).toBeNull()
  })

  test('exposes a household member’s wine, flagged as not mine', async () => {
    // The viewer (user-1) shares a household with 'marie', who owns wid(1).
    fake.seed('household-members', userId, {
      userId,
      householdId: 'h1',
      displayName: 'Me',
      role: 'owner',
      joinedAt: new Date('2026-01-01'),
    })
    fake.seed('household-members', 'marie', {
      userId: 'marie',
      householdId: 'h1',
      displayName: 'Marie',
      role: 'member',
      joinedAt: new Date('2026-01-02'),
    })
    fake.seed('beverages', wid(1), {
      id: wid(1),
      userId: 'marie',
      name: `Beverage ${wid(1)}`,
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })
    // Marie's bottle lives under her own composed id — the loader must read her slot.
    fake.seed('cellar', `marie_${wid(1)}`, {
      userId: 'marie',
      beverageId: wid(1),
      row: 1,
      col: 2,
      createdAt: new Date('2026-01-15'),
      updatedAt: new Date('2026-01-15'),
    })

    const result = await execute(
      `query { beverage(id: "${wid(1)}") { id isMine cellar { row col } } }`,
    )

    expect(result.errors).toBeUndefined()
    expect(result.data?.beverage).toEqual({ id: wid(1), isMine: false, cellar: { row: 1, col: 2 } })
  })

  test('a stranger’s wine stays hidden even with a household', async () => {
    fake.seed('household-members', userId, {
      userId,
      householdId: 'h1',
      displayName: 'Me',
      role: 'owner',
      joinedAt: new Date('2026-01-01'),
    })
    fake.seed('beverages', wid(1), {
      id: wid(1),
      userId: 'stranger',
      name: `Beverage ${wid(1)}`,
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    const result = await execute(`query { beverage(id: "${wid(1)}") { id isMine } }`)

    expect(result.errors).toBeUndefined()
    expect(result.data?.beverage).toBeNull()
  })
})

describe('wines list query', () => {
  test('serves satellites through the batched loaders, without per-wine fallbacks', async () => {
    seedWine(wid(1))
    seedWine(wid(2))
    seedSatellites(wid(1))

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(`
      query {
        beverages(limit: 10) {
          items {
            id
            cellar { row col }
            consumption { rating }
            gift { given { recipientName } }
            recommendation { comment }
          }
        }
      }
    `)

    expect(result.errors).toBeUndefined()
    const items = (
      result.data?.beverages as { items: Array<{ id: string } & Record<string, unknown>> }
    ).items
    expect(items).toHaveLength(2)
    const byId = new Map(items.map((item) => [item.id, item]))
    expect(byId.get(wid(1))).toEqual({
      id: wid(1),
      cellar: { row: 2, col: 3 },
      consumption: { rating: 4 },
      gift: { given: { recipientName: 'Alice' } },
      recommendation: { comment: 'Superbe' },
    })
    expect(byId.get(wid(2))).toEqual({
      id: wid(2),
      cellar: null,
      consumption: null,
      gift: null,
      recommendation: null,
    })
    // Budget guard: 1 page query returning the full wine docs (never re-read),
    // plus one batched getAll of 2 refs per selected satellite collection. The
    // cellar loader reads each wine's own slot, so a household never fans out here.
    // If a loader ever stopped batching, per-wine fallbacks would double the reads.
    expect(fake.queryReads - before.queryReads).toBe(1)
    expect(fake.docReads - before.docReads).toBe(8)
  })

  test('history is batched: one journal query for the whole page, not one per wine', async () => {
    for (let i = 1; i <= 5; i++) {
      seedWine(wid(i))
      fake.seed('journal', `entry-${i}`, {
        userId,
        beverageId: wid(i),
        type: 'in',
        row: 0,
        col: i - 1,
        date: new Date('2026-03-01'),
      })
    }

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(`
      query {
        beverages(limit: 10) {
          items { id history { type position } }
        }
      }
    `)

    expect(result.errors).toBeUndefined()
    const items = (result.data?.beverages as { items: Array<{ history: unknown[] }> }).items
    expect(items).toHaveLength(5)
    for (const item of items) expect(item.history).toHaveLength(1)
    // 1 page query + 1 batched `in` query over the 5 wine ids — never 5 queries.
    expect(fake.queryReads - before.queryReads).toBe(2)
    expect(fake.docReads - before.docReads).toBe(0)
  })
})
