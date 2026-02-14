import { Cellar } from '~/cellar/index'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const result = await Cellar.removeWine(wineId)
  if (result === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Wine not in cellar' })
  return { status: 200, data: result }
})
