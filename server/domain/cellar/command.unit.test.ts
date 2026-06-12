import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { CellarBottle, CellarCol, CellarRow } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { CellarCommand } = await import('~/domain/cellar/command')

const userId = 'user-1' as UserId
const row = (value: number) => value as CellarRow
const col = (value: number) => value as CellarCol
const wine = (id: string) => id as WineId

const bottle = (wineId: string, r: number, c: number): CellarBottle => ({
  userId,
  wineId: wine(wineId),
  row: row(r),
  col: col(c),
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
})

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('CellarCommand.moveBottle', () => {
  test('moves a bottle to a free position and journals the movement in a single batch', async () => {
    fake.seed('cellar', `${userId}_w1`, bottle('w1', 0, 0))

    const result = await CellarCommand.moveBottle(userId, wine('w1'), row(2), col(3))

    expect(result).not.toBe('not-in-cellar')
    const moved = result as CellarBottle
    expect(moved.row).toBe(row(2))
    expect(moved.col).toBe(col(3))

    // Atomicity contract: one batch, committed once, no writes outside it
    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.batches[0].ops).toHaveLength(3)
    expect(fake.directWrites).toEqual([])

    const cellarDoc = fake.snapshot('cellar').get(`${userId}_w1`)
    expect(cellarDoc?.row).toBe(2)
    expect(cellarDoc?.col).toBe(3)

    const journal = [...fake.snapshot('journal').values()]
    expect(journal).toHaveLength(2)
    const out = journal.find((entry) => entry.type === 'out')
    expect(out).toMatchObject({ wineId: 'w1', row: 0, col: 0, userId })
    const entryIn = journal.find((entry) => entry.type === 'in')
    expect(entryIn).toMatchObject({ wineId: 'w1', row: 2, col: 3, userId })
  })

  test('swaps with the occupant of the target position in one batch', async () => {
    fake.seed('cellar', `${userId}_w1`, bottle('w1', 0, 0))
    fake.seed('cellar', `${userId}_w2`, bottle('w2', 1, 1))

    const result = await CellarCommand.moveBottle(userId, wine('w1'), row(1), col(1))

    const moved = result as CellarBottle
    expect(moved.row).toBe(row(1))
    expect(moved.col).toBe(col(1))

    // 2 cellar saves + 4 journal entries, all in the same single-commit batch
    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.batches[0].ops).toHaveLength(6)
    expect(fake.directWrites).toEqual([])

    expect(fake.snapshot('cellar').get(`${userId}_w1`)).toMatchObject({ row: 1, col: 1 })
    expect(fake.snapshot('cellar').get(`${userId}_w2`)).toMatchObject({ row: 0, col: 0 })

    const journal = [...fake.snapshot('journal').values()]
    const trail = journal.map(({ type, wineId, row: r, col: c }) => ({
      type,
      wineId,
      row: r,
      col: c,
    }))
    expect(trail).toContainEqual({ type: 'out', wineId: 'w1', row: 0, col: 0 })
    expect(trail).toContainEqual({ type: 'in', wineId: 'w1', row: 1, col: 1 })
    expect(trail).toContainEqual({ type: 'out', wineId: 'w2', row: 1, col: 1 })
    expect(trail).toContainEqual({ type: 'in', wineId: 'w2', row: 0, col: 0 })
    expect(trail).toHaveLength(4)
  })

  test('a failing commit leaves the cellar and journal untouched', async () => {
    fake.seed('cellar', `${userId}_w1`, bottle('w1', 0, 0))
    fake.seed('cellar', `${userId}_w2`, bottle('w2', 1, 1))
    fake.failCommitsWith(new Error('firestore unavailable'))

    await expect(CellarCommand.moveBottle(userId, wine('w1'), row(1), col(1))).rejects.toThrow(
      'firestore unavailable',
    )

    expect(fake.snapshot('cellar').get(`${userId}_w1`)).toMatchObject({ row: 0, col: 0 })
    expect(fake.snapshot('cellar').get(`${userId}_w2`)).toMatchObject({ row: 1, col: 1 })
    expect(fake.snapshot('journal').size).toBe(0)
    expect(fake.directWrites).toEqual([])
  })

  test('returns not-in-cellar without writing anything', async () => {
    const result = await CellarCommand.moveBottle(userId, wine('w1'), row(1), col(1))

    expect(result).toBe('not-in-cellar')
    expect(fake.batches).toHaveLength(0)
    expect(fake.directWrites).toEqual([])
  })

  test('moving to the current position writes nothing', async () => {
    fake.seed('cellar', `${userId}_w1`, bottle('w1', 2, 3))

    const result = await CellarCommand.moveBottle(userId, wine('w1'), row(2), col(3))

    expect((result as CellarBottle).wineId).toBe(wine('w1'))
    expect(fake.batches).toHaveLength(0)
    expect(fake.directWrites).toEqual([])
    expect(fake.snapshot('journal').size).toBe(0)
  })
})
