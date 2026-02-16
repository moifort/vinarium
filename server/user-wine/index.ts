import { Cellar } from '~/cellar/index'
import type { UserWineDetail } from '~/user-wine/types'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace UserWine {
  export async function getDetail(wineId: WineId): Promise<UserWineDetail | 'not-found'> {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'not-found'
    const entry = await Cellar.getEntryByWineId(wineId)
    let cellar: UserWineDetail['cellar']
    let consumption: UserWineDetail['consumption']

    if (entry && !entry.dateOut) {
      cellar = {
        row: entry.row as string,
        col: entry.col as number,
        dateIn: entry.dateIn,
      }
    } else if (entry?.dateOut) {
      consumption = {
        dateOut: entry.dateOut,
        consumedDate: entry.consumedDate,
        rating: entry.rating as number | undefined,
        tastingNotes: entry.tastingNotes,
      }
    }

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
      cellar,
      consumption,
    }
  }
}
