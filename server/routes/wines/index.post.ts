import { Country, Eur, PersonName, Region, Year } from '~/domain/shared/primitives'
import { Rating } from '~/domain/tasting/primitives'
import {
  Appellation,
  Classification,
  WineColor,
  WineDomain,
  WineName,
} from '~/domain/wine/primitives'
import type { Wine } from '~/domain/wine/types'
import { WineUseCase } from '~/domain/wine/use-case'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const name = WineName(body.name)
  const color = WineColor(body.color)

  const data: Partial<Wine> = {}
  if (body.domain) data.domain = WineDomain(body.domain)
  if (body.vintage != null) data.vintage = Year(body.vintage)
  if (body.appellation) data.appellation = Appellation(body.appellation)
  if (body.region) data.region = Region(body.region)
  if (body.country) data.country = Country(body.country)
  if (body.grapeVarieties) data.grapeVarieties = body.grapeVarieties
  if (body.classification) data.classification = Classification(body.classification)
  if (body.purchasePrice != null) data.purchasePrice = Eur(body.purchasePrice)
  if (body.purchaseDate) data.purchaseDate = body.purchaseDate
  if (body.drinkFrom != null) data.drinkFrom = Year(body.drinkFrom)
  if (body.drinkUntil != null) data.drinkUntil = Year(body.drinkUntil)
  if (body.imageBase64) data.imageBase64 = body.imageBase64
  if (body.notes) data.notes = body.notes
  if (body.giftedBy) data.giftedBy = PersonName(body.giftedBy)

  const tasting =
    body.rating != null
      ? {
          rating: Rating(body.rating),
          consumedDate: body.consumedDate ? new Date(body.consumedDate) : new Date(),
          tastingNotes: body.tastingNotes ? body.tastingNotes : undefined,
          contacts: body.contacts?.length ? body.contacts : undefined,
        }
      : undefined

  const wine = await WineUseCase.addWithTasting(name, color, data, tasting)
  return { status: 201, data: wine }
})
