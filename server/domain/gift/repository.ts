import type { Gift } from '~/domain/gift/types'
import type { WineId } from '~/domain/wine/types'

const storage = () => useStorage('gift')

export const findAll = async () => {
  const keys = await storage().getKeys()
  const items = await storage().getItems<Gift>(keys)
  return items.map(({ value }) => value)
}

export const findBy = (wineId: WineId) => storage().getItem<Gift>(`${wineId}`)

export const save = async (gift: Gift) => {
  await storage().setItem<Gift>(`${gift.wineId}`, gift)
  return gift
}

export const remove = async (wineId: WineId) => {
  await storage().removeItem(`${wineId}`)
}
