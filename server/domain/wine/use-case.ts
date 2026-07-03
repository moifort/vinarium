import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { JournalCommand } from '~/domain/journal/command'
import { RecommendationCommand } from '~/domain/recommendation/command'
import type { UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import { WineCommand } from '~/domain/wine/command'
import type { WineId } from '~/domain/wine/types'
import { atomically } from '~/utils/firestore'

export namespace WineUseCase {
  export const removeCompletely = async (userId: UserId, id: WineId) =>
    await atomically(async (batch) => {
      const error = await WineCommand.remove(userId, id, batch)
      if (error === 'not-found') return 'not-found' as const
      // Every domain enlists its deletions into the same batch: the wine and all
      // related entries vanish together or not at all. CellarCommand.eraseWine
      // skips bottle-out journaling because the wine's whole journal is wiped here.
      await Promise.all([
        CellarCommand.eraseWine(userId, id, batch),
        TastingCommand.removeWine(userId, id, batch),
        GiftCommand.removeWine(userId, id, batch),
        RecommendationCommand.removeWine(userId, id, batch),
        JournalCommand.removeWine(userId, id, batch),
      ])
      return undefined
    })
}
