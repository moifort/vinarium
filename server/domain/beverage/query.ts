import { sortBy } from 'lodash-es'
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
import { HouseholdQuery } from '~/domain/household/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import { memoizedPerRequest } from '~/system/request-cache'

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

  // The wines the viewer may see in their library and search: their own full
  // library, plus any household member's wine currently placed in the shared
  // cellar. A housemate's out-of-cellar wines (consumed, wishlist) stay private.
  // Memoized so the list, search and count paths share one merge per request.
  // Reads the whole library: reserved for the views that must see every wine.
  export const allVisibleTo = (userId: UserId): Promise<Beverage[]> =>
    memoizedPerRequest(`beverages:visible:${userId}`, async () => {
      const [own, housemateWines] = await Promise.all([
        repository.findAllByUser(userId),
        housematesCellarWines(userId),
      ])
      return [...own, ...housemateWines]
    })

  // The housemates' wines placed in the shared cellar — bounded by the grid,
  // never by their libraries. Empty for a solo viewer, at no read.
  const housematesCellarWines = (userId: UserId): Promise<Beverage[]> =>
    memoizedPerRequest(`beverages:housemates-cellar:${userId}`, async () => {
      const scope = await HouseholdQuery.cellarScope(userId)
      if (scope.memberIds.length === 1) return []
      const housemates = scope.memberIds.filter((id) => id !== userId)
      const housemateSet = new Set(housemates)
      const placedByHousemates = (await CellarQuery.householdPlacements(userId))
        .filter((bottle) => housemateSet.has(bottle.userId))
        .map((bottle) => bottle.beverageId)
      return repository.findManyByBeverageIdsForUsers(housemates, placedByHousemates)
    })

  // The owner's beverages carrying at least one of the given search terms. The
  // search domain decides what a term is, the beverage domain owns the lookup.
  export const bySearchTerms = async (ownerId: UserId, terms: string[]) =>
    repository.findBySearchTerms(ownerId, terms)

  export const byId = async (userId: UserId, id: BeverageId) => {
    const beverage = await repository.findBy(userId, id)
    if (!beverage) return 'not-found' as const
    return beverage
  }

  // A beverage the viewer is allowed to see: their own, or a household member's
  // (so a shared-cellar bottle opens its wine detail). Anything else is not-found.
  export const byIdForViewer = async (viewerId: UserId, id: BeverageId) => {
    const beverage = await repository.findById(id)
    if (!beverage) return 'not-found' as const
    if (beverage.userId === viewerId) return beverage
    const scope = await HouseholdQuery.cellarScope(viewerId)
    return scope.memberIds.includes(beverage.userId) ? beverage : ('not-found' as const)
  }

  // Batch-load a page of shared-cellar wines owned by any household member.
  export const byBeverageIdsForUsers = async (memberIds: UserId[], beverageIds: BeverageId[]) =>
    repository.findManyByBeverageIdsForUsers(memberIds, beverageIds)

  // A page of the beverage list, filtered and sorted per view.
  export const list = async (userId: UserId, criteria: BeverageListCriteria) => {
    const { mode, status, color, beverageType, subtype } = criteria
    const facetActive = color !== undefined || beverageType !== undefined || subtype !== undefined

    if (!facetActive && mode === 'all' && status === 'all') {
      // The only truly paginated path: the unbounded default view, sorted on a
      // field present on every document (see CURSOR_SAFE_SORTS).
      if (CURSOR_SAFE_SORTS.includes(criteria.sort)) return pageVisibleTo(userId, criteria)
      // A sort on an optional field (vintage, region, price…) ranks every wine,
      // those missing the field included: Firestore's orderBy would drop them,
      // so this view alone reads the whole library and lets the client sort.
      const items = await allVisibleTo(userId)
      return { items, hasMore: false, totalCount: items.length }
    }

    // Every other view is a bounded subset served in full, so the client can
    // sort and group it freely. It is read at the storage, never carved out of
    // the whole library: the satellites name the wines of a mode or a status,
    // a facet is a term written on the wine itself. Satellite modes filter by the
    // VIEWER's own records, so a housemate's cellar wine only surfaces there once
    // the viewer has favorited/received it themselves.
    const subset = await subsetOf(userId, mode, status)
    const candidates =
      subset === undefined
        ? await facetCandidates(userId, criteria)
        : await visibleAmong(userId, [...subset])
    const items = sortBy(
      candidates.filter(
        (beverage) =>
          (!color || (beverage.beverageType === 'wine' && beverage.wine.color === color)) &&
          (!beverageType || beverage.beverageType === beverageType) &&
          (!subtype || beverage.subtype === subtype),
      ),
      (beverage) => -beverage.createdAt.getTime(),
    )
    return { items, hasMore: false, totalCount: items.length }
  }

  // One page of the viewer's library merged with the housemates' cellar wines.
  // Firestore pages the viewer's own wines (a bounded limit+1 read, resumed after
  // the cursor whoever owns it); the housemates' wines — a handful bounded by the
  // grid — are placed around them in memory, in the same order Firestore uses
  // (sort value, then id). A cursor that no longer exists restarts from the top,
  // as Firestore does.
  const pageVisibleTo = async (userId: UserId, criteria: BeverageListCriteria) => {
    const { sort, order, limit } = criteria
    const [own, housemateWines] = await Promise.all([
      repository.findPage(userId, criteria),
      housematesCellarWines(userId),
    ])
    if (housemateWines.length === 0) {
      return { items: own.beverages, hasMore: own.hasMore, totalCount: own.beverages.length }
    }
    const time = (beverage: Beverage) =>
      (sort === 'updatedAt' ? beverage.updatedAt : beverage.createdAt).getTime()
    const compare = (a: Beverage, b: Beverage) => {
      const delta = time(a) - time(b) || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0)
      return order === 'desc' ? -delta : delta
    }
    const cursor = own.cursor
    const merged = [
      ...own.beverages,
      ...housemateWines.filter((beverage) => !cursor || compare(beverage, cursor) > 0),
    ].sort(compare)
    const items = merged.slice(0, limit)
    return { items, hasMore: own.hasMore || merged.length > limit, totalCount: items.length }
  }

  // The wines a mode and a status single out, as ids read from the satellites —
  // the intersection when both apply, undefined when neither does.
  const subsetOf = async (userId: UserId, mode: BeverageListMode, status: BeverageStatusFilter) => {
    const [ofMode, ofStatus] = await Promise.all([
      idsOfMode(userId, mode),
      idsOfStatus(userId, status),
    ])
    if (!ofMode) return ofStatus
    if (!ofStatus) return ofMode
    return new Set([...ofMode].filter((id) => ofStatus.has(id)))
  }

  // Wines by id, kept when the viewer may see them: their own, or a housemate's
  // placed in the shared cellar.
  const visibleAmong = async (userId: UserId, beverageIds: BeverageId[]) => {
    const scope = await HouseholdQuery.cellarScope(userId)
    const wines = await repository.findManyByBeverageIdsForUsers(scope.memberIds, beverageIds)
    if (wines.every((wine) => wine.userId === userId)) return wines
    const placed = new Set(
      (await CellarQuery.householdPlacements(userId)).map(({ beverageId }) => beverageId),
    )
    return wines.filter((wine) => wine.userId === userId || placed.has(wine.id))
  }

  // A facet-only view: the viewer's wines carrying the most selective facet term,
  // plus the housemates' cellar wines; the other facets are settled by the caller.
  const facetCandidates = async (userId: UserId, criteria: BeverageListCriteria) => {
    const { color, beverageType, subtype } = criteria
    const term = subtype ? `subtype:${subtype}` : color ? `color:${color}` : `type:${beverageType}`
    const [own, housemateWines] = await Promise.all([
      repository.findByTerm(userId, term),
      housematesCellarWines(userId),
    ])
    return [...own, ...housemateWines]
  }

  const idsOfMode = async (userId: UserId, mode: BeverageListMode) => {
    if (mode === 'favorites') {
      return new Set((await TastingQuery.favorites(userId)).map(({ beverageId }) => beverageId))
    }
    if (mode === 'recommended') {
      return new Set((await RecommendationQuery.all(userId)).map(({ beverageId }) => beverageId))
    }
    if (mode === 'gifted') {
      return new Set(
        (await GiftQuery.all(userId))
          .filter((gift) => gift.received !== undefined)
          .map(({ beverageId }) => beverageId),
      )
    }
    return undefined
  }

  const idsOfStatus = async (userId: UserId, status: BeverageStatusFilter) => {
    if (status === 'in-cellar') {
      return new Set(
        (await CellarQuery.householdPlacements(userId)).map(({ beverageId }) => beverageId),
      )
    }
    if (status === 'consumed') {
      return new Set(
        (await TastingQuery.all(userId))
          .filter((tasting) => tasting.consumedDate != null)
          .map(({ beverageId }) => beverageId),
      )
    }
    return undefined
  }
}
