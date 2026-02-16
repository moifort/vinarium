import * as repository from '~/cellar/repository'
import type { CellarCol, CellarRow } from '~/cellar/types'
import { CellarHistory } from '~/cellar-history/index'
import type { WineId } from '~/wine/types'

export namespace CellarCommand {
  export const placeWine = async (wineId: WineId, row: CellarRow, col: CellarCol) => {
    const entry = await repository.save({
      wineId,
      row,
      col,
      createdAt: new Date(),
      updatedAt: new Date(),
    })
    await CellarHistory.create({ wineId, row, col, dateIn: entry.createdAt })
    return entry
  }

  export const removeWine = async (wineId: WineId) => {
    const existing = await repository.findBy(wineId)
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
}
