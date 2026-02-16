import type { CellarHistoryEntry } from '~/cellar-history/types'
import type { WineId } from '~/wine/types'

export const getAll = async () => {
  const storage = useStorage('cellar-history')
  const keys = await storage.getKeys('entries')
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<CellarHistoryEntry>(key))!))
}

export const getByWineId = async (wineId: WineId) => {
  return useStorage('cellar-history').getItem<CellarHistoryEntry>(`entries:${wineId}`)
}

export const save = async (entry: CellarHistoryEntry) => {
  await useStorage('cellar-history').setItem<CellarHistoryEntry>(`entries:${entry.wineId}`, entry)
}
