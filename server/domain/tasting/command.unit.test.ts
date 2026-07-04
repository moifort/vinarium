import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import type { Rating } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { TastingCommand } = await import('~/domain/tasting/command')

const userId = 'user-1' as UserId
const wineId = 'w1' as WineId
const rating = (value: number) => value as Rating

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('TastingCommand.create (merge-upsert)', () => {
  test('preserves an existing favorite when later recording a consumption', async () => {
    fake.seed('tasting', `${userId}_w1`, { userId, wineId, favorite: true })

    await TastingCommand.create({
      userId,
      wineId,
      rating: rating(4),
      tastingNotes: 'Belle robe',
    })

    const saved = fake.snapshot('tasting').get(`${userId}_w1`)
    expect(saved?.favorite).toBe(true)
    expect(saved?.rating).toBe(4)
    expect(saved?.tastingNotes).toBe('Belle robe')
  })

  test('preserves an existing rating and notes when only the favorite flag is provided', async () => {
    fake.seed('tasting', `${userId}_w1`, {
      userId,
      wineId,
      rating: rating(4),
      tastingNotes: 'Épicé',
    })

    await TastingCommand.create({ userId, wineId, favorite: true })

    const saved = fake.snapshot('tasting').get(`${userId}_w1`)
    expect(saved?.favorite).toBe(true)
    expect(saved?.rating).toBe(4)
    expect(saved?.tastingNotes).toBe('Épicé')
  })

  test('saves a fresh note when none exists', async () => {
    await TastingCommand.create({ userId, wineId, rating: rating(5) })

    const saved = fake.snapshot('tasting').get(`${userId}_w1`)
    expect(saved).toEqual({ userId, wineId, rating: 5 })
  })
})

describe('TastingCommand.setFavorite', () => {
  test('sets the flag while keeping the existing rating and notes', async () => {
    fake.seed('tasting', `${userId}_w1`, { userId, wineId, rating: rating(3), tastingNotes: 'Vif' })

    await TastingCommand.setFavorite(userId, wineId, true)

    const saved = fake.snapshot('tasting').get(`${userId}_w1`)
    expect(saved?.favorite).toBe(true)
    expect(saved?.rating).toBe(3)
    expect(saved?.tastingNotes).toBe('Vif')
  })

  test('creates a favorite-only note when none exists', async () => {
    await TastingCommand.setFavorite(userId, wineId, true)

    expect(fake.snapshot('tasting').get(`${userId}_w1`)).toEqual({
      userId,
      wineId,
      favorite: true,
    })
  })

  test('clears the flag without dropping the rest of the note', async () => {
    fake.seed('tasting', `${userId}_w1`, {
      userId,
      wineId,
      favorite: true,
      rating: rating(5),
    })

    await TastingCommand.setFavorite(userId, wineId, false)

    const saved = fake.snapshot('tasting').get(`${userId}_w1`)
    expect(saved?.favorite).toBe(false)
    expect(saved?.rating).toBe(5)
  })
})
