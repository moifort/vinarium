import { expect } from 'bun:test'
import { make } from 'ts-brand'
import * as cellarRepo from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import type { Eur } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/repository'
import type { Rating } from '~/domain/tasting/types'
import * as wineRepo from '~/domain/wine/repository'
import { feature, given, scenario, then, when } from '~/test/bdd'
import { aCellarBottle, aTastingNote, aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './index.get'

feature('Dashboard overview', () => {
  scenario('displaying bottle count and total value', async () => {
    given('two bottles in the cellar worth 20€ and 30€')
    const wine1 = aWine({ purchasePrice: make<Eur>()(20) })
    const wine2 = aWine({ purchasePrice: make<Eur>()(30) })
    await wineRepo.save(wine1)
    await wineRepo.save(wine2)
    await cellarRepo.save(aCellarBottle({ wineId: wine1.id }))
    await cellarRepo.save(
      aCellarBottle({
        wineId: wine2.id,
        row: make<CellarRow>()(0),
        col: make<CellarCol>()(1),
      }),
    )

    when('the dashboard is loaded')
    const event = mockEvent()
    const result = await handler(event as any)

    then('the bottle count is 2 and total value is 50€')
    expect(result.status).toBe(200)
    expect(result.data.bottleCount).toBe(2)
    expect(result.data.totalValue).toBe(50)
  })

  scenario('showing 5-star favorites', async () => {
    given('a wine with a 5-star rating')
    const wine = aWine()
    await wineRepo.save(wine)
    await tastingRepo.save(aTastingNote({ wineId: wine.id, rating: make<Rating>()(5) }))

    when('the dashboard is loaded')
    const event = mockEvent()
    const result = await handler(event as any)

    then('the wine appears in favorites')
    expect(result.data.favorites).toHaveLength(1)
    expect(result.data.favorites[0].id).toBe(wine.id)
  })
})
