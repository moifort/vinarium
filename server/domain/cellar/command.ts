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

  export const moveBottle = async (wineId: WineId, targetRow: CellarRow, targetCol: CellarCol) => {
    const source = await repository.findBy(wineId)
    if (!source) return 'not-in-cellar' as const
    if (source.row === targetRow && source.col === targetCol) return source

    const now = new Date()
    const occupant = (await repository.findAll()).find(
      (entry) => entry.row === targetRow && entry.col === targetCol && entry.wineId !== wineId,
    )

    await JournalCommand.bottleOut({
      type: 'out',
      wineId: source.wineId,
      row: source.row,
      col: source.col,
      dateOut: now,
    })
    if (occupant) {
      await JournalCommand.bottleOut({
        type: 'out',
        wineId: occupant.wineId,
        row: occupant.row,
        col: occupant.col,
        dateOut: now,
      })
    }

    const movedSource = await repository.update({
      ...source,
      row: targetRow,
      col: targetCol,
      updatedAt: now,
    })
    if (occupant) {
      await repository.update({
        ...occupant,
        row: source.row,
        col: source.col,
        updatedAt: now,
      })
    }

    await JournalCommand.bottleIn({
      type: 'in',
      wineId: movedSource.wineId,
      row: movedSource.row,
      col: movedSource.col,
      dateIn: now,
    })
    if (occupant) {
      await JournalCommand.bottleIn({
        type: 'in',
        wineId: occupant.wineId,
        row: source.row,
        col: source.col,
        dateIn: now,
      })
    }

    return movedSource
  }
}
