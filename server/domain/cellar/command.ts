import type { WriteBatch } from 'firebase-admin/firestore'
import type { BeverageId } from '~/domain/beverage/types'
import * as repository from '~/domain/cellar/infrastructure/repository'
import type { CellarBottle, CellarCol, CellarRow } from '~/domain/cellar/types'
import { JournalCommand } from '~/domain/journal/command'
import type { UserId } from '~/domain/shared/types'
import { atomically, bulkSave } from '~/utils/firestore'

export namespace CellarCommand {
  export const placeBeverage = async (
    userId: UserId,
    beverageId: BeverageId,
    row: CellarRow,
    col: CellarCol,
  ) => {
    const now = new Date()
    const entry = await repository.save({
      userId,
      beverageId,
      row,
      col,
      createdAt: now,
      updatedAt: now,
    })
    await JournalCommand.bottleIn(userId, {
      type: 'in',
      beverageId,
      row,
      col,
      date: now,
    })
    return entry
  }

  export const removeBeverage = async (userId: UserId, beverageId: BeverageId) => {
    const existing = await repository.findBy(userId, beverageId)
    if (!existing) return 'not-in-cellar' as const
    await JournalCommand.bottleOut(userId, {
      type: 'out',
      beverageId: existing.beverageId,
      row: existing.row,
      col: existing.col,
      date: new Date(),
    })
    await repository.remove(userId, beverageId)
    return undefined
  }

  export const moveBottle = async (
    userId: UserId,
    beverageId: BeverageId,
    targetRow: CellarRow,
    targetCol: CellarCol,
  ) => {
    // Two independent keyed reads in parallel: the moved bottle and whatever
    // occupies the target slot — never a scan of the whole cellar.
    const [source, atTarget] = await Promise.all([
      repository.findBy(userId, beverageId),
      repository.findByPosition(userId, targetRow, targetCol),
    ])
    if (!source) return 'not-in-cellar' as const
    if (source.row === targetRow && source.col === targetCol) return source

    const now = new Date()
    const occupant = atTarget && atTarget.beverageId !== beverageId ? atTarget : undefined

    // The swap (cellar saves) and its journal trail commit as one batch: a
    // partial failure can no longer leave the cellar half-moved or the journal
    // out of sync with the bottle positions. This guards against partial
    // writes, not concurrent moves — the occupant lookup above is not locked
    // (a Firestore transaction would be needed for that).
    return await atomically(async (batch) => {
      await JournalCommand.bottleOut(
        userId,
        { type: 'out', beverageId: source.beverageId, row: source.row, col: source.col, date: now },
        batch,
      )
      const movedSource = await repository.save(
        { ...source, row: targetRow, col: targetCol, updatedAt: now },
        batch,
      )
      await JournalCommand.bottleIn(
        userId,
        {
          type: 'in',
          beverageId: movedSource.beverageId,
          row: targetRow,
          col: targetCol,
          date: now,
        },
        batch,
      )
      if (occupant) {
        await JournalCommand.bottleOut(
          userId,
          {
            type: 'out',
            beverageId: occupant.beverageId,
            row: occupant.row,
            col: occupant.col,
            date: now,
          },
          batch,
        )
        await repository.save(
          { ...occupant, row: source.row, col: source.col, updatedAt: now },
          batch,
        )
        await JournalCommand.bottleIn(
          userId,
          {
            type: 'in',
            beverageId: occupant.beverageId,
            row: source.row,
            col: source.col,
            date: now,
          },
          batch,
        )
      }
      return movedSource
    })
  }

  // Deletes the wine's bottle without journaling a bottle-out movement: used when
  // the wine and its entire journal are erased together in the same batch (see
  // BeverageUseCase.removeCompletely) — a freshly written journal entry would survive
  // the journal wipe, since batched writes are invisible to the wipe's query.
  export const eraseBeverage = async (
    userId: UserId,
    beverageId: BeverageId,
    batch: WriteBatch,
  ) => {
    await repository.remove(userId, beverageId, batch)
  }

  // Wipe the user's cellar and restore the given bottles (account import).
  export const replaceAllForUser = async (userId: UserId, bottles: CellarBottle[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(bottles, repository.save)
  }
}
