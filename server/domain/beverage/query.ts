import * as repository from '~/domain/beverage/infrastructure/repository'
import type {
  Beverage,
  BeverageId,
  BeverageListMode,
  BeverageSort,
  BeverageStatusFilter,
  BeverageSubtype,
  BeverageType,
  SortOrder,
  WineColor,
} from '~/domain/beverage/types'
import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'

export type BeverageListCriteria = {
  mode: BeverageListMode
  status: BeverageStatusFilter
  sort: BeverageSort
  order: SortOrder
  limit: number
  after?: BeverageId
  color?: WineColor
  beverageType?: BeverageType
  subtype?: BeverageSubtype
}

// Cursor pagination is only safe when ordering by a field present on every
// beverage document: Firestore's orderBy silently DROPS documents missing the
// field, so paging by vintage/region/price would make beverages without them
// disappear (before pagination they showed up in the "Sans millésime/région" groups).
const CURSOR_SAFE_SORTS: readonly BeverageSort[] = ['createdAt', 'updatedAt']

export namespace BeverageQuery {
  export const findAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const byId = async (userId: UserId, id: BeverageId) => {
    const beverage = await repository.findBy(userId, id)
    if (!beverage) return 'not-found' as const
    return beverage
  }

  // Batch-load the beverages of a page by id (no full-collection scan).
  export const byBeverageIds = async (userId: UserId, beverageIds: BeverageId[]) =>
    repository.findManyByBeverageIds(userId, beverageIds)

  // A page of the beverage list, filtered and sorted per view.
  export const list = async (userId: UserId, criteria: BeverageListCriteria) => {
    const { mode, status, color, beverageType, subtype } = criteria
    const facetActive = color !== undefined || beverageType !== undefined || subtype !== undefined

    // The only truly paginated path: the unbounded default view, with no facet
    // active (facets live on the beverage document: a cursor would skip matches
    // page after page) and a sort field present on every document (see
    // CURSOR_SAFE_SORTS). Every other view is a bounded subset served in full,
    // so the client can sort and group it freely with no cross-page jumps.
    if (
      !facetActive &&
      mode === 'all' &&
      status === 'all' &&
      CURSOR_SAFE_SORTS.includes(criteria.sort)
    ) {
      const { beverages, hasMore } = await repository.findPage(userId, criteria)
      return { items: beverages, hasMore, totalCount: beverages.length }
    }

    // Everything else (satellite views, facet filters, sorts on optional
    // fields): filter the full collection in memory — facets first, on fields
    // the beverages carry themselves (color lives in the wine details), then the
    // satellite-backed status — and serve the subset in full. The client sorts
    // and groups. Every collection touched here is a memoized full scan, so the
    // request never pays it twice.
    const beverages = await repository.findAllByUser(userId)
    const candidates = await ofMode(userId, beverages, mode)
    const facetted = candidates.filter(
      (beverage) =>
        (!color || (beverage.beverageType === 'wine' && beverage.wine.color === color)) &&
        (!beverageType || beverage.beverageType === beverageType) &&
        (!subtype || beverage.subtype === subtype),
    )
    const items = await ofStatus(userId, facetted, status)
    return { items, hasMore: false, totalCount: items.length }
  }

  const ofMode = async (userId: UserId, beverages: Beverage[], mode: BeverageListMode) => {
    if (mode === 'favorites') {
      const tastings = await TastingQuery.all(userId)
      const favorites = new Set(
        tastings
          .filter((tasting) => tasting.favorite === true)
          .map((tasting) => tasting.beverageId),
      )
      return beverages.filter((beverage) => favorites.has(beverage.id))
    }
    if (mode === 'recommended') {
      const recommendations = await RecommendationQuery.all(userId)
      const recommended = new Set(
        recommendations.map((recommendation) => recommendation.beverageId),
      )
      return beverages.filter((beverage) => recommended.has(beverage.id))
    }
    if (mode === 'gifted') {
      const gifts = await GiftQuery.all(userId)
      const received = new Set(
        gifts.filter((gift) => gift.received !== undefined).map((gift) => gift.beverageId),
      )
      return beverages.filter((beverage) => received.has(beverage.id))
    }
    return beverages
  }

  const ofStatus = async (userId: UserId, beverages: Beverage[], status: BeverageStatusFilter) => {
    if (status === 'in-cellar') {
      const placed = new Set(
        (await CellarQuery.placements(userId)).map((bottle) => bottle.beverageId),
      )
      return beverages.filter((beverage) => placed.has(beverage.id))
    }
    if (status === 'consumed') {
      const tastings = await TastingQuery.all(userId)
      const consumed = new Set(
        tastings
          .filter((tasting) => tasting.consumedDate != null)
          .map((tasting) => tasting.beverageId),
      )
      return beverages.filter((beverage) => consumed.has(beverage.id))
    }
    return beverages
  }
}
