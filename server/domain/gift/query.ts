import * as repository from '~/domain/gift/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace GiftQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)
}
