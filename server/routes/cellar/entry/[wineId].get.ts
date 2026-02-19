import { CellarQuery } from '~/domain/cellar/query'
import { WineId } from '~/domain/wine/primitives'

export default defineEventHandler(async (event) => {
  const wineId = WineId(getRouterParam(event, 'wineId'))
  const bottle = await CellarQuery.getBottleByWineId(wineId)
  if (bottle === 'not-found')
    throw createError({ statusCode: 404, statusMessage: 'No cellar bottle for this wine' })
  return { status: 200, data: bottle }
})
