import type { CellarBottle } from '~/domain/cellar/types'
import type { WineId } from '~/domain/wine/types'

export const findAll = async () => {
  const storage = useStorage('cellar')
  const keys = await storage.getKeys('entries')
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<CellarBottle>(key))!))
}

export const findBy = (wineId: WineId) =>
  useStorage('cellar').getItem<CellarBottle>(`entries:${wineId}`)

export const save = async (entry: CellarBottle) => {
  const existing = await findBy(entry.wineId)
  if (existing) throw new Error(`Cellar entry already exists for wineId: ${entry.wineId}`)
  await useStorage('cellar').setItem<CellarBottle>(`entries:${entry.wineId}`, entry)
  return entry
}

export const remove = async (wineId: WineId) => {
  await useStorage('cellar').removeItem(`entries:${wineId}`)
}
