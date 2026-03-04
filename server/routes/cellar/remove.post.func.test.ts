import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import { CellarCommand } from '~/domain/cellar/command'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import * as giftRepo from '~/domain/gift/repository'
import * as tastingRepo from '~/domain/tasting/repository'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './remove.post'

describe('POST /cellar/remove', () => {
  test('removes wine from cellar', async () => {
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

    const event = mockEvent({ body: { wineId: wine.id } })
    const result = await handler(event as any)
    expect(result.status).toBe(200)
  })

  test('creates gift when gift data provided', async () => {
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

    const event = mockEvent({
      body: {
        wineId: wine.id,
        gift: { recipientName: 'Jean', giftedDate: '2024-12-25' },
      },
    })
    await handler(event as any)

    const gift = await giftRepo.findBy(wine.id)
    expect(gift).not.toBeNull()
    expect(gift?.recipientName as string).toBe('Jean')
  })

  test('creates tasting note when tasting data provided', async () => {
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

    const event = mockEvent({
      body: { wineId: wine.id, rating: 4, tastingNotes: 'Très bon' },
    })
    await handler(event as any)

    const tasting = await tastingRepo.findBy(wine.id)
    expect(tasting).not.toBeNull()
    expect(tasting?.rating as number).toBe(4)
  })

  test('throws 404 when not in cellar', async () => {
    const wine = aWine()
    const event = mockEvent({ body: { wineId: wine.id } })
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
