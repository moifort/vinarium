import { keyBy, sortBy } from 'lodash-es'
import {
  readyToDrink as isReadyToDrink,
  urgentToDrink,
  wineDetails,
} from '~/domain/beverage/business-rules'
import { BeverageQuery } from '~/domain/beverage/query'
import type { Beverage } from '~/domain/beverage/types'
import { CellarQuery } from '~/domain/cellar/query'
import type { CellarBottleWithWine } from '~/domain/cellar/types'
import { HouseholdQuery } from '~/domain/household/query'
import { JournalQuery } from '~/domain/journal/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import type { TastingNote } from '~/domain/tasting/types'
import type { DashboardView, FavoriteWine, LastBottle, ReadyToDrinkWine } from './types'

// Dashboard sections are a glanceable preview, not a full list — cap each one.
const DASHBOARD_SECTION_LIMIT = 5

export namespace DashboardQuery {
  export const view = async (userId: UserId): Promise<DashboardView> => {
    // Every read here is bounded: the placed bottles (with their wines by id), a
    // page of the journal, the single latest exit and the viewer's favorited
    // notes — never a scan of the whole library or journal. Sharing a cellar
    // shares what the cellar holds: its bottles, their value and every movement
    // span the whole household. Favorites stay personal — they are filtered by
    // the viewer's own tasting notes.
    const [allBottles, historyPage, lastExit, favoriteTastings, cellarConfig] = await Promise.all([
      CellarQuery.householdBottlesWithWine(userId),
      JournalQuery.page(userId, { limit: DASHBOARD_SECTION_LIMIT, offset: 0 }),
      JournalQuery.latestExit(userId),
      TastingQuery.favorites(userId),
      CellarQuery.config(userId),
    ])

    const currentYear = new Date().getFullYear()

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

    const favorites = await loadFavorites(userId, favoriteTastings, allBottles)

    return {
      bottleCount: allBottles.length,
      capacity: cellarConfig.rows * cellarConfig.cols,
      totalValue,
      readyToDrink,
      favorites,
      lastBottle,
      lastExit,
      history: historyPage.items,
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

  // The wines the viewer's favorite notes point at, loaded by id and kept only
  // when visible to them: their own wine, or a housemate's currently in the
  // shared cellar (already loaded with the bottles) — the same visibility rule
  // as the wine list, without its library scan. Truncated before the wine load
  // so the section never costs more than its display cap in reads; a favorite
  // whose wine is gone leaves a shorter section rather than widening the read.
  const loadFavorites = async (
    userId: UserId,
    tastings: TastingNote[],
    allBottles: CellarBottleWithWine[],
  ): Promise<FavoriteWine[]> => {
    const favorites = tastings.slice(0, DASHBOARD_SECTION_LIMIT)
    if (favorites.length === 0) return []
    const scope = await HouseholdQuery.cellarScope(userId)
    const wines = await BeverageQuery.byBeverageIdsForUsers(
      scope.memberIds,
      favorites.map(({ beverageId }) => beverageId),
    )
    const placed = new Set(allBottles.map(({ beverageId }) => beverageId))
    const visible = keyBy(
      wines.filter((wine) => wine.userId === userId || placed.has(wine.id)),
      'id',
    )
    return favorites
      .map((tasting): FavoriteWine | undefined => {
        const wine: Beverage | undefined = visible[tasting.beverageId]
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
}
