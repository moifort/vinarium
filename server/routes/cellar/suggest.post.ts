import { CellarQuery } from '~/cellar/query'

export default defineEventHandler(async () => {
  const result = await CellarQuery.suggestPosition()
  if (result === 'cellar-full')
    throw createError({ statusCode: 409, statusMessage: 'Cellar is full' })
  return { status: 200, data: result }
})
