import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { JournalCommand } from '~/domain/journal/command'
import { RecommendationCommand } from '~/domain/recommendation/command'
import { TastingCommand } from '~/domain/tasting/command'
import { WineCommand } from '~/domain/wine/command'
import type { Wine, WineColor, WineId, WineName } from '~/domain/wine/types'

export namespace WineUseCase {
  export const addWithTasting = async (
    name: WineName,
    color: WineColor,
    data: Partial<Wine>,
    tasting?: Omit<Parameters<typeof TastingCommand.create>[0], 'wineId'>,
  ) => {
    const wine = await WineCommand.add(name, color, data)
    if (tasting) {
      await TastingCommand.create({ wineId: wine.id, ...tasting })
    }
    return wine
  }

  export const removeCompletely = async (id: WineId) => {
    const error = await WineCommand.remove(id)
    if (error === 'not-found') return 'not-found' as const
    await Promise.all([
      CellarCommand.removeWine(id),
      TastingCommand.removeWine(id),
      GiftCommand.removeWine(id),
      RecommendationCommand.removeWine(id),
    ])
    // Sequential: CellarCommand.removeWine creates a journal "out" entry that also needs cleanup
    await JournalCommand.removeWine(id)
    return undefined
  }
}
