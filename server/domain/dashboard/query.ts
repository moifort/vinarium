import { keyBy, sortBy } from 'lodash-es'
import { CellarQuery } from '~/domain/cellar/query'
import type { FavoriteWine, LastBottle, ReadyToDrinkWine } from '~/domain/dashboard/types'
import { JournalQuery } from '~/domain/journal/query'
import { TastingQuery } from '~/domain/tasting/query'
import type { TastingNote } from '~/domain/tasting/types'
import * as _wineRepository from '~/domain/wine/repository'
import type { Wine } from '~/domain/wine/types'
import { traced, tracedModule } from '~/system/sentry/tracing'

const wineRepository = tracedModule('wine', 'db', _wineRepository)

export namespace DashboardQuery {
  export const get = traced('DashboardQuery.get', 'domain.query', async () => {
    const [allBottles, history, allTastings, wines] = await Promise.all([
      CellarQuery.getAllBottles(),
      JournalQuery.getAll(),
      TastingQuery.getAll(),
      wineRepository.findAll(),
    ])

    const currentYear = new Date().getFullYear()
    const wineMap = keyBy(wines, 'id')

    const bottleCount = allBottles.length
    const totalValue = allBottles.reduce((sum, b) => sum + (b.wine.purchasePrice ?? 0), 0)
    const readyToDrink = sortBy(
      allBottles
        .filter((b) => isReadyToDrink(b.wine, currentYear))
        .map((b) => toReadyToDrinkWine(b, currentYear)),
      (w) => (w.urgent ? 0 : 1),
      (w) => w.drinkUntil ?? Infinity,
    )

    const sortedBottles = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
    const lastBottle = toLastBottle(sortedBottles[0])

    const lastExit = history.find((event) => event.type === 'out')

    const favorites = loadFavorites(
      allTastings.filter(({ rating }) => rating === 5),
      wineMap,
    )

    return {
      bottleCount,
      totalValue,
      readyToDrink,
      favorites,
      lastBottle,
      lastExit,
      history: history.slice(0, 10),
    }
  })

  const isReadyToDrink = (wine: Wine, currentYear: number) => {
    if (!wine.drinkFrom && !wine.drinkUntil) return false
    return (
      (!wine.drinkFrom || wine.drinkFrom <= currentYear) &&
      (!wine.drinkUntil || wine.drinkUntil >= currentYear)
    )
  }

  const toReadyToDrinkWine = (
    bottle: Awaited<ReturnType<typeof CellarQuery.getAllBottles>>[number],
    currentYear: number,
  ): ReadyToDrinkWine => ({
    id: bottle.wine.id,
    name: bottle.wine.name,
    color: bottle.wine.color,
    position: `${bottle.rowLabel}${bottle.colLabel}`,
    urgent: !!bottle.wine.drinkUntil && bottle.wine.drinkUntil <= currentYear + 1,
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
        color: bottle.wine.color,
        vintage: bottle.wine.vintage,
      },
      position: `${bottle.rowLabel}${bottle.colLabel}`,
      date: bottle.createdAt,
    }
  }

  const loadFavorites = (tastings: TastingNote[], wineMap: Record<string, Wine>) =>
    tastings
      .map((tasting) => {
        const wine = wineMap[tasting.wineId]
        if (!wine) return undefined
        const favorite: FavoriteWine = {
          id: wine.id,
          name: wine.name,
          color: wine.color,
          vintage: wine.vintage,
          estimatedPrice: wine.purchasePrice,
          tastingDate: tasting.consumedDate,
        }
        return favorite
      })
      .filter((favorite): favorite is FavoriteWine => favorite !== undefined)
}
