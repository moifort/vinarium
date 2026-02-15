import { Cellar } from '~/cellar/index'
import type { WineId } from '~/wine/types'
import { Wines } from '~/wine/index'
import type { UserWineDetail } from '~/user-wine/types'

export namespace UserWine {
  export async function getDetail(wineId: WineId): Promise<UserWineDetail | 'not-found'> {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'not-found'

    const entry = await Cellar.getEntryByWineId(wineId)

    let cellar: UserWineDetail['cellar'] = null
    let consumption: UserWineDetail['consumption'] = null

    if (entry && !entry.dateOut) {
      cellar = {
        row: entry.row as string,
        col: entry.col as number,
        dateIn: entry.dateIn,
      }
    } else if (entry?.dateOut) {
      consumption = {
        dateOut: entry.dateOut,
        consumedDate: entry.consumedDate ?? null,
        rating: entry.rating != null ? (entry.rating as number) : null,
        tastingNotes: entry.tastingNotes ?? null,
      }
    }

    return {
      id: wine.id as string,
      name: wine.name as string,
      color: wine.color,
      domain: wine.domain ?? null,
      vintage: wine.vintage != null ? (wine.vintage as number) : null,
      appellation: wine.appellation ?? null,
      region: wine.region != null ? (wine.region as string) : null,
      country: wine.country != null ? (wine.country as string) : null,
      grapeVarieties: wine.grapeVarieties ?? [],
      alcoholContent: wine.alcoholContent != null ? (wine.alcoholContent as number) : null,
      classification: wine.classification ?? null,
      purchasePrice: wine.purchasePrice != null ? (wine.purchasePrice as number) : null,
      purchaseDate: wine.purchaseDate ?? null,
      drinkFrom: wine.drinkFrom != null ? (wine.drinkFrom as number) : null,
      drinkUntil: wine.drinkUntil != null ? (wine.drinkUntil as number) : null,
      notes: wine.notes ?? null,
      createdAt: wine.createdAt,
      updatedAt: wine.updatedAt,
      cellar,
      consumption,
    }
  }
}
