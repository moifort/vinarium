import { WineId } from '~/domain/wine/primitives'
import { WineUseCase } from '~/domain/wine/use-case'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const error = await WineUseCase.removeCompletely(id)
  if (error === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  return { status: 200, message: 'Wine deleted' }
})
