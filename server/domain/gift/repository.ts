import type { Gift } from '~/domain/gift/types'
import type { WineId } from '~/domain/wine/types'

const storage = () => useStorage('gift')

export const findAll = async () => {
  const keys = await storage().getKeys()
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage().getItem<Gift>(key))!))
}

export const findBy = (wineId: WineId) => storage().getItem<Gift>(`${wineId}`)

export const save = async (gift: Gift) => {
  await storage().setItem<Gift>(`${gift.wineId}`, gift)
  return gift
}
