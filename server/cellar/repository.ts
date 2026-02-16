import type { CellarEntry } from '~/cellar/types'
import type { WineId } from '~/wine/types'

export const getAll = async () => {
  const storage = useStorage('cellar')
  const keys = await storage.getKeys('entries')
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<CellarEntry>(key))!))
}

export const getByWineId = async (wineId: WineId) => {
  return useStorage('cellar').getItem<CellarEntry>(`entries:${wineId}`)
}

export const save = async (entry: CellarEntry) => {
  await useStorage('cellar').setItem<CellarEntry>(`entries:${entry.wineId}`, entry)
}

export const remove = async (wineId: WineId) => {
  await useStorage('cellar').removeItem(`entries:${wineId}`)
}
