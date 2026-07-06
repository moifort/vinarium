import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/tasting/infrastructure/repository'

export namespace TastingQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) =>
    repository.findManyByBeverageIds(userId, beverageIds)
}
