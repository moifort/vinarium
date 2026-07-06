import { CellarQuery } from '~/domain/cellar/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import * as repository from '~/domain/wine/infrastructure/repository'
import type {
  BeverageSubtype,
  BeverageType,
  SortOrder,
  Wine,
  WineColor,
  WineId,
  WineListMode,
  WineSort,
  WineStatusFilter,
} from '~/domain/wine/types'

export type WineListCriteria = {
  mode: WineListMode
  status: WineStatusFilter
  sort: WineSort
  order: SortOrder
  limit: number
  after?: WineId
  color?: WineColor
  beverageType?: BeverageType
  subtype?: BeverageSubtype
}

// Cursor pagination is only safe when ordering by a field present on every wine
// document: Firestore's orderBy silently DROPS documents missing the field, so
// paging by vintage/region/price would make wines without them disappear
// (before pagination they showed up in the "Sans millésime/région" groups).
const CURSOR_SAFE_SORTS: readonly WineSort[] = ['createdAt', 'updatedAt']

export namespace WineQuery {
  export const findAll = async (userId: UserId) => repository.findAllByUser(userId)

  export const byId = async (userId: UserId, id: WineId) => {
    const wine = await repository.findBy(userId, id)
    if (!wine) return 'not-found' as const
    return wine
  }

  // Batch-load the wines of a page by id (no full-collection scan).
  export const byWineIds = async (userId: UserId, wineIds: WineId[]) =>
    repository.findManyByWineIds(userId, wineIds)

  // A page of the wine list, filtered and sorted per view.
  export const list = async (userId: UserId, criteria: WineListCriteria) => {
    const { mode, status, color, beverageType, subtype } = criteria
    const facetActive = color !== undefined || beverageType !== undefined || subtype !== undefined

    // The only truly paginated path: the unbounded default view, with no facet
    // active (facets live on the wine document: a cursor would skip matches page
    // after page) and a sort field present on every document (see
    // CURSOR_SAFE_SORTS). Every other view is a bounded subset served in full,
    // so the client can sort and group it freely with no cross-page jumps.
    if (
      !facetActive &&
      mode === 'all' &&
      status === 'all' &&
      CURSOR_SAFE_SORTS.includes(criteria.sort)
    ) {
      const { wines, hasMore } = await repository.findPage(userId, criteria)
      return { items: wines, hasMore, totalCount: wines.length }
    }

    // Everything else (satellite views, facet filters, sorts on optional
    // fields): filter the full collection in memory — facets first, on fields
    // the wines carry themselves, then the satellite-backed status — and serve
    // the subset in full. The client sorts and groups. Every collection touched
    // here is a memoized full scan, so the request never pays it twice.
    const wines = await repository.findAllByUser(userId)
    const candidates = await ofMode(userId, wines, mode)
    const facetted = candidates.filter(
      (wine) =>
        (!color || wine.color === color) &&
        (!beverageType || wine.beverageType === beverageType) &&
        (!subtype || wine.subtype === subtype),
    )
    const items = await ofStatus(userId, facetted, status)
    return { items, hasMore: false, totalCount: items.length }
  }

  const ofMode = async (userId: UserId, wines: Wine[], mode: WineListMode) => {
    if (mode === 'favorites') {
      const tastings = await TastingQuery.all(userId)
      const favorites = new Set(
        tastings.filter((tasting) => tasting.favorite === true).map((tasting) => tasting.wineId),
      )
      return wines.filter((wine) => favorites.has(wine.id))
    }
    if (mode === 'recommended') {
      const recommendations = await RecommendationQuery.all(userId)
      const recommended = new Set(recommendations.map((recommendation) => recommendation.wineId))
      return wines.filter((wine) => recommended.has(wine.id))
    }
    if (mode === 'gifted') return wines.filter((wine) => wine.giftedBy !== undefined)
    return wines
  }

  const ofStatus = async (userId: UserId, wines: Wine[], status: WineStatusFilter) => {
    if (status === 'in-cellar') {
      const placed = new Set((await CellarQuery.placements(userId)).map((bottle) => bottle.wineId))
      return wines.filter((wine) => placed.has(wine.id))
    }
    if (status === 'consumed') {
      const tastings = await TastingQuery.all(userId)
      const consumed = new Set(
        tastings.filter((tasting) => tasting.consumedDate != null).map((tasting) => tasting.wineId),
      )
      return wines.filter((wine) => consumed.has(wine.id))
    }
    return wines
  }
}
