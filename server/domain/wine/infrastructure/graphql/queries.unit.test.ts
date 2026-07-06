import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { schema } = await import('~/domain/shared/graphql/schema')

const userId = 'user-1' as UserId

// The WineId scalar validates UUIDs — deterministic ones keep assertions readable.
const wid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

// No resolver on the tested paths reads the H3 event — only userId matters.
const execute = (source: string) =>
  graphql({ schema, source, contextValue: { userId, event: undefined as never } })

const seedWine = (id: string, over: Record<string, unknown> = {}) =>
  fake.seed('wines', id, {
    id,
    userId,
    name: `Wine ${id}`,
    beverageType: 'wine',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...over,
  })

// Satellite collections key their single record per (user, wine) as `${userId}_${wineId}`.
const seedSatellites = (wineId: string) => {
  fake.seed('tasting', `${userId}_${wineId}`, { userId, wineId, rating: 4, favorite: true })
  fake.seed('gift', `${userId}_${wineId}`, {
    userId,
    wineId,
    giftedDate: new Date('2026-02-01'),
    recipientName: 'Alice',
  })
  fake.seed('recommendation', `${userId}_${wineId}`, { userId, wineId, comment: 'Superbe' })
  fake.seed('cellar', `${userId}_${wineId}`, {
    userId,
    wineId,
    row: 2,
    col: 3,
    createdAt: new Date('2026-01-15'),
    updatedAt: new Date('2026-01-15'),
  })
}

const detailQuery = (id: string) => `
  query {
    wine(id: "${id}") {
      id
      name
      cellar { row col rowLabel colLabel }
      consumption { rating favorite }
      gift { recipientName }
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
    expect(result.data?.wine).toEqual({
      id: wid(1),
      name: `Wine ${wid(1)}`,
      cellar: { row: 2, col: 3, rowLabel: 'C', colLabel: 4 },
      consumption: { rating: 4, favorite: true },
      gift: { recipientName: 'Alice' },
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
    // 1 wine + 4 satellites, each a keyed get on doc `${userId}_${wineId}`
    expect(fake.docReads - before.docReads).toBe(5)
    expect(fake.queryReads - before.queryReads).toBe(0)
  })

  test('resolves absent satellites to null, at the same read budget', async () => {
    seedWine(wid(1))

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    expect(result.data?.wine).toEqual({
      id: wid(1),
      name: `Wine ${wid(1)}`,
      cellar: null,
      consumption: null,
      gift: null,
      recommendation: null,
    })
    expect(fake.docReads - before.docReads).toBe(5)
    expect(fake.queryReads - before.queryReads).toBe(0)
  })

  test('returns null for a wine owned by another user', async () => {
    fake.seed('wines', wid(1), {
      id: wid(1),
      userId: 'someone-else',
      name: `Wine ${wid(1)}`,
      beverageType: 'wine',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    const result = await execute(detailQuery(wid(1)))

    expect(result.errors).toBeUndefined()
    expect(result.data?.wine).toBeNull()
  })
})

describe('wines list query', () => {
  test('still serves satellites from the batched assembly, without per-wine fallbacks', async () => {
    seedWine(wid(1))
    seedWine(wid(2))
    seedSatellites(wid(1))

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute(`
      query {
        wines(limit: 10) {
          items {
            id
            cellar { row col }
            consumption { rating }
            gift { recipientName }
            recommendation { comment }
          }
        }
      }
    `)

    expect(result.errors).toBeUndefined()
    const items = (result.data?.wines as { items: Array<{ id: string } & Record<string, unknown>> })
      .items
    expect(items).toHaveLength(2)
    const byId = new Map(items.map((item) => [item.id, item]))
    expect(byId.get(wid(1))).toEqual({
      id: wid(1),
      cellar: { row: 2, col: 3 },
      consumption: { rating: 4 },
      gift: { recipientName: 'Alice' },
      recommendation: { comment: 'Superbe' },
    })
    expect(byId.get(wid(2))).toEqual({
      id: wid(2),
      cellar: null,
      consumption: null,
      gift: null,
      recommendation: null,
    })
    // Budget guard for the short-circuit: 1 page query + batched getAll of 2 refs
    // for the wines and each of the 4 satellite collections. If assemble ever
    // stopped attaching satellites, the per-wine fallbacks would add 8 doc reads.
    expect(fake.queryReads - before.queryReads).toBe(1)
    expect(fake.docReads - before.docReads).toBe(10)
  })
})
