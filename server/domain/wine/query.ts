import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/wine/infrastructure/repository'
import type { SortOrder, WineId, WineSort } from '~/domain/wine/types'

export namespace WineQuery {
  export const findAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const getById = async (userId: UserId, id: WineId) => {
    const wine = await repository.findBy(userId, id)
    if (!wine) return 'not-found' as const
    return wine
  }

  // One page of wine ids for the default "Tous" view, ordered by the chosen field.
  export const page = async (
    userId: UserId,
    args: { limit: number; after?: WineId; sort: WineSort; order: SortOrder },
  ) => repository.findPage(userId, args)

  // Batch-load the wines of a page by id (no full-collection scan).
  export const getManyByWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)
}
