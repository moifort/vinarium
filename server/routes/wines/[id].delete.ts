import { Cellar } from '~/cellar/index'
import { Wines } from '~/wine/index'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const error = await Wines.remove(id)
  if (error === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  await Cellar.removeWine(id)
  return { status: 200, message: 'Wine deleted' }
})
