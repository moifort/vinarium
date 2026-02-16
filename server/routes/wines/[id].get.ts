import { WineId } from '~/wine/primitives'
import { WineQuery } from '~/wine/query'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const detail = await WineQuery.getDetail(id)
  if (detail === 'not-found')
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: detail }
})
