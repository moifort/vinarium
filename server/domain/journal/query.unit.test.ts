import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { JournalQuery } = await import('~/domain/journal/query')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const seed = () => {
  fake.seed('wines', 'w1', { id: 'w1', userId, name: 'W1', beverageType: 'wine' })
  for (let i = 0; i < 5; i++) {
    fake.seed('journal', `e${i}`, {
      type: 'in',
      userId,
      wineId: 'w1',
      row: 0,
      col: i,
      date: new Date(2026, 0, i + 1),
    })
  }
}

describe('JournalQuery.page', () => {
  test('returns a bounded page most-recent-first with hasMore', async () => {
    seed()
    const first = await JournalQuery.page(userId, { limit: 2, offset: 0 })
    expect(first.items.length).toBe(2)
    expect(first.hasMore).toBe(true)
    // date desc: e4 (Jan 5) then e3 (Jan 4)
    expect(first.items.map((i) => i.position)).toEqual(['A5', 'A4'])
  })

  test('offset advances the page and clears hasMore at the end', async () => {
    seed()
    const page = await JournalQuery.page(userId, { limit: 2, offset: 4 })
    expect(page.items.length).toBe(1)
    expect(page.hasMore).toBe(false)
  })
})
