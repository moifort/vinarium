import { CellarQuery } from '~/cellar/query'
import { CellarLogQuery } from '~/cellar-log/query'
import { TastingQuery } from '~/tasting/query'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace UserWine {
  export async function getDetail(wineId: WineId) {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'not-found'

    const bottle = await CellarQuery.getBottleByWineId(wineId)
    const history = await CellarLogQuery.getAllByWineId(wineId)
    const tasting = await TastingQuery.getByWineId(wineId)

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
        bottle !== 'not-found'
          ? {
              row: bottle.row as number,
              col: bottle.col as number,
              rowLabel: bottle.rowLabel as string,
              colLabel: bottle.colLabel as number,
              createdAt: bottle.createdAt,
            }
          : undefined,
      history,
      consumption:
        tasting !== 'not-found'
          ? {
              consumedDate: tasting.consumedDate,
              rating: tasting.rating as number | undefined,
              tastingNotes: tasting.tastingNotes,
            }
          : undefined,
    }
  }
}
