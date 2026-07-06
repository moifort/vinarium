import { CellarCommand } from '~/domain/cellar/command'
import { GiftCommand } from '~/domain/gift/command'
import { JournalCommand } from '~/domain/journal/command'
import { RecommendationCommand } from '~/domain/recommendation/command'
import type { PersonName, UserId } from '~/domain/shared/types'
import { TastingCommand } from '~/domain/tasting/command'
import { WineCommand } from '~/domain/wine/command'
import type { BeverageType, WineId, WineName } from '~/domain/wine/types'
import { atomically } from '~/utils/firestore'

type WineData = Parameters<typeof WineCommand.add>[3]

export namespace WineUseCase {
  // Add a wine and, when its provenance is known, record who gave it (the
  // giftedBy field lives in the gift domain — a wine only carries what it is).
  export const add = async (
    userId: UserId,
    name: WineName,
    beverageType: BeverageType,
    data: WineData,
    receivedFrom?: PersonName,
  ) => {
    const result = await WineCommand.add(userId, name, beverageType, data)
    if (typeof result !== 'string' && receivedFrom)
      await GiftCommand.receiveFrom(userId, result.id, receivedFrom)
    return result
  }

  export const update = async (
    userId: UserId,
    id: WineId,
    data: Parameters<typeof WineCommand.update>[2],
    receivedFrom?: PersonName,
  ) => {
    const result = await WineCommand.update(userId, id, data)
    if (typeof result !== 'string' && receivedFrom)
      await GiftCommand.receiveFrom(userId, id, receivedFrom)
    return result
  }

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
