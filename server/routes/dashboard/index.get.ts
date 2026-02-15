import { Cellar } from '~/cellar/index'
import { Wines } from '~/wine/index'
import type { Wine } from '~/wine/types'

export default defineEventHandler(async () => {
  const activeEntries = await Cellar.getActiveEntries()
  const allEntries = await Cellar.getAllEntries()
  const currentYear = new Date().getFullYear()

  // Bottle count
  const bottleCount = activeEntries.length

  // Ready to drink: active wines where drinkFrom <= currentYear <= drinkUntil
  const activeWines = await Promise.all(
    activeEntries.map(async (entry) => {
      const wine = await Wines.getById(entry.wineId)
      return wine !== 'not-found' ? wine : null
    }),
  )
  const readyToDrink = activeWines
    .filter((w): w is Wine => {
      if (!w) return false
      const from = w.drinkFrom as number | undefined
      const until = w.drinkUntil as number | undefined
      if (!from && !until) return false
      return (!from || from <= currentYear) && (!until || until >= currentYear)
    })
    .map((w) => ({
      id: w.id as string,
      name: w.name as string,
      color: w.color,
      domain: w.domain,
      vintage: w.vintage as number | undefined,
      region: w.region as string | undefined,
    }))

  // Last entry (most recent dateIn)
  const sortedByDateIn = [...allEntries].sort(
    (a, b) => new Date(b.dateIn).getTime() - new Date(a.dateIn).getTime(),
  )
  let lastEntry = null
  if (sortedByDateIn.length > 0) {
    const entry = sortedByDateIn[0]
    const wine = await Wines.getById(entry.wineId)
    if (wine !== 'not-found') {
      lastEntry = {
        wine: { id: wine.id as string, name: wine.name as string, color: wine.color, vintage: wine.vintage as number | undefined },
        position: `${entry.row}${entry.col}`,
        date: entry.dateIn,
      }
    }
  }

  // Last exit (most recent dateOut)
  const exits = allEntries.filter((e) => e.dateOut != null)
  const sortedByDateOut = exits.sort(
    (a, b) => new Date(b.dateOut!).getTime() - new Date(a.dateOut!).getTime(),
  )
  let lastExit = null
  if (sortedByDateOut.length > 0) {
    const entry = sortedByDateOut[0]
    const wine = await Wines.getById(entry.wineId)
    if (wine !== 'not-found') {
      lastExit = {
        wine: { id: wine.id as string, name: wine.name as string, color: wine.color, vintage: wine.vintage as number | undefined },
        position: `${entry.row}${entry.col}`,
        date: entry.dateOut,
        rating: entry.rating as number | undefined,
      }
    }
  }

  return { status: 200, data: { bottleCount, readyToDrink, lastEntry, lastExit } }
})
