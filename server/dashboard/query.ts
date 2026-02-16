import { sortBy } from 'lodash-es'
import { CellarQuery } from '~/cellar/query'
import type { CellarBottleView } from '~/cellar/types'
import { CellarLogQuery } from '~/cellar-log/query'
import type { DashboardView, LastBottle, ReadyToDrinkWine } from '~/dashboard/types'
import { WineQuery } from '~/wine/query'
import type { Wine } from '~/wine/types'

export namespace DashboardQuery {
  export const get = async (): Promise<DashboardView> => {
    const allBottles = await CellarQuery.getAllBottles()
    const currentYear = new Date().getFullYear()

    const wines = await Promise.all(
      allBottles.map(async (bottle) => {
        const wine = await WineQuery.getById(bottle.wineId)
        return wine !== 'not-found' ? wine : undefined
      }),
    )
    const activeWines = wines.filter((wine): wine is Wine => wine !== undefined)

    const bottleCount = allBottles.length
    const totalValue = activeWines.reduce((sum, wine) => sum + (wine.purchasePrice ?? 0), 0)
    const readyToDrink = activeWines
      .filter((wine) => isReadyToDrink(wine, currentYear))
      .map(toReadyToDrinkWine)

    const sortedBottles = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
    const lastBottle = await findLastBottle(sortedBottles[0])

    const history = await CellarLogQuery.getAll()
    const lastExit = history.find((event) => event.type === 'out')

    return {
      bottleCount,
      totalValue,
      readyToDrink,
      lastBottle,
      lastExit,
      history: history.slice(0, 10),
    }
  }

  const isReadyToDrink = (wine: Wine, currentYear: number) => {
    if (!wine.drinkFrom && !wine.drinkUntil) return false
    return (
      (!wine.drinkFrom || wine.drinkFrom <= currentYear) &&
      (!wine.drinkUntil || wine.drinkUntil >= currentYear)
    )
  }

  const toReadyToDrinkWine = (wine: Wine): ReadyToDrinkWine => ({
    id: wine.id,
    name: wine.name,
    color: wine.color,
    domain: wine.domain,
    vintage: wine.vintage,
    region: wine.region,
    appellation: wine.appellation,
  })

  const findLastBottle = async (bottle?: CellarBottleView): Promise<LastBottle | undefined> => {
    if (!bottle) return undefined
    const wine = await WineQuery.getById(bottle.wineId)
    if (wine === 'not-found') return undefined
    return {
      wine: {
        id: wine.id,
        name: wine.name,
        color: wine.color,
        vintage: wine.vintage,
      },
      position: `${bottle.rowLabel}${bottle.colLabel}`,
      date: bottle.createdAt,
    }
  }
}
