import { AI } from '~/ai/index'
import { Cellar } from '~/cellar/index'
import { Wines } from '~/wine/index'

export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  const occasion = body?.occasion as string | undefined

  // Get only wines currently in cellar
  const entries = await Cellar.getActiveEntries()
  const wineIds = new Set(entries.map((e) => String(e.wineId)))
  const allWines = await Wines.list()
  const inCellar = allWines.filter((w) => wineIds.has(String(w.id)))

  const advice = await AI.getAdvice(inCellar, occasion)
  return { status: 200, data: { advice } }
})
