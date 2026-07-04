import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/tasting/infrastructure/repository'
import type { WineId } from '~/domain/wine/types'

export namespace TastingQuery {
  export const getAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const getManyByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)

  export const getByWineId = async (userId: UserId, wineId: WineId) => {
    const note = await repository.findBy(userId, wineId)
    if (!note) return 'not-found' as const
    return note
  }
}
