import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/wine/infrastructure/repository'
import { randomWineId } from '~/domain/wine/primitives'
import type { Wine, WineColor, WineId, WineName } from '~/domain/wine/types'

export namespace WineCommand {
  export const add = async (
    userId: UserId,
    name: WineName,
    color: WineColor,
    data: Partial<Omit<Wine, 'id' | 'userId' | 'name' | 'color' | 'createdAt' | 'updatedAt'>>,
  ) => {
    const now = new Date()
    return await repository.save({
      ...data,
      id: randomWineId(),
      userId,
      name,
      color,
      createdAt: now,
      updatedAt: now,
    })
  }

  export const update = async (
    userId: UserId,
    id: WineId,
    data: Partial<Omit<Wine, 'id' | 'userId' | 'createdAt' | 'updatedAt'>>,
  ) => {
    const existing = await repository.findBy(userId, id)
    if (!existing) return 'not-found' as const
    return await repository.save({
      ...existing,
      ...data,
      updatedAt: new Date(),
    })
  }

  export const remove = async (userId: UserId, id: WineId, batch?: WriteBatch) => {
    const existing = await repository.findBy(userId, id)
    if (!existing) return 'not-found' as const
    await repository.remove(id, batch)
    return undefined
  }
}
