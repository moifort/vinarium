import { CellarQuery } from '~/cellar/query'
import { CellarLogQuery } from '~/cellar-log/query'
import { UserLog } from '~/user-log/index'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace UserWine {
  export async function getDetail(wineId: WineId) {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'not-found'

    const entry = await CellarQuery.getEntryByWineId(wineId)
    const history = await CellarLogQuery.getByWineId(wineId)
    const userLog = await UserLog.getByWineId(wineId)

    return {
      id: wine.id as string,
      name: wine.name as string,
      color: wine.color,
      grapeVarieties: wine.grapeVarieties ?? [],
      createdAt: wine.createdAt,
      updatedAt: wine.updatedAt,
      domain: wine.domain,
      vintage: wine.vintage as number | undefined,
      appellation: wine.appellation,
      region: wine.region as string | undefined,
      country: wine.country as string | undefined,
      alcoholContent: wine.alcoholContent as number | undefined,
      classification: wine.classification,
      purchasePrice: wine.purchasePrice as number | undefined,
      purchaseDate: wine.purchaseDate,
      drinkFrom: wine.drinkFrom as number | undefined,
      drinkUntil: wine.drinkUntil as number | undefined,
      notes: wine.notes,
      cellar:
        entry !== 'not-found'
          ? {
              row: entry.row as number,
              col: entry.col as number,
              rowLabel: entry.rowLabel as string,
              colLabel: entry.colLabel as number,
              createdAt: entry.createdAt,
            }
          : undefined,
      history,
      consumption: userLog
        ? {
            consumedDate: userLog.consumedDate,
            rating: userLog.rating as number | undefined,
            tastingNotes: userLog.tastingNotes,
          }
        : undefined,
    }
  }
}
