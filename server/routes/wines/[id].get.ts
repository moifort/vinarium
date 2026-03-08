import { WineId } from '~/domain/wine/primitives'
import { WineDetailReadModel } from '~/read-model/wine/wine-detail'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const detail = await WineDetailReadModel.byId(id)
  if (detail === 'not-found')
    throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: detail }
})
