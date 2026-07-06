import type { WriteBatch } from 'firebase-admin/firestore'
import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import { bulkSave } from '~/utils/firestore'

export namespace RecommendationCommand {
  export const create = async (rec: Recommendation) => repository.save(rec)

  export const removeBeverage = async (
    userId: UserId,
    beverageId: BeverageId,
    batch?: WriteBatch,
  ) => {
    await repository.remove(userId, beverageId, batch)
  }

  // Wipe the user's recommendations and restore the given records (account import).
  export const replaceAllForUser = async (userId: UserId, recommendations: Recommendation[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(recommendations, repository.save)
  }
}
