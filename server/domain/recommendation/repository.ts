import type { Recommendation } from '~/domain/recommendation/types'
import type { WineId } from '~/domain/wine/types'

const storage = () => useStorage('recommendation')

export const findAll = async () => {
  const keys = await storage().getKeys()
  // biome-ignore lint/style/noNonNullAssertion: keys from storage always exist
  return Promise.all(keys.map(async (key) => (await storage().getItem<Recommendation>(key))!))
}

export const findBy = (wineId: WineId) => storage().getItem<Recommendation>(`${wineId}`)

export const save = async (recommendation: Recommendation) => {
  await storage().setItem<Recommendation>(`${recommendation.wineId}`, recommendation)
  return recommendation
}

export const remove = async (wineId: WineId) => {
  await storage().removeItem(`${wineId}`)
}
