import type { WriteBatch } from 'firebase-admin/firestore'
import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { bulkSave } from '~/utils/firestore'

export namespace RecommendationCommand {
  export const create = async (rec: Recommendation) => repository.save(rec)

  export const removeWine = async (userId: UserId, wineId: WineId, batch?: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }

  // Wipe the user's recommendations and restore the given records (account import).
  export const replaceAllForUser = async (userId: UserId, recommendations: Recommendation[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(recommendations, repository.save)
  }
}
