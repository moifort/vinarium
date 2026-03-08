import * as repository from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import { JournalCommand } from '~/domain/journal/command'
import type { WineId } from '~/domain/wine/types'

export namespace CellarCommand {
  export const placeWine = async (wineId: WineId, row: CellarRow, col: CellarCol) => {
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
      row,
      col,
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
      row: existing.row,
      col: existing.col,
      dateOut: new Date(),
    })
    await repository.remove(wineId)
    return
  }
}
