import { z } from 'zod'
import { TastingCommand } from '~/domain/tasting/command'
import { Rating } from '~/domain/tasting/primitives'
import { WineId } from '~/domain/wine/primitives'
import { WineQuery } from '~/domain/wine/query'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const wine = await WineQuery.getById(id)
  if (wine === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  const body = (await readBody(event)) ?? {}
  const note = await TastingCommand.create({
    wineId: id,
    shortlist: true,
    rating: body.rating != null ? Rating(body.rating) : undefined,
    consumedDate: body.consumedDate ? new Date(body.consumedDate) : new Date(),
    tastingNotes: body.tastingNotes ? z.string().max(1000).parse(body.tastingNotes) : undefined,
    contacts: body.contacts?.length ? body.contacts : undefined,
  })
  return { status: 200, data: note }
})
