import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { HouseholdId, HouseholdMember } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { JournalQuery } = await import('~/domain/journal/query')

const userId = 'user-1' as UserId

const member = (id: string, role: 'owner' | 'member'): HouseholdMember => ({
  userId: id as UserId,
  householdId: 'h1' as HouseholdId,
  displayName: `${id} name` as PersonName,
  role,
  joinedAt: new Date('2026-01-01'),
})

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const seed = () => {
  fake.seed('beverages', 'w1', { id: 'w1', userId, name: 'W1', beverageType: 'wine' })
  for (let i = 0; i < 5; i++) {
    fake.seed('journal', `e${i}`, {
      type: 'in',
      userId,
      beverageId: 'w1',
      row: 0,
      col: i,
      date: new Date(2026, 0, i + 1),
    })
  }
}

// The viewer (user-1) shares a cellar with marie. She owns 'm1', still placed, and
// 'm2', which she has already drunk — so it is out of cellar and out of the
// viewer's visible library, yet its exit belongs to the shared journal.
const seedHousehold = () => {
  fake.seed('household-members', userId, member(userId, 'owner'))
  fake.seed('household-members', 'marie', member('marie', 'member'))
  fake.seed('beverages', 'w1', { id: 'w1', userId, name: 'W1', beverageType: 'wine' })
  fake.seed('beverages', 'm1', { id: 'm1', userId: 'marie', name: 'M1', beverageType: 'wine' })
  fake.seed('beverages', 'm2', { id: 'm2', userId: 'marie', name: 'M2', beverageType: 'wine' })
  fake.seed('cellar', 'marie_m1', { userId: 'marie', beverageId: 'm1', row: 0, col: 1 })
  fake.seed('journal', 'j-mine', {
    type: 'in',
    userId,
    beverageId: 'w1',
    row: 0,
    col: 0,
    date: new Date('2026-01-01'),
  })
  fake.seed('journal', 'j-hers', {
    type: 'in',
    userId: 'marie',
    beverageId: 'm1',
    row: 0,
    col: 1,
    date: new Date('2026-01-02'),
  })
  fake.seed('journal', 'j-hers-out', {
    type: 'out',
    userId: 'marie',
    beverageId: 'm2',
    row: 1,
    col: 1,
    date: new Date('2026-01-03'),
  })
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

  test('merges every member’s movements, each naming who moved the bottle', async () => {
    seedHousehold()

    const { items } = await JournalQuery.page(userId, { limit: 15, offset: 0 })

    expect(items.map(({ beverageId }) => String(beverageId))).toEqual(['m2', 'm1', 'w1'])
    const byBeverage = new Map(items.map((item) => [String(item.beverageId), item]))
    expect(byBeverage.get('w1')?.actor).toMatchObject({ userId, isMine: true })
    expect(byBeverage.get('w1')?.actor.displayName).toBeUndefined()
    expect(byBeverage.get('m1')?.actor).toMatchObject({
      userId: 'marie',
      displayName: 'marie name',
      isMine: false,
    })
  })

  test('keeps a housemate’s exit even though its wine left the shared cellar', async () => {
    seedHousehold()

    const { items } = await JournalQuery.page(userId, { limit: 15, offset: 0 })

    expect(items.find(({ beverageId }) => beverageId === 'm2')).toMatchObject({
      type: 'out',
      beverageName: 'M2',
    })
  })
})

describe('JournalQuery.latestExit', () => {
  test('returns the household’s most recent exit, skipping newer entries', async () => {
    seedHousehold()
    // A later 'in' must not shadow the exit: only 'out' events qualify.
    fake.seed('journal', 'j-mine-in-later', {
      type: 'in',
      userId,
      beverageId: 'w1',
      row: 0,
      col: 2,
      date: new Date('2026-01-05'),
    })

    const exit = await JournalQuery.latestExit(userId)

    expect(exit).toMatchObject({ type: 'out', beverageName: 'M2' })
    expect(exit?.actor).toMatchObject({ userId: 'marie', isMine: false })
  })

  test('undefined when no bottle ever left the cellar', async () => {
    seed()

    expect(await JournalQuery.latestExit(userId)).toBeUndefined()
  })

  test('costs one bounded query plus the exit’s wine, never a journal scan', async () => {
    seedHousehold()

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    await JournalQuery.latestExit(userId)

    // The household members query and the limit(1) exit query.
    expect(fake.queryReads - before.queryReads).toBe(2)
    // The membership doc and the exit's wine (m2), read by id.
    expect(fake.docReads - before.docReads).toBe(2)
  })
})

describe('JournalQuery.historyOf', () => {
  test('names the member behind each movement of a shared wine', async () => {
    seedHousehold()
    const wine = { id: 'm1', userId: 'marie', name: 'M1', beverageType: 'wine' }
    const entries = await JournalQuery.entriesByBeverageIds(userId, ['m1'] as never)

    // biome-ignore lint/suspicious/noExplicitAny: the wine shape is a test fixture
    const history = await JournalQuery.historyOf(userId, wine as any, entries)

    expect(history).toHaveLength(1)
    expect(history[0]?.actor).toMatchObject({
      userId: 'marie',
      displayName: 'marie name',
      isMine: false,
    })
  })

  test('entries stay scoped to the household, never another cellar', async () => {
    seedHousehold()
    fake.seed('journal', 'j-stranger', {
      type: 'in',
      userId: 'stranger',
      beverageId: 'm1',
      row: 2,
      col: 2,
      date: new Date('2026-01-04'),
    })

    const entries = await JournalQuery.entriesByBeverageIds(userId, ['m1'] as never)

    expect(entries.map(({ userId: actor }) => String(actor))).toEqual(['marie'])
  })
})
