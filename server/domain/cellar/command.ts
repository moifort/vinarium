import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as repository from '~/domain/cellar/repository'
import type { CellarCol as CellarColType, CellarRow as CellarRowType } from '~/domain/cellar/types'
import { JournalCommand } from '~/domain/journal/command'
import type { WineId } from '~/domain/wine/types'

export namespace CellarCommand {
  export const placeWine = async (wineId: WineId, row: CellarRowType, col: CellarColType) => {
    const entry = await repository.save({
      wineId,
      row,
      col,
      createdAt: new Date(),
      updatedAt: new Date(),
    })
    await JournalCommand.bottleIn({
      type: 'in',
      wineId,
      rowLabel: CellarRow.toLabel(row),
      colLabel: CellarCol.toLabel(col),
      dateIn: entry.createdAt,
    })
    return entry
  }

  export const removeWine = async (wineId: WineId) => {
    const existing = await repository.findBy(wineId)
    if (!existing) return 'not-in-cellar' as const
    await JournalCommand.bottleOut({
      type: 'out',
      wineId: existing.wineId,
      rowLabel: CellarRow.toLabel(existing.row),
      colLabel: CellarCol.toLabel(existing.col),
      dateOut: new Date(),
    })
    await repository.remove(wineId)
    return
  }
}
