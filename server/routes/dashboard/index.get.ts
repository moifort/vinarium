import { sortBy } from 'lodash-es'
import { CellarQuery } from '~/cellar/query'
import { CellarLogQuery } from '~/cellar-log/query'
import { Wines } from '~/wine/index'
import type { Wine } from '~/wine/types'

export default defineEventHandler(async () => {
  const allBottles = await CellarQuery.getAllBottles()
  const currentYear = new Date().getFullYear()

  const bottleCount = allBottles.length

  const activeWines = await Promise.all(
    allBottles.map(async (bottle) => {
      const wine = await Wines.getById(bottle.wineId)
      return wine !== 'not-found' ? wine : null
    }),
  )
  const readyToDrink = activeWines
    .filter((wine): wine is Wine => {
      if (!wine) return false
      const from = wine.drinkFrom as number | undefined
      const until = wine.drinkUntil as number | undefined
      if (!from && !until) return false
      return (!from || from <= currentYear) && (!until || until >= currentYear)
    })
    .map((wine) => ({
      id: wine.id as string,
      name: wine.name as string,
      color: wine.color,
      domain: wine.domain,
      vintage: wine.vintage as number | undefined,
      region: wine.region as string | undefined,
    }))

  const totalValue = activeWines
    .filter((wine): wine is Wine => wine !== null)
    .reduce((sum, wine) => sum + ((wine.purchasePrice as number | undefined) ?? 0), 0)

  const sortedByCreatedAt = sortBy(allBottles, (bottle) => -new Date(bottle.createdAt).getTime())
  let lastBottle
  if (sortedByCreatedAt.length > 0) {
    const bottle = sortedByCreatedAt[0]
    const wine = await Wines.getById(bottle.wineId)
    if (wine !== 'not-found') {
      lastBottle = {
        wine: {
          id: wine.id as string,
          name: wine.name as string,
          color: wine.color,
          vintage: wine.vintage as number | undefined,
        },
        position: `${bottle.rowLabel}${bottle.colLabel}`,
        date: bottle.createdAt,
      }
    }
  }

  const history = await CellarLogQuery.getAll()
  const lastExit = history.find((event) => event.type === 'out')

  const recentHistory = history.slice(0, 10)

  return {
    status: 200,
    data: { bottleCount, totalValue, readyToDrink, lastBottle, lastExit, history: recentHistory },
  }
})
