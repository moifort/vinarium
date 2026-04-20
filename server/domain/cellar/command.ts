import * as repository from '~/domain/cellar/infrastructure/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import { JournalCommand } from '~/domain/journal/command'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace CellarCommand {
  export const placeWine = async (
    userId: UserId,
    wineId: WineId,
    row: CellarRow,
    col: CellarCol,
  ) => {
    const now = new Date()
    const entry = await repository.save({
      userId,
      wineId,
      row,
      col,
      createdAt: now,
      updatedAt: now,
    })
    await JournalCommand.bottleIn(userId, {
      type: 'in',
      wineId,
      row,
      col,
      date: now,
    })
    return entry
  }

  export const removeWine = async (userId: UserId, wineId: WineId) => {
    const existing = await repository.findBy(userId, wineId)
    if (!existing) return 'not-in-cellar' as const
    await JournalCommand.bottleOut(userId, {
      type: 'out',
      wineId: existing.wineId,
      row: existing.row,
      col: existing.col,
      date: new Date(),
    })
    await repository.remove(userId, wineId)
    return undefined
  }

  export const moveBottle = async (
    userId: UserId,
    wineId: WineId,
    targetRow: CellarRow,
    targetCol: CellarCol,
  ) => {
    const source = await repository.findBy(userId, wineId)
    if (!source) return 'not-in-cellar' as const
    if (source.row === targetRow && source.col === targetCol) return source

    const now = new Date()
    const occupant = (await repository.findAllByUser(userId)).find(
      (entry) => entry.row === targetRow && entry.col === targetCol && entry.wineId !== wineId,
    )

    await JournalCommand.bottleOut(userId, {
      type: 'out',
      wineId: source.wineId,
      row: source.row,
      col: source.col,
      date: now,
    })
    if (occupant) {
      await JournalCommand.bottleOut(userId, {
        type: 'out',
        wineId: occupant.wineId,
        row: occupant.row,
        col: occupant.col,
        date: now,
      })
    }

    const movedSource = await repository.save({
      ...source,
      row: targetRow,
      col: targetCol,
      updatedAt: now,
    })
    if (occupant) {
      await repository.save({
        ...occupant,
        row: source.row,
        col: source.col,
        updatedAt: now,
      })
    }

    await JournalCommand.bottleIn(userId, {
      type: 'in',
      wineId: movedSource.wineId,
      row: movedSource.row,
      col: movedSource.col,
      date: now,
    })
    if (occupant) {
      await JournalCommand.bottleIn(userId, {
        type: 'in',
        wineId: occupant.wineId,
        row: source.row,
        col: source.col,
        date: now,
      })
    }

    return movedSource
  }
}
