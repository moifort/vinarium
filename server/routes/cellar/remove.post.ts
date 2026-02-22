import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { PersonName } from '~/domain/shared/primitives'
import { TastingCommand } from '~/domain/tasting/command'
import { Rating } from '~/domain/tasting/primitives'
import { WineId } from '~/domain/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const error = await CellarCommand.removeWine(wineId)
  if (error === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Wine not in cellar' })

  if (body.gift) {
    await GiftCommand.giveTo({
      wineId,
      giftedDate: body.gift.giftedDate ? new Date(body.gift.giftedDate) : new Date(),
      recipientName: body.gift.recipientName ? PersonName(body.gift.recipientName) : undefined,
    })
  } else if (body.consumedDate || body.rating != null || body.tastingNotes) {
    await TastingCommand.create({
      wineId,
      consumedDate: body.consumedDate ? new Date(body.consumedDate) : undefined,
      rating: body.rating != null ? Rating(body.rating) : undefined,
      tastingNotes: body.tastingNotes ? body.tastingNotes : undefined,
      contacts: body.contacts?.length ? body.contacts : undefined,
    })
  }

  return { status: 200, data: { ok: true } }
})
