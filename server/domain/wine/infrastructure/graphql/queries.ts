import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import { builder } from '~/domain/shared/graphql/builder'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import { WineQuery } from '../../query'
import type {
  BeverageSubtype,
  BeverageType,
  WineColor,
  WineId,
  WineListMode,
  WineStatusFilter,
} from '../../types'
import {
  BeverageSubtypeEnum,
  BeverageTypeEnum,
  SortOrderEnum,
  WineColorEnum,
  WineListModeEnum,
  WineSortEnum,
  WineStatusFilterEnum,
} from './enums'
import { type WineListItem, WinesType, WineType } from './types'

const indexByWineId = <T extends { wineId: WineId }>(records: T[]) =>
  new Map(records.map((record) => [record.wineId, record]))

// Load the wines of a page plus their satellites (each batched by id) and attach
// them, preserving the page order. Attached satellites let the WineType field
// resolvers skip the per-request fallback query entirely.
const assemble = async (userId: UserId, wineIds: WineId[]): Promise<WineListItem[]> => {
  const [wines, placements, tastings, gifts, recommendations] = await Promise.all([
    WineQuery.getManyByWineIds(userId, wineIds),
    CellarQuery.getPlacementsByWineIds(userId, wineIds),
    TastingQuery.getManyByWineIds(userId, wineIds),
    GiftQuery.getManyByWineIds(userId, wineIds),
    RecommendationQuery.getManyByWineIds(userId, wineIds),
  ])
  const cellar = indexByWineId(placements)
  const consumption = indexByWineId(tastings)
  const gift = indexByWineId(gifts)
  const recommendation = indexByWineId(recommendations)
  const byId = new Map(wines.map((wine) => [wine.id, wine]))
  return wineIds
    .map((id) => byId.get(id))
    .filter((wine): wine is (typeof wines)[number] => wine !== undefined)
    .map((wine) => ({
      ...wine,
      cellar: cellar.get(wine.id) ?? null,
      consumption: consumption.get(wine.id) ?? null,
      gift: gift.get(wine.id) ?? null,
      recommendation: recommendation.get(wine.id) ?? null,
    }))
}

// Candidate wine ids for a view, loaded in full (no cursor). The satellite views
// (favorites, gifted, recommended) are small subsets; status and facet filters
// are applied after assembly, so they work uniformly on every view.
const candidateWineIds = async (userId: UserId, mode: WineListMode): Promise<WineId[]> => {
  if (mode === 'favorites') {
    const tastings = await TastingQuery.getAll(userId)
    return tastings.filter((tasting) => tasting.favorite === true).map((tasting) => tasting.wineId)
  }
  if (mode === 'recommended') {
    const recommendations = await RecommendationQuery.getAll(userId)
    return recommendations.map((recommendation) => recommendation.wineId)
  }
  if (mode === 'gifted') {
    const wines = await WineQuery.findAll(userId)
    return wines.filter((wine) => wine.giftedBy !== undefined).map((wine) => wine.id)
  }
  const wines = await WineQuery.findAll(userId)
  return wines.map((wine) => wine.id)
}

const matchesStatus = (item: WineListItem, status: WineStatusFilter) => {
  if (status === 'in-cellar') return item.cellar != null
  if (status === 'consumed') return item.consumption?.consumedDate != null
  return true
}

// Cursor pagination is only safe when ordering by a field present on every wine
// document: Firestore's orderBy silently DROPS documents missing the field, so
// paging by vintage/region/price would make wines without them disappear
// (before pagination they showed up in the "Sans millésime/région" groups).
const CURSOR_SAFE_SORTS: readonly string[] = ['createdAt', 'updatedAt']

builder.queryField('wines', (t) =>
  t.field({
    type: WinesType,
    description: 'A page of the current user’s wine list, filtered and sorted per view',
    args: {
      mode: t.arg({ type: WineListModeEnum, defaultValue: 'all' }),
      status: t.arg({ type: WineStatusFilterEnum, defaultValue: 'all' }),
      color: t.arg({ type: WineColorEnum }),
      beverageType: t.arg({ type: BeverageTypeEnum }),
      subtype: t.arg({ type: BeverageSubtypeEnum }),
      sort: t.arg({ type: WineSortEnum, defaultValue: 'updatedAt' }),
      order: t.arg({ type: SortOrderEnum, defaultValue: 'desc' }),
      limit: t.arg.int({ defaultValue: 40 }),
      after: t.arg({ type: 'WineId' }),
    },
    resolve: async (_root, args, { userId }) => {
      const limit = args.limit ?? 40
      const order = args.order ?? 'desc'
      const after = args.after ?? undefined
      const mode = args.mode ?? 'all'
      const status = args.status ?? 'all'
      const color: WineColor | undefined = args.color ?? undefined
      const beverageType: BeverageType | undefined = args.beverageType ?? undefined
      const subtype: BeverageSubtype | undefined = args.subtype ?? undefined

      const sort = args.sort ?? 'updatedAt'
      const facetActive = color !== undefined || beverageType !== undefined || subtype !== undefined

      // The only truly paginated path: the unbounded default view, with no facet
      // active (facets live on the wine document: a cursor would skip matches
      // page after page) and a sort field present on every document (see
      // CURSOR_SAFE_SORTS). Every other view is a bounded subset served in full,
      // so the client can sort and group it freely with no cross-page jumps.
      if (!facetActive && mode === 'all' && status === 'all' && CURSOR_SAFE_SORTS.includes(sort)) {
        const { wineIds, hasMore } = await WineQuery.page(userId, { limit, after, sort, order })
        const items = await assemble(userId, wineIds)
        return { items, hasMore, totalCount: items.length }
      }

      // Everything else (satellite views, facet filters, sorts on optional
      // fields): serve the filtered subset in full, the client sorts and groups.
      const ids = await candidateWineIds(userId, mode)
      const items = (await assemble(userId, ids)).filter(
        (item) =>
          matchesStatus(item, status) &&
          (!color || item.color === color) &&
          (!beverageType || item.beverageType === beverageType) &&
          (!subtype || item.subtype === subtype),
      )
      return { items, hasMore: false, totalCount: items.length }
    },
  }),
)

builder.queryField('wine', (t) =>
  t.field({
    type: WineType,
    nullable: true,
    description: 'Get a single wine by ID',
    args: { id: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { id }, { userId }) => {
      const wine = await WineQuery.getById(userId, id)
      return wine === 'not-found' ? null : wine
    },
  }),
)
