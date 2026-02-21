import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { JournalCommand } from '~/domain/journal/command'
import { RecommendationCommand } from '~/domain/recommendation/command'
import { TastingCommand } from '~/domain/tasting/command'
import { WineCommand } from '~/domain/wine/command'
import { WineId } from '~/domain/wine/primitives'

export default defineEventHandler(async (event) => {
  const id = WineId(getRouterParam(event, 'id'))
  const error = await WineCommand.remove(id)
  if (error === 'not-found') throw createError({ statusCode: 404, statusMessage: 'Wine not found' })
  await Promise.all([
    CellarCommand.removeWine(id),
    TastingCommand.removeWine(id),
    GiftCommand.removeWine(id),
    RecommendationCommand.removeWine(id),
  ])
  // Sequential: CellarCommand.removeWine creates a journal "out" entry that also needs cleanup
  await JournalCommand.removeWine(id)
  return { status: 200, message: 'Wine deleted' }
})
