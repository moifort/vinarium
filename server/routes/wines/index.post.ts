import { z } from 'zod'
import { Country, Eur, Region, Year } from '~/shared/primitives'
import { WineCommand } from '~/wine/command'
import { Appellation, Classification, WineDomain, WineName } from '~/wine/primitives'
import type { Wine } from '~/wine/types'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const name = WineName(body.name)
  const color = z.enum(['red', 'white', 'rosé', 'sparkling', 'sweet']).parse(body.color)

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

  const wine = await WineCommand.add(name, color, data)
  return { status: 201, data: wine }
})
