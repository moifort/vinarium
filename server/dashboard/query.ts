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
    const readyToDrink = sortBy(
      wines
        .filter((wine) => isUrgentToDrink(wine, currentYear))
        .map(toReadyToDrinkWine),
      (w) => w.drinkUntil ?? Infinity,
    )

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

  const isUrgentToDrink = (wine: Wine, currentYear: number) => {
    if (!wine.drinkUntil) return false
    const isReady = !wine.drinkFrom || wine.drinkFrom <= currentYear
    const isUrgent = wine.drinkUntil <= currentYear + 1
    return isReady && isUrgent && wine.drinkUntil >= currentYear
  }

  const toReadyToDrinkWine = (wine: Wine): ReadyToDrinkWine => ({
    id: wine.id,
    name: wine.name,
    color: wine.color,
    domain: wine.domain,
    vintage: wine.vintage,
    region: wine.region,
    appellation: wine.appellation,
    drinkUntil: wine.drinkUntil,
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
