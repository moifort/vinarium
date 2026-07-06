import type { WriteBatch } from 'firebase-admin/firestore'
import * as repository from '~/domain/gift/infrastructure/repository'
import type { Gift } from '~/domain/gift/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { bulkSave } from '~/utils/firestore'

export namespace GiftCommand {
  export const giveTo = async (gift: Gift) => repository.save(gift)

  export const removeWine = async (userId: UserId, wineId: WineId, batch?: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }

  // Wipe the user's gifts and restore the given records (account import).
  export const replaceAllForUser = async (userId: UserId, gifts: Gift[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(gifts, repository.save)
  }
}
