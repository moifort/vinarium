import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { WineUseCase } = await import('~/domain/wine/use-case')

const userId = 'user-1' as UserId
const wineId = 'w1' as WineId

const seedWineWithRelatedData = (fake: ReturnType<typeof resetFakeFirestore>) => {
  fake.seed('wines', 'w1', { id: 'w1', userId, name: 'Château Test', color: 'red' })
  fake.seed('cellar', `${userId}_w1`, { userId, wineId: 'w1', row: 0, col: 0 })
  fake.seed('tasting', `${userId}_w1`, { userId, wineId: 'w1', rating: 4 })
  fake.seed('gift', `${userId}_w1`, { userId, wineId: 'w1', recipient: 'Alice' })
  fake.seed('recommendation', `${userId}_w1`, { userId, wineId: 'w1', source: 'Bob' })
  fake.seed('journal', 'j1', { type: 'in', userId, wineId: 'w1', row: 0, col: 0 })
  fake.seed('journal', 'j2', { type: 'out', userId, wineId: 'w1', row: 0, col: 0 })
  // Unrelated data that must survive the removal
  fake.seed('wines', 'w2', { id: 'w2', userId, name: 'Survivor', color: 'white' })
  fake.seed('journal', 'j3', { type: 'in', userId, wineId: 'w2', row: 1, col: 1 })
  fake.seed('tasting', `${userId}_w2`, { userId, wineId: 'w2', rating: 5 })
}

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('WineUseCase.removeCompletely', () => {
  test('erases the wine and every related entry in a single batch', async () => {
    seedWineWithRelatedData(fake)

    const result = await WineUseCase.removeCompletely(userId, wineId)

    expect(result).toBeUndefined()

    // Atomicity contract: one batch, committed once, no writes outside it
    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.directWrites).toEqual([])

    // Only deletions — no journal bottle-out entry is written, it would
    // survive the journal wipe and point at a deleted wine
    const ops = fake.batches[0].ops
    expect(ops.every((op) => op.type === 'delete')).toBe(true)
    const deleted = ops.map((op) => `${op.ref.collection}/${op.ref.id}`).sort()
    expect(deleted).toEqual(
      [
        'wines/w1',
        `cellar/${userId}_w1`,
        `tasting/${userId}_w1`,
        `gift/${userId}_w1`,
        `recommendation/${userId}_w1`,
        'journal/j1',
        'journal/j2',
      ].sort(),
    )

    // The wine is gone everywhere, unrelated data survives
    expect([...fake.snapshot('wines').keys()]).toEqual(['w2'])
    expect([...fake.snapshot('journal').keys()]).toEqual(['j3'])
    expect([...fake.snapshot('tasting').keys()]).toEqual([`${userId}_w2`])
    expect(fake.snapshot('cellar').size).toBe(0)
    expect(fake.snapshot('gift').size).toBe(0)
    expect(fake.snapshot('recommendation').size).toBe(0)
  })

  test('returns not-found and deletes nothing when the wine does not exist', async () => {
    fake.seed('wines', 'w2', { id: 'w2', userId, name: 'Survivor', color: 'white' })

    const result = await WineUseCase.removeCompletely(userId, wineId)

    expect(result).toBe('not-found')
    expect(fake.directWrites).toEqual([])
    for (const batch of fake.batches) expect(batch.ops).toEqual([])
    expect([...fake.snapshot('wines').keys()]).toEqual(['w2'])
  })

  test('a failing commit leaves the wine and all related entries intact', async () => {
    seedWineWithRelatedData(fake)
    fake.failCommitsWith(new Error('firestore unavailable'))

    await expect(WineUseCase.removeCompletely(userId, wineId)).rejects.toThrow(
      'firestore unavailable',
    )

    expect(fake.directWrites).toEqual([])
    expect(fake.snapshot('wines').size).toBe(2)
    expect(fake.snapshot('cellar').size).toBe(1)
    expect(fake.snapshot('tasting').size).toBe(2)
    expect(fake.snapshot('gift').size).toBe(1)
    expect(fake.snapshot('recommendation').size).toBe(1)
    expect(fake.snapshot('journal').size).toBe(3)
  })
})
