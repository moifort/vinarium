import type { Wine, WineId } from '~/wine/types'

const storage = () => useStorage('wines')

export const findAll = async () => {
  const keys = await storage().getKeys()
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage().getItem<Wine>(key))!))
}

export const findBy = (id: WineId) => storage().getItem<Wine>(id)

export const save = async (wine: Wine) => {
  await storage().setItem<Wine>(wine.id, wine)
  return wine
}

export const remove = async (id: WineId) => {
  await storage().removeItem(id)
}
