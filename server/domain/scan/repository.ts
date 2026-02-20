import type { CachedScanResult, ImageHash } from '~/domain/scan/types'

const storage = () => useStorage('scan-cache')

export const findBy = (imageHash: ImageHash) => storage().getItem<CachedScanResult>(imageHash)

export const save = async (entry: CachedScanResult) => {
  await storage().setItem<CachedScanResult>(entry.imageHash, entry)
  return entry
}
