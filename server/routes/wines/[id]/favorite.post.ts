import { TastingCommand } from '~/domain/tasting/command'
import { Rating } from '~/domain/tasting/primitives'
import { FAVORITE_RATING } from '~/domain/wine/business-rules'
import { WineId } from '~/domain/wine/primitives'
import { WineQuery } from '~/domain/wine/query'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const wine = await WineQuery.getById(id)
  if (wine === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  const note = await TastingCommand.create({ wineId: id, rating: Rating(FAVORITE_RATING) })
  return { status: 200, data: note }
})
