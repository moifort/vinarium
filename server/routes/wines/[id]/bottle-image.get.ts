import { WineId } from '~/domain/wine/primitives'
import * as bottleImageRepo from '~/system/bottle-image/repository'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const imageBase64 = await bottleImageRepo.findBy(id)
  if (!imageBase64) throw createError({ statusCode: 404, statusMessage: 'Bottle image not found' })

  const buffer = Buffer.from(imageBase64, 'base64')
  setResponseHeaders(event, {
    'Content-Type': 'image/png',
    'Cache-Control': 'public, max-age=86400',
    'Content-Length': buffer.length.toString(),
  })
  return buffer
})
