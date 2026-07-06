import { keyBy, sortBy } from 'lodash-es'
import { CellarQuery } from '~/domain/cellar/query'
import type { CellarBottleWithWine } from '~/domain/cellar/types'
import { JournalQuery } from '~/domain/journal/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import type { TastingNote } from '~/domain/tasting/types'
import {
  isFavorite,
  readyToDrink as isReadyToDrink,
  urgentToDrink,
} from '~/domain/wine/business-rules'
import { WineQuery } from '~/domain/wine/query'
import type { Wine } from '~/domain/wine/types'
import type { DashboardView, FavoriteWine, LastBottle, ReadyToDrinkWine } from './types'

// Dashboard sections are a glanceable preview, not a full list — cap each one.
const DASHBOARD_SECTION_LIMIT = 5

export namespace DashboardQuery {
  export const view = async (userId: UserId): Promise<DashboardView> => {
    // The per-request cache dedupes the shared wines read across these queries.
    const [allBottles, history, allTastings, wines] = await Promise.all([
      CellarQuery.bottlesWithWine(userId),
      JournalQuery.all(userId),
      TastingQuery.all(userId),
      WineQuery.findAll(userId),
    ])

    const currentYear = new Date().getFullYear()
    const wineMap = keyBy(wines, 'id')

    const bottleCount = allBottles.length
    const totalValue = allBottles.reduce((sum, b) => sum + (b.wine.purchase?.price ?? 0), 0)

    const readyToDrink = sortBy(
      allBottles
        .filter((b) => isReadyToDrink(b.wine.drinkWindow ?? {}, currentYear))
        .map((b) => toReadyToDrinkWine(b, currentYear)),
      (w) => (w.urgent ? 0 : 1),
      (w) => w.drinkUntil ?? Number.POSITIVE_INFINITY,
    ).slice(0, DASHBOARD_SECTION_LIMIT)

    const sortedBottles = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
    const lastBottle = toLastBottle(sortedBottles[0])

    const lastExit = history.find((event) => event.type === 'out')

    const favorites = loadFavorites(allTastings.filter(isFavorite), wineMap).slice(
      0,
      DASHBOARD_SECTION_LIMIT,
    )

    return {
      bottleCount,
      totalValue,
      readyToDrink,
      favorites,
      lastBottle,
      lastExit,
      history: history.slice(0, DASHBOARD_SECTION_LIMIT),
    }
  }

  const toReadyToDrinkWine = (
    bottle: CellarBottleWithWine,
    currentYear: number,
  ): ReadyToDrinkWine => ({
    id: bottle.wine.id,
    name: bottle.wine.name,
    beverageType: bottle.wine.beverageType,
    color: bottle.wine.color,
    position: `${bottle.rowLabel}${bottle.colLabel}`,
    urgent: urgentToDrink(bottle.wine.drinkWindow ?? {}, currentYear),
    drinkUntil: bottle.wine.drinkWindow?.until,
  })

  const toLastBottle = (bottle?: CellarBottleWithWine): LastBottle | undefined => {
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
          estimatedPrice: wine.purchase?.price,
          tastingDate: tasting.consumedDate,
          rating: tasting.rating,
        }
      })
      .filter((favorite): favorite is FavoriteWine => favorite !== undefined)
}
