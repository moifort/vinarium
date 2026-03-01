import { keyBy, orderBy, uniq } from 'lodash-es'
import { match } from 'ts-pattern'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import type { Gift } from '~/domain/gift/types'
import { JournalQuery } from '~/domain/journal/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { Recommendation } from '~/domain/recommendation/types'
import { TastingQuery } from '~/domain/tasting/query'
import * as repository from '~/domain/wine/repository'
import type { SortOrder, Wine, WineColor, WineId, WineSort, WineStatus } from '~/domain/wine/types'

export namespace WineQuery {
  export const findAll = async () => {
    return repository.findAll()
  }

  export const getById = async (id: WineId) => {
    const wine = await repository.findBy(id)
    if (!wine) return 'not-found' as const
    return wine
  }

  export const getAll = async (options?: {
    color?: WineColor
    sort?: WineSort
    order?: SortOrder
    status?: WineStatus
  }) => {
    const [all, tastings, gifts, recommendations] = await Promise.all([
      repository.findAll(),
      TastingQuery.getAll(),
      GiftQuery.getAll(),
      RecommendationQuery.getAll(),
    ])
    const ratingMap = keyBy(tastings, ({ wineId }) => wineId)
    const giftMap = keyBy(gifts, ({ wineId }) => wineId)
    const recommendationMap = keyBy(recommendations, ({ wineId }) => wineId)
    const withExtra = all.map((wine) => {
      const { imageBase64, ...rest } = wine
      const tasting = ratingMap[wine.id]
      const gift = giftMap[wine.id]
      const recommendation = recommendationMap[wine.id]
      return {
        ...rest,
        rating: tasting?.rating ?? null,
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
      ? await filterByStatus(byColor, options.status, giftMap, recommendationMap)
      : byColor
    return options?.sort
      ? orderBy(byStatus, sortKey(options.sort), options?.order ?? 'asc')
      : byStatus
  }

  export const getDetail = async (wineId: WineId) => {
    const wine = await repository.findBy(wineId)
    if (!wine) return 'not-found' as const
    const [bottle, history, tasting, gift, recommendation] = await Promise.all([
      CellarQuery.getBottleByWineId(wine.id),
      JournalQuery.getAllByWineId(wine.id),
      TastingQuery.getByWineId(wine.id),
      GiftQuery.getByWineId(wine.id),
      RecommendationQuery.getByWineId(wine.id),
    ])

    const cellar =
      bottle !== 'not-found'
        ? {
            row: bottle.row,
            col: bottle.col,
            rowLabel: bottle.rowLabel,
            colLabel: bottle.colLabel,
            dateIn: bottle.createdAt,
          }
        : await cellarFromJournal(wine.id)

    const { imageBase64, grapeVarieties, ...wineWithoutImage } = wine
    return {
      ...wineWithoutImage,
      grapeVarieties: grapeVarieties ?? [],
      cellar,
      history,
      consumption:
        tasting !== 'not-found'
          ? {
              consumedDate: tasting.consumedDate,
              rating: tasting.rating,
              tastingNotes: tasting.tastingNotes,
              contacts: tasting.contacts,
            }
          : undefined,
      gift:
        gift !== 'not-found'
          ? {
              giftedDate: gift.giftedDate,
              recipientName: gift.recipientName,
            }
          : undefined,
      recommendation:
        recommendation !== 'not-found'
          ? {
              recommenderName: recommendation.recommenderName,
              comment: recommendation.comment,
            }
          : undefined,
    }
  }

  const cellarFromJournal = async (wineId: WineId) => {
    const dates = await JournalQuery.getCellarDates(wineId)
    if (dates === 'not-found') return undefined
    return {
      row: CellarRow(dates.rowLabel.charCodeAt(0) - 65),
      col: CellarCol(dates.colLabel - 1),
      rowLabel: dates.rowLabel,
      colLabel: dates.colLabel,
      dateIn: dates.dateIn,
      dateOut: dates.dateOut,
    }
  }

  const filterByStatus = async (
    wines: Wine[],
    status: WineStatus,
    giftMap: Record<string, Gift>,
    recommendationMap: Record<string, Recommendation>,
  ) => {
    const bottles = await CellarQuery.getAllBottles()
    const inCellarMap = keyBy(bottles, ({ wineId }) => wineId)
    if (status === 'in-cellar') return wines.filter((wine) => wine.id in inCellarMap)
    if (status === 'gifted')
      return wines.filter((wine) => !(wine.id in inCellarMap) && wine.id in giftMap)
    if (status === 'recommended')
      return wines.filter(
        (wine) =>
          !(wine.id in inCellarMap) && !(wine.id in giftMap) && wine.id in recommendationMap,
      )
    return wines.filter(
      (wine) =>
        !(wine.id in inCellarMap) && !(wine.id in giftMap) && !(wine.id in recommendationMap),
    )
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
