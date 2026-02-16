import { sortBy } from 'lodash-es'
import { CellarQuery } from '~/cellar/query'
import { CellarHistory } from '~/cellar-history/index'
import { Wines } from '~/wine/index'
import type { Wine } from '~/wine/types'

export default defineEventHandler(async () => {
  const allEntries = await CellarQuery.getAllEntries()
  const currentYear = new Date().getFullYear()

  const bottleCount = allEntries.length

  const activeWines = await Promise.all(
    allEntries.map(async (entry) => {
      const wine = await Wines.getById(entry.wineId)
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

  const sortedByCreatedAt = sortBy(allEntries, (entry) => -new Date(entry.createdAt).getTime())
  let lastEntry
  if (sortedByCreatedAt.length > 0) {
    const entry = sortedByCreatedAt[0]
    const wine = await Wines.getById(entry.wineId)
    if (wine !== 'not-found') {
      lastEntry = {
        wine: {
          id: wine.id as string,
          name: wine.name as string,
          color: wine.color,
          vintage: wine.vintage as number | undefined,
        },
        position: `${entry.rowLabel}${entry.colLabel}`,
        date: entry.createdAt,
      }
    }
  }

  const history = await CellarHistory.list()
  const lastExit = history.find((event) => event.type === 'exit')

  const recentHistory = history.slice(0, 10).map((event) => ({
    type: event.type,
    date: event.date,
    wineName: event.wineName,
    wineColor: event.wineColor,
    position: event.position,
    rating: event.rating,
  }))

  return {
    status: 200,
    data: { bottleCount, totalValue, readyToDrink, lastEntry, lastExit, history: recentHistory },
  }
})
