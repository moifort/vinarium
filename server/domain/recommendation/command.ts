import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace RecommendationCommand {
  export const create = async (rec: Recommendation) => repository.save(rec)

  export const removeWine = async (userId: UserId, wineId: WineId) => {
    await repository.remove(userId, wineId)
  }
}
