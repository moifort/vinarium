import type { UserLogEntry } from '~/user-log/types'
import type { WineId } from '~/wine/types'

export const getAll = async () => {
  const storage = useStorage('user-log')
  const keys = await storage.getKeys('entries')
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<UserLogEntry>(key))!))
}

export const getByWineId = async (wineId: WineId) => {
  return useStorage('user-log').getItem<UserLogEntry>(`entries:${wineId}`)
}

export const save = async (entry: UserLogEntry) => {
  await useStorage('user-log').setItem<UserLogEntry>(`entries:${entry.wineId}`, entry)
}
