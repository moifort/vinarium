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
  fake.seed('wines', 'w1', {
    id: 'w1',
    userId,
    name: 'Château Margaux',
    beverageType: 'wine',
    color: 'red',
    domain: 'Château Margaux',
    region: 'Bordeaux',
    vintage: 2015,
    createdAt: new Date('2026-01-03'),
    updatedAt: new Date('2026-01-03'),
  })
  fake.seed('wines', 'w2', {
    id: 'w2',
    userId,
    name: 'Pouilly-Fumé',
    beverageType: 'wine',
    color: 'white',
    vintage: 2021,
    createdAt: new Date('2026-01-02'),
    updatedAt: new Date('2026-01-02'),
  })
  fake.seed('wines', 'w3', {
    id: 'w3',
    userId,
    name: 'Porto Vintage',
    beverageType: 'wine',
    subtype: 'porto',
    giftedBy: 'Alice Martin',
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  })
  fake.seed('cellar', `${userId}_w1`, {
    userId,
    wineId: 'w1',
    row: 0,
    col: 0,
    createdAt: new Date('2026-01-03'),
    updatedAt: new Date('2026-01-03'),
  })
  fake.seed('tasting', `${userId}_w2`, {
    userId,
    wineId: 'w2',
    favorite: true,
    consumedDate: new Date('2026-02-01'),
  })
  fake.seed('gift', `${userId}_w3`, {
    userId,
    wineId: 'w3',
    giftedDate: new Date('2026-01-01'),
    recipientName: 'Bob Durand',
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
    fake.seed('wines', 'a', {
      id: 'a',
      userId,
      name: 'Château Margaux',
      beverageType: 'wine',
      createdAt: new Date('2026-01-02'),
      updatedAt: new Date('2026-01-02'),
    })
    fake.seed('wines', 'b', {
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
    await run('margaux')
    expect(fake.reads).toBe(5)
  })
})
