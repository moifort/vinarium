import { randomWineId } from '~/wine/primitives'
import * as repository from '~/wine/repository'
import type { Wine, WineColor, WineId, WineName } from '~/wine/types'

export namespace WineCommand {
  export const add = async (name: WineName, color: WineColor, data: Partial<Wine>) => {
    return await repository.save({
      ...data,
      id: randomWineId(),
      name,
      color,
      createdAt: new Date(),
      updatedAt: new Date(),
    })
  }

  export const update = async (id: WineId, data: Partial<Wine>) => {
    const existing = await repository.findBy(id)
    if (!existing) return 'not-found' as const
    return await repository.save({
      ...existing,
      ...data,
      updatedAt: new Date(),
    })
  }

  export const remove = async (id: WineId) => {
    const existing = await repository.findBy(id)
    if (!existing) return 'not-found' as const
    await repository.remove(id)
    return
  }
}
