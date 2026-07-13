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

describe('CellarUseCase.removeBottle (household)', () => {
  const marieBeverage = 'w2' as BeverageId

  // 'user-1' and 'marie' share a household; marie owns a bottle in the shared grid.
  const seedShared = () => {
    const memberDoc = (id: string, role: 'owner' | 'member') => ({
      userId: id,
      householdId: 'h1',
      displayName: id,
      role,
      joinedAt: new Date('2026-01-01'),
    })
    fake.seed('household-members', userId, memberDoc(userId, 'owner'))
    fake.seed('household-members', 'marie', memberDoc('marie', 'member'))
    fake.seed('cellar', `marie_${marieBeverage}`, {
      userId: 'marie',
      beverageId: marieBeverage,
      row: 0 as CellarRow,
      col: 0 as CellarCol,
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })
  }

  test('consuming a housemate’s bottle files the note under the actor, the exit under the owner', async () => {
    seedShared()

    const result = await CellarUseCase.removeBottle(userId, marieBeverage, {
      type: 'tasting',
      rating: 5 as never,
      tastingNotes: 'Partagé au dîner',
    })

    expect(result).toBeUndefined()
    // The bottle left marie's slot; her journal records the exit.
    expect(fake.snapshot('cellar').get(`marie_${marieBeverage}`)).toBeUndefined()
    const journal = [...fake.snapshot('journal').values()]
    expect(journal).toHaveLength(1)
    expect(journal[0]).toMatchObject({ type: 'out', userId: 'marie', beverageId: marieBeverage })
    // The tasting note is the actor's own, keyed under their id — never marie's.
    expect(fake.snapshot('tasting').get(`${userId}_${marieBeverage}`)).toMatchObject({ rating: 5 })
    expect(fake.snapshot('tasting').get(`marie_${marieBeverage}`)).toBeUndefined()
  })

  test('gifting a housemate’s bottle records the gift under the owner', async () => {
    seedShared()

    const result = await CellarUseCase.removeBottle(userId, marieBeverage, {
      type: 'gift',
      given: { date: new Date('2026-03-01'), recipientName: 'Léa' as never },
    })

    expect(result).toBeUndefined()
    // The owner's wine was given away — the gift record is hers, not the actor's.
    expect(fake.snapshot('gift').get(`marie_${marieBeverage}`)).toMatchObject({
      given: { recipientName: 'Léa' },
    })
    expect(fake.snapshot('gift').get(`${userId}_${marieBeverage}`)).toBeUndefined()
  })
})
