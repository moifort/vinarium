import * as repository from '~/cellar/repository'
import type { CellarCol, CellarRow } from '~/cellar/types'
import { CellarGrid } from '~/cellar-grid/index'
import { CellarHistory } from '~/cellar-history/index'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace Cellar {
  export const getAllEntries = () => repository.findAll()

  export const getEntryByWineId = (wineId: WineId) => repository.findBy(wineId)

  export const placeWine = async (wineId: WineId, row: CellarRow, col: CellarCol) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const
    const existing = await getEntryByWineId(wineId)
    if (existing) return 'already-placed' as const
    const allEntries = await repository.findAll()
    if (CellarGrid.isPositionTaken(allEntries, row, col)) return 'position-taken' as const
    const entry = { wineId, row, col, createdAt: new Date(), updatedAt: new Date() }
    await repository.save(entry)
    return entry
  }

  export const removeWine = async (wineId: WineId) => {
    const existing = await getEntryByWineId(wineId)
    if (!existing) return 'not-in-cellar' as const
    await CellarHistory.create({
      wineId: existing.wineId,
      row: existing.row,
      col: existing.col,
      dateIn: existing.createdAt,
      dateOut: new Date(),
    })
    await repository.remove(wineId)
    return
  }

  export const suggestPosition = async (wineId: WineId) => {
    const allEntries = await repository.findAll()
    return CellarGrid.suggest(wineId, allEntries)
  }

  export const getGrid = async () => {
    const allEntries = await repository.findAll()
    return CellarGrid.get(allEntries)
  }
}
