import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { JournalQuery } from '~/domain/journal/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import { TastingQuery } from '~/domain/tasting/query'
import { WineQuery } from '~/domain/wine/query'
import type { WineId } from '~/domain/wine/types'
import { exists as bottleImageExists } from '~/system/bottle-image/repository'

export namespace WineDetailReadModel {
  export const byId = async (wineId: WineId) => {
    const wine = await WineQuery.getById(wineId)
    if (wine === 'not-found') return 'not-found' as const
    const [bottle, history, tasting, gift, recommendation, hasBottleImage] = await Promise.all([
      CellarQuery.getBottleByWineId(wine.id),
      JournalQuery.getAllByWineId(wine),
      TastingQuery.getByWineId(wine.id),
      GiftQuery.getByWineId(wine.id),
      RecommendationQuery.getByWineId(wine.id),
      bottleImageExists(wine.id),
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
      hasBottleImage,
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
      row: dates.row,
      col: dates.col,
      rowLabel: CellarRow.toLabel(dates.row),
      colLabel: CellarCol.toLabel(dates.col),
      dateIn: dates.dateIn,
      dateOut: dates.dateOut,
    }
  }
}
