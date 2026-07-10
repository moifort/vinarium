import { keyBy, sortBy } from 'lodash-es'
import {
  isFavorite,
  readyToDrink as isReadyToDrink,
  urgentToDrink,
  wineDetails,
} from '~/domain/beverage/business-rules'
import { BeverageQuery } from '~/domain/beverage/query'
import type { Beverage } from '~/domain/beverage/types'
import { CellarQuery } from '~/domain/cellar/query'
import { CELLAR_SIZE, type CellarBottleWithWine } from '~/domain/cellar/types'
import { JournalQuery } from '~/domain/journal/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import type { TastingNote } from '~/domain/tasting/types'
import type { DashboardView, FavoriteWine, LastBottle, ReadyToDrinkWine } from './types'

// Dashboard sections are a glanceable preview, not a full list — cap each one.
const DASHBOARD_SECTION_LIMIT = 5

export namespace DashboardQuery {
  export const view = async (userId: UserId): Promise<DashboardView> => {
    // The per-request cache dedupes the shared wines read across these queries.
    // bottleCount reflects the whole shared cellar (occupancy is a household fact);
    // every other section below stays personal, computed from the viewer's bottles.
    const [allBottles, history, allTastings, wines, bottleCount] = await Promise.all([
      CellarQuery.bottlesWithWine(userId),
      JournalQuery.all(userId),
      TastingQuery.all(userId),
      BeverageQuery.findAll(userId),
      CellarQuery.householdBottleCount(userId),
    ])

    const currentYear = new Date().getFullYear()
    const beverageMap = keyBy(wines, 'id')

    const totalValue = allBottles.reduce((sum, b) => sum + (b.wine.purchase?.price ?? 0), 0)

    const readyToDrink = sortBy(
      allBottles
        .filter((b) => isReadyToDrink(wineDetails(b.wine)?.drinkWindow ?? {}, currentYear))
        .map((b) => toReadyToDrinkWine(b, currentYear)),
      (w) => (w.urgent ? 0 : 1),
      (w) => w.drinkUntil ?? Number.POSITIVE_INFINITY,
    ).slice(0, DASHBOARD_SECTION_LIMIT)

    const sortedBottles = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
    const lastBottle = toLastBottle(sortedBottles[0])

    const lastExit = history.find((event) => event.type === 'out')

    const favorites = loadFavorites(allTastings.filter(isFavorite), beverageMap).slice(
      0,
      DASHBOARD_SECTION_LIMIT,
    )

    return {
      bottleCount,
      capacity: CELLAR_SIZE.rows * CELLAR_SIZE.cols,
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
  ): ReadyToDrinkWine => {
    const details = wineDetails(bottle.wine)
    return {
      id: bottle.wine.id,
      name: bottle.wine.name,
      beverageType: bottle.wine.beverageType,
      color: details?.color,
      position: `${bottle.rowLabel}${bottle.colLabel}`,
      urgent: urgentToDrink(details?.drinkWindow ?? {}, currentYear),
      drinkUntil: details?.drinkWindow?.until,
    }
  }

  const toLastBottle = (bottle?: CellarBottleWithWine): LastBottle | undefined => {
    if (!bottle) return undefined
    const details = wineDetails(bottle.wine)
    return {
      wine: {
        id: bottle.wine.id,
        name: bottle.wine.name,
        beverageType: bottle.wine.beverageType,
        color: details?.color,
        vintage: details?.vintage,
      },
      position: `${bottle.rowLabel}${bottle.colLabel}`,
      date: bottle.createdAt,
    }
  }

  const loadFavorites = (
    tastings: TastingNote[],
    beverageMap: Record<string, Beverage>,
  ): FavoriteWine[] =>
    tastings
      .map((tasting): FavoriteWine | undefined => {
        const wine = beverageMap[tasting.beverageId]
        if (!wine) return undefined
        const details = wineDetails(wine)
        return {
          id: wine.id,
          name: wine.name,
          beverageType: wine.beverageType,
          color: details?.color,
          vintage: details?.vintage,
          estimatedPrice: wine.purchase?.price,
          tastingDate: tasting.consumedDate,
          rating: tasting.rating,
        }
      })
      .filter((favorite): favorite is FavoriteWine => favorite !== undefined)
}
