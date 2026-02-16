import { AI } from '~/ai/index'
import { CellarQuery } from '~/cellar/query'
import { Wines } from '~/wine/index'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const occasion = body?.occasion as string | undefined

  const entries = await CellarQuery.getAllEntries()
  const wineIds = entries.map((entry) => String(entry.wineId))
  const allWines = await Wines.list()
  const inCellar = allWines.filter((wine) => wineIds.includes(String(wine.id)))

  const advice = await AI.getAdvice(inCellar, occasion)
  return { status: 200, data: { advice } }
})
