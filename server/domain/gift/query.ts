import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/gift/infrastructure/repository'
import type { UserId } from '~/domain/shared/types'

// Up to this many wines, keyed lookups cost less than the scan of a user's records.
const KEYED_LOOKUP_MAX = 4

export namespace GiftQuery {
  export const all = async (userId: UserId) => repository.findAllByUser(userId)

  export const byBeverage = async (userId: UserId, beverageId: BeverageId) =>
    repository.findBy(userId, beverageId)

  // Gifts are sparse (a handful of records per user, a few dozen at most), so
  // a page of wines filters the memoized full scan: one query costing #gifts
  // reads for the whole request, instead of one billed lookup per wine. A wine's
  // sheet asks for one: there, a keyed lookup is one read where the scan is all
  // of them (about thirty a sheet in production on 2026-11-15).
  export const byBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) => {
    if (beverageIds.length === 0) return []
    if (beverageIds.length <= KEYED_LOOKUP_MAX)
      return repository.findManyByBeverageIds(userId, beverageIds)
    const wanted = new Set(beverageIds)
    return (await repository.findAllByUser(userId)).filter(({ beverageId }) =>
      wanted.has(beverageId),
    )
  }
}
