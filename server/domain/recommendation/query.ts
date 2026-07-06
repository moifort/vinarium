import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace RecommendationQuery {
  export const getAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const getManyByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)
}
