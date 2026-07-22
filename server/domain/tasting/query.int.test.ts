import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { TastingQuery } = await import('~/domain/tasting/query')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('TastingQuery.favorites', () => {
  test('returns only the viewer’s favorited notes', async () => {
    fake.seed('tasting', `${userId}_w1`, { userId, beverageId: 'w1', favorite: true, rating: 5 })
    fake.seed('tasting', `${userId}_w2`, { userId, beverageId: 'w2', favorite: false })
    fake.seed('tasting', `${userId}_w3`, { userId, beverageId: 'w3', rating: 3 })
    fake.seed('tasting', 'other_w9', { userId: 'other', beverageId: 'w9', favorite: true })

    const favorites = await TastingQuery.favorites(userId)

    expect(favorites.map(({ beverageId }) => String(beverageId))).toEqual(['w1'])
  })

  test('costs one query however large the tasting history', async () => {
    for (let i = 0; i < 100; i++) {
      fake.seed('tasting', `${userId}_w${i}`, { userId, beverageId: `w${i}`, rating: 3 })
    }
    fake.seed('tasting', `${userId}_fav`, { userId, beverageId: 'fav', favorite: true })

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const favorites = await TastingQuery.favorites(userId)

    expect(favorites).toHaveLength(1)
    expect(fake.queryReads - before.queryReads).toBe(1)
    expect(fake.docReads - before.docReads).toBe(0)
  })
})
