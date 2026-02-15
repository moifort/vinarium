import { AI } from '~/ai/index'

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'No image provided' })

  const scanResult = await AI.scanLabel(Buffer.from(body))
  const enriched = await AI.enrichWithSearch(scanResult)

  return { status: 200, data: enriched }
})
