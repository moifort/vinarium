import { sortBy } from 'lodash-es'
import { CellarQuery } from '~/cellar/query'
import { CellarLogQuery } from '~/cellar-log/query'
import type { DashboardView, LastBottle, ReadyToDrinkWine } from '~/dashboard/types'
import type { Wine } from '~/wine/types'

export namespace DashboardQuery {
  export const get = async (): Promise<DashboardView> => {
    const allBottles = await CellarQuery.getAllBottles()
    const currentYear = new Date().getFullYear()

    const wines = allBottles.map((b) => b.wine)
    const bottleCount = allBottles.length
    const totalValue = wines.reduce((sum, wine) => sum + (wine.purchasePrice ?? 0), 0)
    const readyToDrink = wines
      .filter((wine) => isReadyToDrink(wine, currentYear))
      .map(toReadyToDrinkWine)

    const sortedBottles = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
    const lastBottle = toLastBottle(sortedBottles[0])

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

  const toLastBottle = (bottle?: Awaited<ReturnType<typeof CellarQuery.getAllBottles>>[number]): LastBottle | undefined => {
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
}
