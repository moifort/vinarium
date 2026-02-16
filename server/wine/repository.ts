import type { Wine, WineId } from '~/wine/types'

export const getAll = async () => {
  const storage = useStorage('wines')
  const keys = await storage.getKeys()
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage.getItem<Wine>(key))!))
}

export const getById = async (id: WineId) => {
  return useStorage('wines').getItem<Wine>(id)
}

export const save = async (wine: Wine) => {
  await useStorage('wines').setItem<Wine>(wine.id, wine)
}

export const remove = async (id: WineId) => {
  await useStorage('wines').removeItem(id)
}
