import type { Wine, WineId } from '~/domain/wine/types'

const storage = () => useStorage('wines')

export const findAll = async () => {
  const keys = await storage().getKeys()
  const items = await Promise.all(keys.map((key) => storage().getItem<Wine>(key)))
  return items.filter((item): item is Wine => item !== null)
}

export const findBy = (id: WineId) => storage().getItem<Wine>(id)

export const save = async (wine: Wine) => {
  await storage().setItem<Wine>(wine.id, wine)
  return wine
}

export const remove = async (id: WineId) => {
  await storage().removeItem(id)
}
