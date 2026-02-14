import { Wines } from '~/wine/index'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const wine = await Wines.getById(id)
  if (wine === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, data: wine }
})
