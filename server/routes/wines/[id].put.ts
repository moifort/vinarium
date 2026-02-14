import { z } from 'zod'
import { Country, Eur, Region, Year } from '~/primitives'
import { Wines } from '~/wine/index'
import { AlcoholContent, WineId, WineName } from '~/wine/primitives'
import type { Wine } from '~/wine/types'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const data: Partial<Wine> = {}

  if (body.name !== undefined) data.name = WineName(body.name)
  if (body.domain !== undefined) data.domain = body.domain
  if (body.vintage !== undefined) data.vintage = Year(body.vintage)
  if (body.appellation !== undefined) data.appellation = body.appellation
  if (body.region !== undefined) data.region = Region(body.region)
  if (body.country !== undefined) data.country = Country(body.country)
  if (body.color !== undefined)
    data.color = z.enum(['red', 'white', 'rosé', 'sparkling', 'sweet']).parse(body.color)
  if (body.grapeVarieties !== undefined) data.grapeVarieties = body.grapeVarieties
  if (body.alcoholContent !== undefined) data.alcoholContent = AlcoholContent(body.alcoholContent)
  if (body.classification !== undefined) data.classification = body.classification
  if (body.purchasePrice !== undefined) data.purchasePrice = Eur(body.purchasePrice)
  if (body.purchaseDate !== undefined) data.purchaseDate = body.purchaseDate
  if (body.drinkFrom !== undefined) data.drinkFrom = Year(body.drinkFrom)
  if (body.drinkUntil !== undefined) data.drinkUntil = Year(body.drinkUntil)
  if (body.imageBase64 !== undefined) data.imageBase64 = body.imageBase64
  if (body.notes !== undefined) data.notes = body.notes

  const wine = await Wines.update(id, data)
  if (wine === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: wine }
})
