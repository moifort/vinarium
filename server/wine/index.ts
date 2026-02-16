import { maxBy, orderBy } from 'lodash-es'
import { CellarQuery } from '~/cellar/query'
import * as userLogRepository from '~/user-log/repository'
import { randomWineId } from '~/wine/primitives'
import * as repository from '~/wine/repository'
import type { Wine, WineColor, WineId, WineName } from '~/wine/types'

type WineSort = 'vintage' | 'region' | 'color' | 'price' | 'consumedDate'
type SortOrder = 'asc' | 'desc'
type WineStatus = 'in-cellar' | 'consumed' | 'all'

export namespace Wines {
  export const create = async (name: WineName, color: WineColor, data: Partial<Wine>) => {
    const id = randomWineId()
    const wine: Wine = {
      ...data,
      id,
      name,
      color,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    await repository.save(wine)
    return wine
  }

  export const getById = async (id: WineId) => {
    const wine = await repository.findBy(id)
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
    let wines = await repository.findAll()

    if (options?.color) {
      wines = wines.filter((wine) => wine.color === options.color)
    }

    if (options?.status && options.status !== 'all') {
      const activeEntries = await CellarQuery.getAllEntries()
      const inCellarIds = activeEntries.map((entry) => entry.wineId)
      if (options.status === 'in-cellar') {
        wines = wines.filter((wine) => inCellarIds.includes(wine.id))
      } else if (options.status === 'consumed') {
        wines = wines.filter((wine) => !inCellarIds.includes(wine.id))
      }
    }

    if (options?.minRating) {
      const logs = await userLogRepository.findAll()
      const bestRating = (wineId: string) =>
        maxBy(
          logs.filter((log) => log.wineId === wineId && log.rating != null),
          (log) => log.rating,
        )?.rating ?? 0
      wines = wines.filter((wine) => bestRating(wine.id) >= options.minRating!)
    }

    if (options?.sort) {
      const sortKey = (wine: Wine) => {
        switch (options.sort) {
          case 'vintage':
            return wine.vintage ?? 0
          case 'region':
            return wine.region ?? ''
          case 'color':
            return wine.color
          case 'price':
            return wine.purchasePrice ?? 0
          default:
            return 0
        }
      }
      wines = orderBy(wines, sortKey, options.order === 'desc' ? 'desc' : 'asc')
    }

    return wines
  }

  export const update = async (id: WineId, data: Partial<Wine>) => {
    const existing = await getById(id)
    if (existing === 'not-found') return 'not-found' as const
    const wine: Wine = {
      ...existing,
      ...data,
      updatedAt: new Date(),
    }
    await repository.save(wine)
    return wine
  }

  export const remove = async (id: WineId) => {
    const existing = await getById(id)
    if (existing === 'not-found') return 'not-found' as const
    await repository.remove(id)
    return
  }
}
