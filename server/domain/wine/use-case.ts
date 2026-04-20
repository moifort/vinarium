import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { JournalCommand } from '~/domain/journal/command'
import { RecommendationCommand } from '~/domain/recommendation/command'
import type { UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import { WineCommand } from '~/domain/wine/command'
import type { Wine, WineColor, WineId, WineName } from '~/domain/wine/types'

export namespace WineUseCase {
  export const addWithTasting = async (
    userId: UserId,
    name: WineName,
    color: WineColor,
    data: Partial<Omit<Wine, 'id' | 'userId' | 'name' | 'color' | 'createdAt' | 'updatedAt'>>,
    tasting?: Omit<Parameters<typeof TastingCommand.create>[0], 'wineId' | 'userId'>,
  ) => {
    const wine = await WineCommand.add(userId, name, color, data)
    if (tasting) await TastingCommand.create({ userId, wineId: wine.id, ...tasting })
    return wine
  }

  export const removeCompletely = async (userId: UserId, id: WineId) => {
    const error = await WineCommand.remove(userId, id)
    if (error === 'not-found') return 'not-found' as const
    await Promise.all([
      CellarCommand.removeWine(userId, id),
      TastingCommand.removeWine(userId, id),
      GiftCommand.removeWine(userId, id),
      RecommendationCommand.removeWine(userId, id),
    ])
    // Sequential: CellarCommand.removeWine creates a journal "out" entry that also needs cleanup
    await JournalCommand.removeWine(userId, id)
    return undefined
  }
}
