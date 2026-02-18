import { CellarCommand } from '~/domain/cellar/command'
import { WineCommand } from '~/domain/wine/command'
import { WineId } from '~/domain/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const error = await WineCommand.remove(id)
  if (error === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  await CellarCommand.removeWine(id)
  return { status: 200, message: 'Wine deleted' }
})
