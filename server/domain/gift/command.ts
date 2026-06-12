import type { WriteBatch } from 'firebase-admin/firestore'
import * as repository from '~/domain/gift/infrastructure/repository'
import type { Gift } from '~/domain/gift/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'

export namespace GiftCommand {
  export const giveTo = async (gift: Gift) => repository.save(gift)

  export const removeWine = async (userId: UserId, wineId: WineId, batch?: WriteBatch) => {
    await repository.remove(userId, wineId, batch)
  }
}
