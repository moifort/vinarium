import { CellarQuery } from '~/cellar/query'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const result = await CellarQuery.suggestPosition(wineId)
  if (result === 'wine-not-found')
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  if (result === 'cellar-full')
    throw createError({ statusCode: 409, statusMessage: 'Cellar is full' })
  return { status: 200, data: result }
})
