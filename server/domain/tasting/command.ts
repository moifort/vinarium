import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/tasting/infrastructure/repository'
import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'

export namespace TastingCommand {
  // Upsert a tasting note: overlay the provided fields onto any existing note
  // rather than overwriting the whole document. Since `favorite`, `rating` and
  // the consumption details all share one doc, a plain overwrite would silently
  // drop, e.g., a favorite flag when later recording a consumption. Callers pass
  // only the fields they mean to set (nulls stripped at the API boundary), so
  // the merge preserves everything they leave untouched.
  export const create = async (note: TastingNote) => {
    const existing = await repository.findBy(note.userId, note.wineId)
    return repository.save(existing ? { ...existing, ...note } : note)
  }

  // Toggle the favorite (heart) flag without clobbering an existing note:
  // read-modify-write so the rating and tasting notes survive the toggle.
  export const setFavorite = async (userId: UserId, wineId: WineId, favorite: boolean) => {
    const existing = await repository.findBy(userId, wineId)
    await repository.save({ ...(existing ?? { userId, wineId }), favorite })
  }

  export const removeWine = async (userId: UserId, wineId: WineId, batch?: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }
}
