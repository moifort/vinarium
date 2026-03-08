import type { RemovalReason } from '~/domain/cellar/use-case'
import { CellarUseCase } from '~/domain/cellar/use-case'
import { PersonName } from '~/domain/shared/primitives'
import { Rating } from '~/domain/tasting/primitives'
import { WineId } from '~/domain/wine/primitives'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  if (!body) throw createError({ statusCode: 400, statusMessage: 'Body is required' })

  const wineId = WineId(body.wineId)
  const reason = parseRemovalReason(body)
  const error = await CellarUseCase.removeBottle(wineId, reason)
  if (error === 'not-in-cellar')
    throw createError({ statusCode: 404, statusMessage: 'Wine not in cellar' })

  return { status: 200, data: { ok: true } }
})

// biome-ignore lint/suspicious/noExplicitAny: raw HTTP body
const parseRemovalReason = (body: any): RemovalReason | undefined => {
  if (body.gift) {
    return {
      type: 'gift',
      giftedDate: body.gift.giftedDate ? new Date(body.gift.giftedDate) : new Date(),
      recipientName: body.gift.recipientName ? PersonName(body.gift.recipientName) : undefined,
    }
  }
  if (body.consumedDate || body.rating != null || body.tastingNotes) {
    return {
      type: 'tasting',
      consumedDate: body.consumedDate ? new Date(body.consumedDate) : undefined,
      rating: body.rating != null ? Rating(body.rating) : undefined,
      tastingNotes: body.tastingNotes ? body.tastingNotes : undefined,
      contacts: body.contacts?.length ? body.contacts : undefined,
    }
  }
  return undefined
}
