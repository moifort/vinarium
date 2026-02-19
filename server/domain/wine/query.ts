import { keyBy, orderBy } from 'lodash-es'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { JournalQuery } from '~/domain/journal/query'
import { TastingQuery } from '~/domain/tasting/query'
import * as repository from '~/domain/wine/repository'
import type {
  SortOrder,
  Wine,
  WineColor,
  WineId,
  WineSort,
  WineStatus,
  WineView,
} from '~/domain/wine/types'

export namespace WineQuery {
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
    const [all, tastings, gifts] = await Promise.all([
      repository.findAll(),
      TastingQuery.getAll(),
      GiftQuery.getAll(),
    ])
    const ratingMap = keyBy(tastings, ({ wineId }) => wineId)
    const giftMap = keyBy(gifts, ({ wineId }) => wineId)
    const giftIds = new Set(gifts.map(({ wineId }) => wineId))
    const withExtra = all.map((wine) => ({
      ...wine,
      rating: ratingMap[wine.id]?.rating ?? null,
      giftedTo: giftMap[wine.id]?.recipientName ?? null,
    }))
    const byColor = options?.color
      ? withExtra.filter((wine) => wine.color === options.color)
      : withExtra
    const byStatus = options?.status
      ? await filterByStatus(byColor, options.status, giftIds)
      : byColor
    return options?.sort
      ? orderBy(byStatus, sortKey(options.sort), options.order === 'desc' ? 'desc' : 'asc')
      : byStatus
  }

  export const getDetail = async (wineId: WineId) => {
    const wine = await repository.findBy(wineId)
    if (!wine) return 'not-found' as const
    return toView(wine)
  }

  const toView = async (wine: Wine): Promise<WineView> => {
    const [bottle, history, tasting, gift] = await Promise.all([
      CellarQuery.getBottleByWineId(wine.id),
      JournalQuery.getAllByWineId(wine.id),
      TastingQuery.getByWineId(wine.id),
      GiftQuery.getByWineId(wine.id),
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

    return {
      ...wine,
      cellar,
      history,
      consumption:
        tasting !== 'not-found'
          ? {
              consumedDate: tasting.consumedDate,
              rating: tasting.rating,
              tastingNotes: tasting.tastingNotes,
            }
          : undefined,
      gift:
        gift !== 'not-found'
          ? {
              giftedDate: gift.giftedDate,
              recipientName: gift.recipientName,
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

  const filterByStatus = async (wines: Wine[], status: WineStatus, giftIds: Set<string>) => {
    const bottles = await CellarQuery.getAllBottles()
    const inCellarIds = new Set(bottles.map(({ wineId }) => wineId))
    if (status === 'in-cellar') return wines.filter((wine) => inCellarIds.has(wine.id))
    if (status === 'gifted')
      return wines.filter((wine) => !inCellarIds.has(wine.id) && giftIds.has(wine.id))
    return wines.filter((wine) => !inCellarIds.has(wine.id) && !giftIds.has(wine.id))
  }

  const sortKey = (sort: WineSort) => (wine: Wine) => {
    switch (sort) {
      case 'createdAt':
        return new Date(wine.createdAt).getTime()
      case 'vintage':
        return wine.vintage ?? 0
      case 'region':
        return wine.region ?? ''
      case 'color':
        return wine.color
      case 'price':
        return wine.purchasePrice ?? 0
      default:
        return 0
    }
  }
}
