import { CellarQuery } from '~/cellar/query'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const wineId = WineId(getRouterParam(event, 'wineId'))
  const entry = await CellarQuery.getEntryByWineId(wineId)
  if (!entry) throw createError({ statusCode: 404, statusMessage: 'No cellar entry for this wine' })
  return { status: 200, data: entry }
})
