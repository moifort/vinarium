import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/gift/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'

export namespace GiftQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) =>
    repository.findManyByBeverageIds(userId, beverageIds)
}
