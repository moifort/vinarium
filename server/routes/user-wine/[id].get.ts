import { UserWine } from '~/user-wine/index'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const detail = await UserWine.getDetail(id)
  if (detail === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: detail }
})
