import * as repository from '~/domain/gift/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace GiftQuery {
  export const getAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const getManyByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)

  export const getByWineId = async (userId: UserId, wineId: WineId) => {
    const gift = await repository.findBy(userId, wineId)
    if (!gift) return 'not-found' as const
    return gift
  }
}
