import type { Wine, WineId } from '~/domain/wine/types'

const storage = () => useStorage('wines')
const imageStorage = () => useStorage('wine-images')

export const findAll = async () => {
  const keys = await storage().getKeys()
  const items = await storage().getItems<Wine>(keys)
  return items.map(({ value }) => value)
}

export const findBy = (id: WineId) => storage().getItem<Wine>(id)

export const findImageBy = (id: WineId) => imageStorage().getItem<string>(id)

export const save = async (wine: Wine) => {
  const { imageBase64, ...data } = wine
  if (imageBase64) await imageStorage().setItem(wine.id, imageBase64)
  await storage().setItem(wine.id, data)
  return wine
}

export const remove = async (id: WineId) => {
  await storage().removeItem(id)
  await imageStorage().removeItem(id)
}
