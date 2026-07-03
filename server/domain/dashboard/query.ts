import { keyBy, sortBy } from 'lodash-es'
import { CellarQuery } from '~/domain/cellar/query'
import { JournalQuery } from '~/domain/journal/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import type { TastingNote } from '~/domain/tasting/types'
import {
  isFavorite,
  readyToDrink as isReadyToDrink,
  isShortlisted,
  urgentToDrink,
} from '~/domain/wine/business-rules'
import { WineQuery } from '~/domain/wine/query'
import type { Wine } from '~/domain/wine/types'
import type {
  DashboardView,
  FavoriteWine,
  LastBottle,
  ReadyToDrinkWine,
  ShortlistWine,
} from './types'

export namespace DashboardQuery {
  export const get = async (userId: UserId): Promise<DashboardView> => {
    // Fetch the wines collection once and share it with the sub-queries
    const winesPromise = WineQuery.findAll(userId)
    const [allBottles, history, allTastings, wines] = await Promise.all([
      CellarQuery.getAllBottles(userId, winesPromise),
      JournalQuery.getAll(userId, winesPromise),
      TastingQuery.getAll(userId),
      winesPromise,
    ])

    const currentYear = new Date().getFullYear()
    const wineMap = keyBy(wines, 'id')

    const bottleCount = allBottles.length
    const totalValue = allBottles.reduce((sum, b) => sum + (b.wine.purchasePrice ?? 0), 0)

    const readyToDrink = sortBy(
      allBottles
        .filter((b) =>
          isReadyToDrink({ from: b.wine.drinkFrom, until: b.wine.drinkUntil }, currentYear),
        )
        .map((b) => toReadyToDrinkWine(b, currentYear)),
      (w) => (w.urgent ? 0 : 1),
      (w) => w.drinkUntil ?? Number.POSITIVE_INFINITY,
    )

    const sortedBottles = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
    const lastBottle = toLastBottle(sortedBottles[0])

    const lastExit = history.find((event) => event.type === 'out')

    const favorites = loadFavorites(
      allTastings.filter(({ rating }) => isFavorite(rating)),
      wineMap,
    )

    const shortlist = loadShortlist(
      allTastings.filter((t) => isShortlisted(t) && !isFavorite(t.rating)),
      wineMap,
    )

    return {
      bottleCount,
      totalValue,
      readyToDrink,
      favorites,
      shortlist,
      lastBottle,
      lastExit,
      history: history.slice(0, 10),
    }
  }

  const toReadyToDrinkWine = (
    bottle: Awaited<ReturnType<typeof CellarQuery.getAllBottles>>[number],
    currentYear: number,
  ): ReadyToDrinkWine => ({
    id: bottle.wine.id,
    name: bottle.wine.name,
    beverageType: bottle.wine.beverageType,
    color: bottle.wine.color,
    position: `${bottle.rowLabel}${bottle.colLabel}`,
    urgent: urgentToDrink({ until: bottle.wine.drinkUntil }, currentYear),
    drinkUntil: bottle.wine.drinkUntil,
  })

  const toLastBottle = (
    bottle?: Awaited<ReturnType<typeof CellarQuery.getAllBottles>>[number],
  ): LastBottle | undefined => {
    if (!bottle) return undefined
    return {
      wine: {
        id: bottle.wine.id,
        name: bottle.wine.name,
        beverageType: bottle.wine.beverageType,
        color: bottle.wine.color,
        vintage: bottle.wine.vintage,
      },
      position: `${bottle.rowLabel}${bottle.colLabel}`,
      date: bottle.createdAt,
    }
  }

  const loadFavorites = (tastings: TastingNote[], wineMap: Record<string, Wine>): FavoriteWine[] =>
    tastings
      .map((tasting): FavoriteWine | undefined => {
        const wine = wineMap[tasting.wineId]
        if (!wine) return undefined
        return {
          id: wine.id,
          name: wine.name,
          beverageType: wine.beverageType,
          color: wine.color,
          vintage: wine.vintage,
          estimatedPrice: wine.purchasePrice,
          tastingDate: tasting.consumedDate,
        }
      })
      .filter((favorite): favorite is FavoriteWine => favorite !== undefined)

  const loadShortlist = (tastings: TastingNote[], wineMap: Record<string, Wine>): ShortlistWine[] =>
    tastings
      .map((tasting): ShortlistWine | undefined => {
        const wine = wineMap[tasting.wineId]
        if (!wine) return undefined
        return {
          id: wine.id,
          name: wine.name,
          beverageType: wine.beverageType,
          color: wine.color,
          vintage: wine.vintage,
          estimatedPrice: wine.purchasePrice,
          tastingDate: tasting.consumedDate,
          rating: tasting.rating,
        }
      })
      .filter((entry): entry is ShortlistWine => entry !== undefined)
}
