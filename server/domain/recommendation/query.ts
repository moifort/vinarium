import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/recommendation/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'

export namespace RecommendationQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  // Recommendations are sparse (a handful of records per user), so filtering the
  // memoized full scan beats a keyed getAll: one query costing #recommendations
  // reads for the whole request, instead of one billed lookup per beverage on
  // every page.
  export const byBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) => {
    if (beverageIds.length === 0) return []
    const wanted = new Set(beverageIds)
    return (await repository.findAllByUser(userId)).filter((recommendation) =>
      wanted.has(recommendation.beverageId),
    )
  }
}
