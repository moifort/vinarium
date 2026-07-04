import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import { builder } from '~/domain/shared/graphql/builder'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import { WineQuery } from '../../query'
import type { WineId, WineListMode, WineStatusFilter } from '../../types'
import {
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

// Views whose porter collection has no orderable date field (favorites,
// recommended, consumed) are small subsets: load their wine ids in full and let
// the client sort/group. hasMore is false for these.
const fullLoadWineIds = async (
  userId: UserId,
  mode: WineListMode,
  status: WineStatusFilter,
): Promise<WineId[]> => {
  if (mode === 'favorites') {
    const tastings = await TastingQuery.getAll(userId)
    return tastings.filter((tasting) => tasting.favorite === true).map((tasting) => tasting.wineId)
  }
  if (mode === 'recommended') {
    const recommendations = await RecommendationQuery.getAll(userId)
    return recommendations.map((recommendation) => recommendation.wineId)
  }
  // mode 'all' with the 'consumed' status filter
  const tastings = await TastingQuery.getAll(userId)
  return tastings
    .filter((tasting) => status !== 'consumed' || tasting.consumedDate !== undefined)
    .map((tasting) => tasting.wineId)
}

builder.queryField('wines', (t) =>
  t.field({
    type: WinesType,
    description: 'A page of the current user’s wine list, filtered and sorted per view',
    args: {
      mode: t.arg({ type: WineListModeEnum, defaultValue: 'all' }),
      status: t.arg({ type: WineStatusFilterEnum, defaultValue: 'all' }),
      color: t.arg({ type: WineColorEnum }),
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

      // Truly paginated paths: the porter collection carries an order field.
      if (mode === 'gifted') {
        const { wineIds, hasMore } = await WineQuery.giftedPage(userId, { limit, after, order })
        const items = await assemble(userId, wineIds)
        return { items, hasMore, totalCount: items.length }
      }
      if (mode === 'all' && status === 'in-cellar') {
        const { wineIds, hasMore } = await CellarQuery.pageWineIds(userId, { limit, after, order })
        const items = await assemble(userId, wineIds)
        return { items, hasMore, totalCount: items.length }
      }
      if (mode === 'all' && status === 'all') {
        const { wineIds, hasMore } = await WineQuery.page(userId, {
          limit,
          after,
          sort: args.sort ?? 'updatedAt',
          order,
        })
        const items = await assemble(userId, wineIds)
        return { items, hasMore, totalCount: items.length }
      }

      // Full-load paths (favorites, recommended, consumed): single page.
      const items = await assemble(userId, await fullLoadWineIds(userId, mode, status))
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
