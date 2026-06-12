import type { WriteBatch } from 'firebase-admin/firestore'
import * as repository from '~/domain/cellar/infrastructure/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import { JournalCommand } from '~/domain/journal/command'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { atomically } from '~/utils/firestore'

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

    // The swap (cellar saves) and its journal trail commit as one batch: a
    // partial failure can no longer leave the cellar half-moved or the journal
    // out of sync with the bottle positions. This guards against partial
    // writes, not concurrent moves — the occupant lookup above is not locked
    // (a Firestore transaction would be needed for that).
    return await atomically(async (batch) => {
      await JournalCommand.bottleOut(
        userId,
        { type: 'out', wineId: source.wineId, row: source.row, col: source.col, date: now },
        batch,
      )
      const movedSource = await repository.save(
        { ...source, row: targetRow, col: targetCol, updatedAt: now },
        batch,
      )
      await JournalCommand.bottleIn(
        userId,
        { type: 'in', wineId: movedSource.wineId, row: targetRow, col: targetCol, date: now },
        batch,
      )
      if (occupant) {
        await JournalCommand.bottleOut(
          userId,
          { type: 'out', wineId: occupant.wineId, row: occupant.row, col: occupant.col, date: now },
          batch,
        )
        await repository.save(
          { ...occupant, row: source.row, col: source.col, updatedAt: now },
          batch,
        )
        await JournalCommand.bottleIn(
          userId,
          { type: 'in', wineId: occupant.wineId, row: source.row, col: source.col, date: now },
          batch,
        )
      }
      return movedSource
    })
  }

  // Deletes the wine's bottle without journaling a bottle-out movement: used when
  // the wine and its entire journal are erased together in the same batch (see
  // WineUseCase.removeCompletely) — a freshly written journal entry would survive
  // the journal wipe, since batched writes are invisible to the wipe's query.
  export const eraseWine = async (userId: UserId, wineId: WineId, batch: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }
}
