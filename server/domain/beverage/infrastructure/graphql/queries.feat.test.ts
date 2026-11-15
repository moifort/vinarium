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

  test('costs 5 keyed doc reads and no scan, however many gifts the user keeps', async () => {
    seedWine(wid(1))
    seedSatellites(wid(1))
    // A busy cellar: the doc-read budget must not grow with collection sizes.
    for (let i = 2; i <= 20; i++) {
      seedWine(wid(i))
      seedSatellites(wid(i))
    }

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    // 1 wine + cellar, consumption, gift and recommendation, each a keyed get
    // on the composed doc id. The viewer owns the wine, so no household scope
    // is resolved. A page scans gifts and recommendations instead; one wine
    // reads only its own.
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
    // 1 wine + the four satellite probes, all keyed on the viewer's own docs.
    expect(fake.docReads - before.docReads).toBe(5)
    expect(fake.queryReads - before.queryReads).toBe(0)
  })

  test('names the label family the bottle is drawn with, as the home screen does', async () => {
    seedWine(wid(1), {
      producer: 'Château Margaux',
      region: 'Bordeaux',
      wine: { color: 'red', appellation: 'Margaux' },
    })
    seedWine(wid(2), { name: 'Lagavulin 16', beverageType: 'spirit' })

    const result = await execute(`
      query {
        a: beverage(id: "${wid(1)}") { labelFamily }
        b: beverage(id: "${wid(2)}") { labelFamily }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(result.data).toEqual({ a: { labelFamily: 'CHATEAU' }, b: { labelFamily: 'SPIRIT' } })
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

describe('the wine sheet, in one request', () => {
  test('reads the same whatever the size of the cellar and the number of gifts', async () => {
    fake.seed('cellar-configs', `usr_${userId}`, { rows: 4, cols: 6, zones: 1 })
    // A busy cellar: 30 placed bottles, every fifth one a gift with its advice.
    for (let i = 1; i <= 30; i++) {
      seedWine(wid(i))
      fake.seed('cellar', `${userId}_${wid(i)}`, {
        userId,
        beverageId: wid(i),
        row: Math.floor(i / 6) % 4,
        col: i % 6,
        createdAt: new Date('2026-01-15'),
        updatedAt: new Date('2026-01-15'),
      })
      if (i % 5 === 0) {
        fake.seed('gift', `${userId}_${wid(i)}`, {
          userId,
          beverageId: wid(i),
          received: { from: 'Julien' },
        })
        fake.seed('recommendation', `${userId}_${wid(i)}`, {
          userId,
          beverageId: wid(i),
          comment: 'x',
        })
      }
    }
    fake.seed('journal', 'entry-1', {
      userId,
      beverageId: wid(5),
      type: 'in',
      row: 0,
      col: 5,
      date: new Date('2026-03-01'),
    })

    const before = {
      docReads: fake.docReads,
      queryReads: fake.queryReads,
      queryDocs: fake.queryDocReads,
    }
    // What the app's WineDetail asks, but the attachments' signed URLs.
    const result = await execute(`
      query {
        beverage(id: "${wid(5)}") {
          id
          cellar { cellarId row col }
          consumption { rating }
          gift { received { from } }
          recommendation { comment }
          attachments { id }
          history { type position }
        }
        cellars { id name isPrimary rows cols }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(result.data).toEqual({
      beverage: {
        id: wid(5),
        cellar: { cellarId: `usr_${userId}`, row: 0, col: 5 },
        consumption: null,
        gift: { received: { from: 'Julien' } },
        recommendation: { comment: 'x' },
        attachments: [],
        history: [{ type: 'IN', position: 'A6' }],
      },
      cellars: [{ id: `usr_${userId}`, name: null, isPrimary: true, rows: 4, cols: 6 }],
    })
    // The wine and its four keyed satellites, the membership probe, the primary
    // cellar: never a read per bottle of the cellar.
    expect(fake.docReads - before.docReads).toBe(7)
    // The other cellars, the attachments and the journal of this wine.
    expect(fake.queryReads - before.queryReads).toBe(3)
    expect(fake.queryDocReads - before.queryDocs).toBe(3)
  })
})

describe('wines list query', () => {
  test('serves satellites through the batched loaders, without per-wine fallbacks', async () => {
    // More wines than a sheet's keyed lookups take, so the page path is the one tested.
    for (let i = 1; i <= 6; i++) seedWine(wid(i))
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
      result.data as { beverages: { items: Array<{ id: string } & Record<string, unknown>> } }
    ).beverages.items
    expect(items).toHaveLength(6)
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
    // plus one memoized scan each for the sparse gift and recommendation
    // collections — a flat cost however long the page. If a loader ever stopped
    // batching, per-wine fallbacks would blow these numbers up.
    expect(fake.queryReads - before.queryReads).toBe(3)
    // One batched getAll of 6 refs for cellar and for consumption (the dense
    // satellites) + the household-scope membership probe (one doc get).
    expect(fake.docReads - before.docReads).toBe(13)
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
    const items = (result.data as { beverages: { items: Array<{ history: unknown[] }> } }).beverages
      .items
    expect(items).toHaveLength(5)
    for (const item of items) expect(item.history).toHaveLength(1)
    // 1 page query + 1 batched `in` query over the 5 wine ids — never 5 queries.
    expect(fake.queryReads - before.queryReads).toBe(2)
    // Plus the household-scope membership probe (one bounded doc get).
    expect(fake.docReads - before.docReads).toBe(1)
  })

  test('a household member’s in-cellar wine appears in the list, tagged with its owner', async () => {
    // The viewer (user-1) shares a household with 'marie'; her wid(2) is placed
    // in the shared cellar, so it must surface in the viewer's list with her name.
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
    seedWine(wid(1)) // the viewer's own wine
    fake.seed('beverages', wid(2), {
      id: wid(2),
      userId: 'marie',
      name: `Beverage ${wid(2)}`,
      beverageType: 'wine',
      createdAt: new Date('2026-01-02'),
      updatedAt: new Date('2026-01-02'),
    })
    fake.seed('cellar', `marie_${wid(2)}`, {
      userId: 'marie',
      beverageId: wid(2),
      row: 0,
      col: 0,
      createdAt: new Date('2026-01-15'),
      updatedAt: new Date('2026-01-15'),
    })

    const result = await execute(`query { beverages(limit: 10) { items { id isMine ownerName } } }`)

    expect(result.errors).toBeUndefined()
    const items = (
      result.data as {
        beverages: { items: Array<{ id: string; isMine: boolean; ownerName: string | null }> }
      }
    ).beverages.items
    const byId = new Map(items.map((item) => [item.id, item]))
    expect(byId.get(wid(1))).toEqual({ id: wid(1), isMine: true, ownerName: null })
    expect(byId.get(wid(2))).toEqual({ id: wid(2), isMine: false, ownerName: 'Marie' })
  })
})
