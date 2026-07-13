import type { CachedScanResult, ImageHash } from '~/domain/scan/types'
import { db } from '~/system/firebase'
import { genericDataConverter } from '~/utils/firestore'

const cache = () =>
  db().collection('scan-cache').withConverter(genericDataConverter<CachedScanResult>())

export const findBy = async (imageHash: ImageHash): Promise<CachedScanResult | null> => {
  const doc = await cache().doc(imageHash).get()
  return doc.data() ?? null
}

export const save = async (entry: CachedScanResult): Promise<CachedScanResult> => {
  await cache().doc(entry.imageHash).set(entry)
  return entry
}
