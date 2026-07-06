import type { WriteBatch } from 'firebase-admin/firestore'
import * as repository from '~/domain/gift/infrastructure/repository'
import type { Gift, GiftGiven } from '~/domain/gift/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { bulkSave } from '~/utils/firestore'

export namespace GiftCommand {
  // Record that the bottle was given away, preserving any received-from facet.
  export const giveTo = async (userId: UserId, wineId: WineId, given: GiftGiven) => {
    const existing = await repository.findBy(userId, wineId)
    return repository.save({ ...(existing ?? { userId, wineId }), given })
  }

  // Record who gave the bottle to us, preserving any given-away facet.
  export const receiveFrom = async (userId: UserId, wineId: WineId, from: PersonName) => {
    const existing = await repository.findBy(userId, wineId)
    return repository.save({ ...(existing ?? { userId, wineId }), received: { from } })
  }

  export const removeWine = async (userId: UserId, wineId: WineId, batch?: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }

  // Wipe the user's gifts and restore the given records (account import).
  export const replaceAllForUser = async (userId: UserId, gifts: Gift[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(gifts, repository.save)
  }
}
