import type { JournalEntry } from '~/domain/journal/types'
import type { WineId } from '~/domain/wine/types'

export const findAll = async () => {
  const storage = useStorage('journal')
  const keys = await storage.getKeys('by-wine')
  const groups = await Promise.all(
    keys.map(async (key) => (await storage.getItem<JournalEntry[]>(key)) ?? []),
  )
  return groups.flat()
}

export const findByWineId = async (wineId: WineId) => {
  return (await useStorage('journal').getItem<JournalEntry[]>(`by-wine:${wineId}`)) ?? []
}

export const removeByWineId = async (wineId: WineId) => {
  await useStorage('journal').removeItem(`by-wine:${wineId}`)
}

export const save = async (entry: JournalEntry) => {
  const storage = useStorage('journal')
  const key = `by-wine:${entry.wineId}`
  const existing = (await storage.getItem<JournalEntry[]>(key)) ?? []
  await storage.setItem<JournalEntry[]>(key, [...existing, entry])
  return entry
}
