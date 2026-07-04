import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace RecommendationQuery {
  export const getAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const getManyByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)

  export const getByWineId = async (userId: UserId, wineId: WineId) => {
    const rec = await repository.findBy(userId, wineId)
    if (!rec) return 'not-found' as const
    return rec
  }
}
