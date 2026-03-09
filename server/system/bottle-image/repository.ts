import type { WineId } from '~/domain/wine/types'

const storage = () => useStorage('bottle-images')

export const findBy = (id: WineId) => storage().getItem<string>(id)

export const exists = async (id: WineId) => (await storage().getItem<string>(id)) !== null

export const save = async (id: WineId, imageBase64: string) => {
  await storage().setItem(id, imageBase64)
}

export const remove = async (id: WineId) => {
  await storage().removeItem(id)
}
