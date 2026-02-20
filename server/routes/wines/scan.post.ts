import { Scan } from '~/domain/scan/index'

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'No image provided' })

  const result = await Scan.scanWithCache(Buffer.from(body))

  return { status: 200, data: result }
})
