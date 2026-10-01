import type { WriteBatch } from 'firebase-admin/firestore'
import { BeverageQuery } from '~/domain/beverage/query'
import type { BeverageId } from '~/domain/beverage/types'
import { isOutsideGrid } from '~/domain/cellar/business-rules'
import * as repository from '~/domain/cellar/infrastructure/repository'
import { randomCellarId } from '~/domain/cellar/primitives'
import { CellarQuery } from '~/domain/cellar/query'
import {
  type CellarBottle,
  type CellarCol,
  type CellarCols,
  type CellarId,
  type CellarName,
  type CellarRow,
  type CellarRows,
  type CellarZones,
  MAX_CELLARS,
} from '~/domain/cellar/types'
import { HouseholdQuery } from '~/domain/household/query'
import { JournalCommand } from '~/domain/journal/command'
import type { UserId } from '~/domain/shared/types'
import { atomically, bulkSave } from '~/utils/firestore'

export namespace CellarCommand {
  // Initialise the grid dimensions for the caller's cellar scope during onboarding.
  // Never overwrites an existing config: the grid is shared, so a housemate who
  // onboards after the household already sized its cave must not resize (or shrink,
  // stranding placed bottles) it. Returns the effective config either way.
  export const configureFor = async (
    userId: UserId,
    rows: CellarRows,
    cols: CellarCols,
    zones: CellarZones,
    batch?: WriteBatch,
  ) => {
    const key = await CellarQuery.configKey(userId)
    const existing = await repository.findConfig(key)
    if (existing) return existing
    return repository.saveConfig(key, { rows, cols, zones }, batch)
  }

  // Resize/retune a cellar from the settings screen. Unlike configureFor's
  // onboarding no-op, this is a deliberate action, so it OVERWRITES the shared
  // grid. Refuses to shrink below a placed bottle: positions are 0-based, so any
  // bottle at row >= rows or col >= cols would fall outside the new grid and be
  // stranded. The check spans every household member's bottles in that cellar.
  export const reconfigure = async (
    userId: UserId,
    rows: CellarRows,
    cols: CellarCols,
    zones: CellarZones,
    cellarId?: CellarId,
  ) => {
    const cellar = await CellarQuery.byId(userId, cellarId)
    if (cellar === 'not-found') return 'not-found' as const
    const bottles = await CellarQuery.bottlesIn(userId, cellar.id)
    const outOfBounds = bottles.filter((b) => b.row >= rows || b.col >= cols).length
    if (outOfBounds > 0) return { outOfBounds } as const
    const stored = await repository.findConfig(cellar.id)
    return repository.saveConfig(cellar.id, { ...stored, rows, cols, zones })
  }

  // Add a cellar to the household. Whether the caller may (Premium) is the
  // use-case's call; the count cap holds whoever asks.
  export const create = async (
    userId: UserId,
    name: CellarName,
    { rows, cols, zones }: { rows: CellarRows; cols: CellarCols; zones: CellarZones },
  ) => {
    if ((await CellarQuery.cellars(userId)).length >= MAX_CELLARS)
      return 'too-many-cellars' as const
    const id = randomCellarId()
    const scopeKey = await CellarQuery.configKey(userId)
    await repository.saveConfig(id, { scopeKey, name, rows, cols, zones, createdAt: new Date() })
    return id
  }

  // Name a cellar. The primary one may have no document yet (never sized at
  // onboarding): naming it writes it at the default size it was shown with.
  export const rename = async (userId: UserId, cellarId: CellarId, name: CellarName) => {
    const cellar = await CellarQuery.byId(userId, cellarId)
    if (cellar === 'not-found') return 'not-found' as const
    const stored = await repository.findConfig(cellar.id)
    const { rows, cols, zones } = cellar
    await repository.saveConfig(cellar.id, { rows, cols, zones, ...stored, name })
    return cellar.id
  }

  // Remove an empty cellar. The primary one stays: it is where a bottle naming
  // no cellar, or one the household lost, stands.
  export const remove = async (userId: UserId, cellarId: CellarId) => {
    const cellar = await CellarQuery.byId(userId, cellarId)
    if (cellar === 'not-found') return 'not-found' as const
    if (cellar.isPrimary) return 'primary-cellar' as const
    const placed = (await CellarQuery.bottlesIn(userId, cellar.id)).length
    if (placed > 0) return { notEmpty: placed } as const
    await repository.removeConfig(cellar.id, await CellarQuery.configKey(userId))
    return undefined
  }

  export const placeBeverage = async (
    userId: UserId,
    beverageId: BeverageId,
    row: CellarRow,
    col: CellarCol,
    cellarId?: CellarId,
  ) => {
    // You only place your own wine into the shared grid — placing a housemate's
    // beverage would write a second, mis-attributed bottle for it.
    if ((await BeverageQuery.byId(userId, beverageId)) === 'not-found')
      return 'not-your-beverage' as const

    const cellar = await CellarQuery.byId(userId, cellarId)
    if (cellar === 'not-found') return 'cellar-not-found' as const
    if (isOutsideGrid(cellar, row, col)) return 'out-of-grid' as const

    // The grid is shared: a slot filled by any household member is taken. The
    // bottle's owner stays the caller (their own wine).
    const occupant = (await CellarQuery.bottlesIn(userId, cellar.id)).find(
      (bottle) => bottle.row === row && bottle.col === col,
    )
    if (occupant && occupant.beverageId !== beverageId) return 'position-occupied' as const

    const now = new Date()
    const entry = await repository.save({
      userId,
      beverageId,
      cellarId: cellar.id,
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

  // Remove a bottle from the shared grid. Any member may remove any bottle, but
  // the cellar doc and the journal 'out' belong to the bottle's owner. Returns
  // the owner so the use-case can attribute a gift to them.
  export const removeBeverage = async (actorId: UserId, beverageId: BeverageId) => {
    const scope = await HouseholdQuery.cellarScope(actorId)
    const existing = await repository.findByForUsers(scope.memberIds, beverageId)
    if (!existing) return 'not-in-cellar' as const
    await JournalCommand.bottleOut(existing.userId, {
      type: 'out',
      beverageId: existing.beverageId,
      row: existing.row,
      col: existing.col,
      date: new Date(),
    })
    await repository.remove(existing.userId, beverageId)
    return { ownerId: existing.userId }
  }

  // Move a bottle to a slot of the same cellar, or of another one when `cellarId`
  // names it. A bottle already standing there swaps places with the moved one.
  export const moveBottle = async (
    actorId: UserId,
    beverageId: BeverageId,
    targetRow: CellarRow,
    targetCol: CellarCol,
    targetCellarId?: CellarId,
  ) => {
    // Both the moved bottle and the target's occupant may belong to a housemate,
    // so both are located across the household.
    const scope = await HouseholdQuery.cellarScope(actorId)
    const found = await repository.findByForUsers(scope.memberIds, beverageId)
    if (!found) return 'not-in-cellar' as const
    const source: CellarBottle = { ...found, cellarId: await CellarQuery.cellarOf(actorId, found) }
    const cellar = await CellarQuery.byId(actorId, targetCellarId ?? source.cellarId)
    if (cellar === 'not-found') return 'cellar-not-found' as const
    if (isOutsideGrid(cellar, targetRow, targetCol)) return 'out-of-grid' as const
    if (source.cellarId === cellar.id && source.row === targetRow && source.col === targetCol)
      return source

    const atTarget = (await CellarQuery.bottlesIn(actorId, cellar.id)).find(
      (bottle) => bottle.row === targetRow && bottle.col === targetCol,
    )
    const now = new Date()
    const occupant = atTarget && atTarget.beverageId !== beverageId ? atTarget : undefined

    // The swap (cellar saves) and its journal trail commit as one batch: a
    // partial failure can no longer leave the cellar half-moved or the journal
    // out of sync with the bottle positions. This guards against partial
    // writes, not concurrent moves — the occupant lookup above is not locked
    // (a Firestore transaction would be needed for that). Each bottle keeps its
    // own owner, and its movement is journaled under that owner, not the actor.
    return await atomically(async (batch) => {
      await JournalCommand.bottleOut(
        source.userId,
        { type: 'out', beverageId: source.beverageId, row: source.row, col: source.col, date: now },
        batch,
      )
      const movedSource = await repository.save(
        { ...source, cellarId: cellar.id, row: targetRow, col: targetCol, updatedAt: now },
        batch,
      )
      await JournalCommand.bottleIn(
        source.userId,
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
          occupant.userId,
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
          {
            ...occupant,
            cellarId: source.cellarId,
            row: source.row,
            col: source.col,
            updatedAt: now,
          },
          batch,
        )
        await JournalCommand.bottleIn(
          occupant.userId,
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

  // Erase every trace of the user's cellars: their bottles and their solo
  // cellars. Only the deterministic solo `usr_<userId>` scope is dropped, never a
  // shared `hh_<householdId>` one: its cellars belong to the remaining members, and
  // the caller (account deletion) has already left the household. Resolving the
  // key by membership would be wrong here anyway, the just-removed membership can
  // still be memoized as present, pointing back at the shared cellars.
  export const deleteAllForUser = async (userId: UserId) => {
    const scopeKey = CellarQuery.soloConfigKey(userId)
    await repository.removeAllByUser(userId)
    for (const { id } of await repository.findSecondary(scopeKey))
      await repository.removeConfig(id, scopeKey)
    await repository.removeConfig(scopeKey)
  }

  // Wipe the user's cellar and restore the given bottles (account import).
  export const replaceAllForUser = async (userId: UserId, bottles: CellarBottle[]) => {
    await repository.removeAllByUser(userId)
    await bulkSave(bottles, repository.save)
  }
}
