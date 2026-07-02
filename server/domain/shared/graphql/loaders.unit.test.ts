import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { createLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('createLoaders', () => {
  test('resolves nested wine fields from the user collections', async () => {
    fake.seed('cellar', `${userId}_w1`, { userId, wineId: 'w1', row: 0, col: 2 })
    fake.seed('tasting', `${userId}_w1`, { userId, wineId: 'w1', rating: 4 })
    fake.seed('gift', `${userId}_w2`, { userId, wineId: 'w2', recipientName: 'Alice' })
    fake.seed('recommendation', `${userId}_w2`, { userId, wineId: 'w2', recommenderName: 'Bob' })

    const loaders = createLoaders(userId)

    expect(await loaders.cellarPlacement.byWineId('w1' as WineId)).toMatchObject({
      wineId: 'w1',
      row: 0,
      col: 2,
      rowLabel: 'A',
    })
    expect(await loaders.consumption.byWineId('w1' as WineId)).toMatchObject({ rating: 4 })
    expect(await loaders.gift.byWineId('w2' as WineId)).toMatchObject({ recipientName: 'Alice' })
    expect(await loaders.recommendation.byWineId('w2' as WineId)).toMatchObject({
      recommenderName: 'Bob',
    })
  })

  test('returns null for wines without a record', async () => {
    const loaders = createLoaders(userId)
    expect(await loaders.gift.byWineId('unknown' as WineId)).toBeNull()
  })

  test('reads each collection once regardless of how many wines are resolved', async () => {
    for (const wineId of ['w1', 'w2', 'w3']) {
      fake.seed('tasting', `${userId}_${wineId}`, { userId, wineId, rating: 3 })
    }

    const loaders = createLoaders(userId)
    const before = fake.reads
    await Promise.all(
      ['w1', 'w2', 'w3', 'w4'].map((id) => loaders.consumption.byWineId(id as WineId)),
    )

    expect(fake.reads - before).toBe(1)
  })

  test('only returns records belonging to the loader user', async () => {
    fake.seed('tasting', `${userId}_w1`, { userId, wineId: 'w1', rating: 5 })
    fake.seed('tasting', 'other_w1', { userId: 'other', wineId: 'w1', rating: 1 })

    const loaders = createLoaders(userId)

    expect(await loaders.consumption.byWineId('w1' as WineId)).toMatchObject({ rating: 5 })
  })
})
