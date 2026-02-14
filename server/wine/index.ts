import { randomWineId } from '~/wine/primitives'
import type { Wine, WineColor, WineId, WineName } from '~/wine/types'

export namespace Wines {
  export const create = async (name: WineName, color: WineColor, data: Partial<Wine>) => {
    const storage = useStorage('wines')
    const id = randomWineId()
    const wine: Wine = {
      ...data,
      id,
      name,
      color,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    await storage.setItem<Wine>(id, wine)
    return wine
  }

  export const getById = async (id: WineId) => {
    const storage = useStorage('wines')
    const wine = await storage.getItem<Wine>(id)
    if (!wine) return 'not-found' as const
    return wine
  }

  export const list = async (filterByColor?: WineColor) => {
    const storage = useStorage('wines')
    const keys = await storage.getKeys()
    const all = await Promise.all(keys.map((key) => storage.getItem<Wine>(key)))
    return all
      .filter((wine) => wine !== null)
      .filter(({ color }) => !filterByColor || filterByColor === color)
  }

  export const update = async (id: WineId, data: Partial<Wine>) => {
    const storage = useStorage('wines')
    const existing = await getById(id)
    if (existing === 'not-found') return 'not-found' as const
    const wine: Wine = {
      ...existing,
      ...data,
      updatedAt: new Date(),
    }
    await storage.setItem<Wine>(id, wine)
    return wine
  }

  export const remove = async (id: WineId) => {
    const storage = useStorage('wines')
    const existing = await getById(id)
    if (existing === 'not-found') return 'not-found' as const
    await storage.removeItem(id)
    return 'ok' as const
  }
}
