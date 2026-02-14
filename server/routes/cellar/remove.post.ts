import { Cellar } from '~/cellar/index'
import { Rating } from '~/cellar/primitives'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const consumption = {
    consumedDate: body.consumedDate ? new Date(body.consumedDate) : undefined,
    rating: body.rating != null ? Rating(body.rating) : undefined,
    tastingNotes: body.tastingNotes as string | undefined,
  }
  const result = await Cellar.removeWine(wineId, consumption)
  if (result === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Wine not in cellar' })
  return { status: 200, data: result }
})
