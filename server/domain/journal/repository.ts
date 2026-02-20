import type { JournalEntry } from '~/domain/journal/types'
import type { WineId } from '~/domain/wine/types'

export const findAll = async () => {
  const storage = useStorage('journal')
  const keys = await storage.getKeys('entries')
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<JournalEntry>(key))!))
}

export const findByWineId = async (wineId: WineId) => {
  const all = await findAll()
  return all.filter((entry) => entry.wineId === wineId)
}

export const removeByWineId = async (wineId: WineId) => {
  const storage = useStorage('journal')
  const keys = await storage.getKeys('entries')
  const entries = await Promise.all(
    keys.map(async (key) => ({ key, entry: await storage.getItem<JournalEntry>(key) })),
  )
  const keysToRemove = entries
    .filter(({ entry }) => entry?.wineId === wineId)
    .map(({ key }) => key)
  await Promise.all(keysToRemove.map((key) => storage.removeItem(key)))
}

export const save = async (entry: JournalEntry) => {
  const key = `entries:${Date.now()}-${entry.type}-${entry.wineId}`
  await useStorage('journal').setItem<JournalEntry>(key, entry)
  return entry
}
