import { Cellar } from '~/cellar/index'
import { UserLog } from '~/user-log/index'
import { Rating } from '~/user-log/primitives'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const result = await Cellar.removeWine(wineId)
  if (result === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Wine not in cellar' })

  if (body.consumedDate || body.rating != null || body.tastingNotes) {
    await UserLog.create({
      wineId,
      consumedDate: body.consumedDate ? new Date(body.consumedDate) : undefined,
      rating: body.rating != null ? Rating(body.rating) : undefined,
      tastingNotes: body.tastingNotes as string | undefined,
    })
  }

  return { status: 200, data: { ok: true } }
})
