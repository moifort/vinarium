import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'

export namespace RecommendationQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) =>
    repository.findManyByBeverageIds(userId, beverageIds)
}
