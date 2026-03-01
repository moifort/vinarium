import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'

const storage = () => useStorage('tasting')

export const findAll = async () => {
  const keys = await storage().getKeys('entries')
  const items = await storage().getItems<TastingNote>(keys)
  return items.map(({ value }) => value)
}

export const findBy = (wineId: WineId) => storage().getItem<TastingNote>(`entries:${wineId}`)

export const save = async (note: TastingNote) => {
  await storage().setItem<TastingNote>(`entries:${note.wineId}`, note)
  return note
}

export const remove = async (wineId: WineId) => {
  await storage().removeItem(`entries:${wineId}`)
}
