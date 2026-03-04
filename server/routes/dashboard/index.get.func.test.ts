import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import * as cellarRepo from '~/domain/cellar/repository'
import type { Eur } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/repository'
import type { Rating } from '~/domain/tasting/types'
import * as wineRepo from '~/domain/wine/repository'
import { aCellarBottle, aTastingNote, aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './index.get'

describe('GET /dashboard', () => {
  test('returns dashboard with bottle count and total value', async () => {
    const wine1 = aWine({ purchasePrice: make<Eur>()(20) })
    const wine2 = aWine({ purchasePrice: make<Eur>()(30) })
    await wineRepo.save(wine1)
    await wineRepo.save(wine2)
    await cellarRepo.save(aCellarBottle({ wineId: wine1.id }))
    await cellarRepo.save(
      aCellarBottle({
        wineId: wine2.id,
        row: make<import('~/domain/cellar/types').CellarRow>()(0),
        col: make<import('~/domain/cellar/types').CellarCol>()(1),
      }),
    )

    const event = mockEvent()
    const result = await handler(event as any)
    expect(result.status).toBe(200)
    expect(result.data.bottleCount).toBe(2)
    expect(result.data.totalValue).toBe(50)
  })

  test('includes favorites with 5-star ratings', async () => {
    const wine = aWine()
    await wineRepo.save(wine)
    await tastingRepo.save(aTastingNote({ wineId: wine.id, rating: make<Rating>()(5) }))

    const event = mockEvent()
    const result = await handler(event as any)
    expect(result.data.favorites).toHaveLength(1)
    expect(result.data.favorites[0].id).toBe(wine.id)
  })
})
