import { AI } from '~/ai/index'

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'No image provided' })
  const result = await AI.scanLabel(Buffer.from(body))
  return { status: 200, data: result }
})
