import { WineId } from '~/domain/wine/primitives'
import { WineQuery } from '~/domain/wine/query'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const detail = await WineQuery.getDetail(id)
  if (detail === 'not-found')
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: detail }
})
