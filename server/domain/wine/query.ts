import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/wine/infrastructure/repository'
import type { WineId } from '~/domain/wine/types'

export namespace WineQuery {
  export const findAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const getById = async (userId: UserId, id: WineId) => {
    const wine = await repository.findBy(userId, id)
    if (!wine) return 'not-found' as const
    return wine
  }
}
