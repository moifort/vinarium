import type { CellarLogEntry } from '~/domain/cellar-log/types'
import type { WineId } from '~/domain/wine/types'

export const findAll = async () => {
  const storage = useStorage('cellar-log')
  const keys = await storage.getKeys('entries')
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<CellarLogEntry>(key))!))
}

export const findByWineId = async (wineId: WineId) => {
  const all = await findAll()
  return all.filter((entry) => entry.wineId === wineId)
}

export const save = async (entry: CellarLogEntry) => {
  const key = `entries:${Date.now()}-${entry.type}-${entry.wineId}`
  await useStorage('cellar-log').setItem<CellarLogEntry>(key, entry)
  return entry
}
