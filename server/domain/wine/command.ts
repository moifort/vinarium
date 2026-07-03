import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import { irrelevantAttributes, requiresColor } from '~/domain/wine/business-rules'
import * as repository from '~/domain/wine/infrastructure/repository'
import { randomWineId } from '~/domain/wine/primitives'
import type { BeverageType, Wine, WineId, WineName } from '~/domain/wine/types'

export namespace WineCommand {
  export const add = async (
    userId: UserId,
    name: WineName,
    beverageType: BeverageType,
    data: Partial<
      Omit<Wine, 'id' | 'userId' | 'name' | 'beverageType' | 'createdAt' | 'updatedAt'>
    >,
  ) => {
    if (requiresColor(beverageType) && !data.color) return 'color-required' as const
    const now = new Date()
    return await repository.save(
      withoutIrrelevantAttributes({
        ...data,
        id: randomWineId(),
        userId,
        name,
        beverageType,
        createdAt: now,
        updatedAt: now,
      }),
    )
  }

  export const update = async (
    userId: UserId,
    id: WineId,
    data: Partial<Omit<Wine, 'id' | 'userId' | 'createdAt' | 'updatedAt'>>,
  ) => {
    const existing = await repository.findBy(userId, id)
    if (!existing) return 'not-found' as const
    const updated = withoutIrrelevantAttributes({ ...existing, ...data, updatedAt: new Date() })
    if (requiresColor(updated.beverageType) && !updated.color) return 'color-required' as const
    return await repository.save(updated)
  }

  export const remove = async (userId: UserId, id: WineId, batch?: WriteBatch) => {
    const existing = await repository.findBy(userId, id)
    if (!existing) return 'not-found' as const
    await repository.remove(id, batch)
    return undefined
  }

  const withoutIrrelevantAttributes = (wine: Wine) => {
    const cleaned = { ...wine }
    for (const attribute of irrelevantAttributes(wine.beverageType)) delete cleaned[attribute]
    return cleaned
  }
}
