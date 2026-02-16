import { CellarCommand } from '~/cellar/command'
import { TastingCommand } from '~/tasting/command'
import { Rating } from '~/tasting/primitives'
import { WineId } from '~/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const error = await CellarCommand.removeWine(wineId)
  if (error === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Wine not in cellar' })

  if (body.consumedDate || body.rating != null || body.tastingNotes) {
    await TastingCommand.create({
      wineId,
      consumedDate: body.consumedDate ? new Date(body.consumedDate) : undefined,
      rating: body.rating != null ? Rating(body.rating) : undefined,
      tastingNotes: body.tastingNotes as string | undefined,
    })
  }

  return { status: 200, data: { ok: true } }
})
