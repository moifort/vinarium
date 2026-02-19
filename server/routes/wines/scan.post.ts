import { Scan } from '~/domain/scan/index'

export default defineEventHandler(async (event) => {
  const body = await readRawBody(event, false)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'No image provided' })

  const scanResult = await Scan.scanLabel(Buffer.from(body))
  const enriched = await Scan.enrichWithSearch(scanResult)

  return { status: 200, data: enriched }
})
