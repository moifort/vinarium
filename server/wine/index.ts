import { maxBy, orderBy } from 'lodash-es'
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
    // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
    let wines = await Promise.all(keys.map(async (key) => (await storage.getItem<Wine>(key))!))

    if (options?.color) {
      wines = wines.filter((wine) => wine.color === options.color)
    }

    if (options?.status && options.status !== 'all') {
      const activeEntries = await Cellar.getActiveEntries()
      const inCellarIds = activeEntries.map((entry) => entry.wineId)
      if (options.status === 'in-cellar') {
        wines = wines.filter((wine) => inCellarIds.includes(wine.id))
      } else if (options.status === 'consumed') {
        wines = wines.filter((wine) => !inCellarIds.includes(wine.id))
      }
    }

    if (options?.minRating) {
      const cellarStorage = useStorage('cellar')
      const entryKeys = await cellarStorage.getKeys('entries')
      // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
      const entries = await Promise.all(entryKeys.map(async (key) => (await cellarStorage.getItem<import('~/cellar/types').CellarEntry>(key))!))
      const bestRating = (wineId: string) =>
        maxBy(
          entries.filter((entry) => entry.wineId === wineId && entry.rating != null),
          (entry) => entry.rating,
        )?.rating ?? 0
      wines = wines.filter((wine) => bestRating(wine.id) >= options.minRating!)
    }

    if (options?.sort) {
      const sortKey = (wine: Wine) => {
        switch (options.sort) {
          case 'vintage': return wine.vintage ?? 0
          case 'region': return wine.region ?? ''
          case 'color': return wine.color
          case 'price': return wine.purchasePrice ?? 0
          default: return 0
        }
      }
      wines = orderBy(wines, sortKey, options.order === 'desc' ? 'desc' : 'asc')
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
