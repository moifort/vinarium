import { Cellar } from '~/cellar/index'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })
  const config = await Cellar.updateConfig(body)
  return { status: 200, data: config }
})
