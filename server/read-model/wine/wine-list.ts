import { keyBy, orderBy, uniq } from 'lodash-es'
import { match } from 'ts-pattern'
import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import type { Gift } from '~/domain/gift/types'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { Recommendation } from '~/domain/recommendation/types'
import { TastingQuery } from '~/domain/tasting/query'
import { wineStatus } from '~/domain/wine/business-rules'
import { WineQuery } from '~/domain/wine/query'
import type { SortOrder, Wine, WineColor, WineSort, WineStatus } from '~/domain/wine/types'

export namespace WineListReadModel {
  export const all = async (options?: {
    color?: WineColor
    sort?: WineSort
    order?: SortOrder
    status?: WineStatus
  }) => {
    const [wines, tastings, gifts, recommendations] = await Promise.all([
      WineQuery.findAll(),
      TastingQuery.getAll(),
      GiftQuery.getAll(),
      RecommendationQuery.getAll(),
    ])
    const ratingMap = keyBy(tastings, ({ wineId }) => wineId)
    const giftMap = keyBy(gifts, ({ wineId }) => wineId)
    const recommendationMap = keyBy(recommendations, ({ wineId }) => wineId)
    const withExtra = wines.map((wine) => {
      const { imageBase64, ...rest } = wine
      const tasting = ratingMap[wine.id]
      const gift = giftMap[wine.id]
      const recommendation = recommendationMap[wine.id]
      return {
        ...rest,
        rating: tasting?.rating ?? null,
        shortlist: tasting?.shortlist === true,
        giftedTo: gift?.recipientName ?? null,
        recommendedBy: recommendation?.recommenderName ?? null,
        contacts: uniq([
          ...(tasting?.contacts ?? []),
          ...(wine.giftedBy ? [wine.giftedBy] : []),
          ...(gift?.recipientName ? [gift.recipientName] : []),
          ...(recommendation?.recommenderName ? [recommendation.recommenderName] : []),
        ]),
      }
    })
    const byColor = options?.color
      ? withExtra.filter((wine) => wine.color === options.color)
      : withExtra
    const byStatus = options?.status
      ? filterByStatus(byColor, options.status, giftMap, recommendationMap)
      : byColor
    return options?.sort
      ? orderBy(byStatus, sortKey(options.sort), options?.order ?? 'asc')
      : byStatus
  }

  const filterByStatus = async (
    wines: Wine[],
    status: WineStatus,
    giftMap: Record<string, Gift>,
    recommendationMap: Record<string, Recommendation>,
  ) => {
    const bottles = await CellarQuery.getAllBottles()
    const inCellarMap = keyBy(bottles, ({ wineId }) => wineId)
    return wines.filter((wine) => {
      const resolved = wineStatus({
        inCellar: wine.id in inCellarMap,
        gifted: wine.id in giftMap,
        recommended: wine.id in recommendationMap,
      })
      return resolved === status
    })
  }

  const sortKey = (sort: WineSort) => (wine: Wine) =>
    match(sort)
      .with('createdAt', () => new Date(wine.createdAt).getTime())
      .with('updatedAt', () => new Date(wine.updatedAt).getTime())
      .with('vintage', () => wine.vintage ?? 0)
      .with('region', () => wine.region ?? '')
      .with('color', () => wine.color)
      .with('price', () => wine.purchasePrice ?? 0)
      .exhaustive()
}
