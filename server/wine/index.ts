import { Cellar } from '~/cellar/index'
import { randomWineId } from '~/wine/primitives'
import type { Wine, WineColor, WineId, WineName } from '~/wine/types'

type WineSort = 'vintage' | 'region' | 'color' | 'price' | 'consumedDate'
type SortOrder = 'asc' | 'desc'
type WineStatus = 'in-cellar' | 'consumed' | 'all'

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

  export const list = async (options?: {
    color?: WineColor
    sort?: WineSort
    order?: SortOrder
    status?: WineStatus
    minRating?: number
  }) => {
    const storage = useStorage('wines')
    const keys = await storage.getKeys()
    const all = await Promise.all(keys.map((key) => storage.getItem<Wine>(key)))
    let wines = all.filter((wine): wine is Wine => wine !== null)

    // Color filter
    if (options?.color) {
      wines = wines.filter((w) => w.color === options.color)
    }

    // Status filter
    if (options?.status && options.status !== 'all') {
      const activeEntries = await Cellar.getActiveEntries()
      const inCellarIds = new Set(activeEntries.map((e) => e.wineId))
      if (options.status === 'in-cellar') {
        wines = wines.filter((w) => inCellarIds.has(w.id))
      } else if (options.status === 'consumed') {
        wines = wines.filter((w) => !inCellarIds.has(w.id))
      }
    }

    // Rating filter (rating lives on CellarEntry, cross-reference)
    if (options?.minRating) {
      const cellarStorage = useStorage('cellar')
      const entryKeys = await cellarStorage.getKeys('entries')
      const entries = await Promise.all(entryKeys.map((key) => cellarStorage.getItem<import('~/cellar/types').CellarEntry>(key)))
      const ratingByWineId = new Map<string, number>()
      for (const entry of entries) {
        if (entry?.rating != null) {
          const existing = ratingByWineId.get(entry.wineId)
          if (existing == null || entry.rating > existing) {
            ratingByWineId.set(entry.wineId, entry.rating)
          }
        }
      }
      wines = wines.filter((w) => (ratingByWineId.get(w.id) ?? 0) >= options.minRating!)
    }

    // Sort
    if (options?.sort) {
      const dir = options.order === 'desc' ? -1 : 1
      wines.sort((a, b) => {
        switch (options.sort) {
          case 'vintage':
            return ((a.vintage ?? 0) - (b.vintage ?? 0)) * dir
          case 'region':
            return (a.region ?? '').localeCompare(b.region ?? '') * dir
          case 'color':
            return a.color.localeCompare(b.color) * dir
          case 'price':
            return ((a.purchasePrice ?? 0) - (b.purchasePrice ?? 0)) * dir
          default:
            return 0
        }
      })
    }

    return wines
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
