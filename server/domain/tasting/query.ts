import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/tasting/infrastructure/repository'
import type { WineId } from '~/domain/wine/types'

export namespace TastingQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)
}
