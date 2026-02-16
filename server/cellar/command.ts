import { CellarCol, CellarRow } from '~/cellar/primitives'
import { CellarQuery } from '~/cellar/query'
import * as repository from '~/cellar/repository'
import type { CellarCol as CellarColType, CellarRow as CellarRowType } from '~/cellar/types'
import { CellarGrid } from '~/cellar-grid/index'
import { CellarHistory } from '~/cellar-history/index'
import { Wines } from '~/wine/index'
import type { WineId } from '~/wine/types'

export namespace CellarCommand {
  export const placeWine = async (wineId: WineId, row: CellarRowType, col: CellarColType) => {
    const wine = await Wines.getById(wineId)
    if (wine === 'not-found') return 'wine-not-found' as const
    const existing = await CellarQuery.getEntryByWineId(wineId)
    if (existing) return 'already-placed' as const
    const allEntries = await repository.findAll()
    if (CellarGrid.isPositionTaken(allEntries, row, col)) return 'position-taken' as const
    const entry = {
      wineId,
      row,
      col,
      rowLabel: CellarRow.toLabel(row),
      colLabel: CellarCol.toLabel(col),
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    await repository.save(entry)
    return entry
  }

  export const removeWine = async (wineId: WineId) => {
    const existing = await CellarQuery.getEntryByWineId(wineId)
    if (!existing) return 'not-in-cellar' as const
    await CellarHistory.create({
      wineId: existing.wineId,
      row: existing.row,
      col: existing.col,
      rowLabel: existing.rowLabel,
      colLabel: existing.colLabel,
      dateIn: existing.createdAt,
      dateOut: new Date(),
    })
    await repository.remove(wineId)
    return
  }
}
