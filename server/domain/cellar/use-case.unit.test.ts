import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { BeverageId } from '~/domain/beverage/types'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { CellarUseCase } = await import('~/domain/cellar/use-case')

const userId = 'user-1' as UserId
const beverageId = 'w1' as BeverageId

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

const seedBottle = () =>
  fake.seed('cellar', `${userId}_w1`, {
    userId,
    beverageId,
    row: 0 as CellarRow,
    col: 0 as CellarCol,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  })

describe('CellarUseCase.removeBottle', () => {
  test('consuming a favorite bottle keeps it a favorite', async () => {
    seedBottle()
    fake.seed('tasting', `${userId}_w1`, { userId, beverageId, favorite: true })

    const result = await CellarUseCase.removeBottle(userId, beverageId, {
      type: 'tasting',
      rating: 4 as never,
      tastingNotes: 'Dernier verre',
    })

    expect(result).toBeUndefined()
    const tasting = fake.snapshot('tasting').get(`${userId}_w1`)
    expect(tasting?.favorite).toBe(true)
    expect(tasting?.rating).toBe(4)
    expect(tasting?.tastingNotes).toBe('Dernier verre')
    // the bottle left the cellar
    expect(fake.snapshot('cellar').get(`${userId}_w1`)).toBeUndefined()
  })

  test('returns not-in-cellar when the bottle is absent', async () => {
    const result = await CellarUseCase.removeBottle(userId, beverageId, { type: 'tasting' })

    expect(result).toBe('not-in-cellar')
  })
})
