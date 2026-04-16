import {
  Country,
  Eur,
  Latitude,
  Longitude,
  PersonName,
  PlaceName,
  Region,
  Year,
} from '~/domain/shared/primitives'
import { WineCommand } from '~/domain/wine/command'
import {
  Appellation,
  Classification,
  WineColor,
  WineDomain,
  WineId,
  WineName,
} from '~/domain/wine/primitives'
import type { Wine } from '~/domain/wine/types'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const data: Partial<Wine> = {}

  if (body.name !== undefined) data.name = WineName(body.name)
  if (body.domain !== undefined) data.domain = WineDomain(body.domain)
  if (body.vintage !== undefined) data.vintage = Year(body.vintage)
  if (body.appellation !== undefined) data.appellation = Appellation(body.appellation)
  if (body.region !== undefined) data.region = Region(body.region)
  if (body.country !== undefined) data.country = Country(body.country)
  if (body.color !== undefined) data.color = WineColor(body.color)
  if (body.grapeVarieties !== undefined) data.grapeVarieties = body.grapeVarieties
  if (body.classification !== undefined) data.classification = Classification(body.classification)
  if (body.purchasePrice !== undefined) data.purchasePrice = Eur(body.purchasePrice)
  if (body.purchaseDate !== undefined) data.purchaseDate = body.purchaseDate
  if (body.drinkFrom !== undefined) data.drinkFrom = Year(body.drinkFrom)
  if (body.drinkUntil !== undefined) data.drinkUntil = Year(body.drinkUntil)
  if (body.imageBase64 !== undefined) data.imageBase64 = body.imageBase64
  if (body.giftedBy !== undefined) data.giftedBy = PersonName(body.giftedBy)
  if (body.notes !== undefined) data.notes = body.notes
  if (body.latitude !== undefined) data.latitude = Latitude(body.latitude)
  if (body.longitude !== undefined) data.longitude = Longitude(body.longitude)
  if (body.placeName !== undefined) data.placeName = PlaceName(body.placeName)
  if (
    (body.latitude !== undefined || body.longitude !== undefined) &&
    (data.latitude == null) !== (data.longitude == null)
  )
    throw createError({
      statusCode: 400,
      statusMessage: 'latitude and longitude must be provided together',
    })

  const wine = await WineCommand.update(id, data)
  if (wine === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: wine }
})
