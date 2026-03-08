import { expect } from 'bun:test'
import { make } from 'ts-brand'
import { CellarCommand } from '~/domain/cellar/command'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import * as giftRepo from '~/domain/gift/repository'
import * as tastingRepo from '~/domain/tasting/repository'
import { feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './remove.post'

feature('Removing a bottle from the cellar', () => {
  scenario('simple removal', async () => {
    given('a bottle in the cellar')
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

    when('the bottle is removed')
    const event = mockEvent({ body: { wineId: wine.id } })
    const result = await handler(event as any)

    then('the removal is confirmed')
    expect(result.status).toBe(200)
  })

  scenario('removal as a gift', async () => {
    given('a bottle in the cellar')
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

    when('the bottle is removed as a gift')
    const event = mockEvent({
      body: {
        wineId: wine.id,
        gift: { recipientName: 'Jean', giftedDate: '2024-12-25' },
      },
    })
    await handler(event as any)

    then('the gift is recorded with the recipient name')
    const gift = await giftRepo.findBy(wine.id)
    expect(gift).not.toBeNull()
    expect(gift?.recipientName as string).toBe('Jean')
  })

  scenario('removal with tasting note', async () => {
    given('a bottle in the cellar')
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

    when('the bottle is removed with a tasting note')
    const event = mockEvent({
      body: { wineId: wine.id, rating: 4, tastingNotes: 'Très bon' },
    })
    await handler(event as any)

    then('the tasting note is recorded')
    const tasting = await tastingRepo.findBy(wine.id)
    expect(tasting).not.toBeNull()
    expect(tasting?.rating as number).toBe(4)
  })

  scenario('bottle not found returns 404', async () => {
    given('no bottle in the cellar')
    const wine = aWine()

    when('a non-existing bottle is removed')
    const event = mockEvent({ body: { wineId: wine.id } })

    then('a 404 error is returned')
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
