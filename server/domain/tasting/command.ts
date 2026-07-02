import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/tasting/infrastructure/repository'
import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'

export namespace TastingCommand {
  export const create = async (note: TastingNote) => repository.save(note)

  export const removeWine = async (userId: UserId, wineId: WineId, batch?: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }
}
