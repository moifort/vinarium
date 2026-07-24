import type { CachedScanResult, ImageHash, ScanLanguage } from '~/domain/scan/types'
import { db } from '~/system/firebase'
import { genericDataConverter } from '~/utils/firestore'

const cache = () =>
  db().collection('scan-cache').withConverter(genericDataConverter<CachedScanResult>())

// One cache entry per (image, language): the document id folds the language in so
// the same label scanned in two languages stays two separate entries. Entries
// written before multi-language support carry the bare hash (French) and are
// simply never hit again once callers send a language suffix.
const cacheId = (imageHash: ImageHash, language: ScanLanguage) => `${imageHash}_${language}`

export const findBy = async (
  imageHash: ImageHash,
  language: ScanLanguage,
): Promise<CachedScanResult | null> => {
  const doc = await cache().doc(cacheId(imageHash, language)).get()
  return doc.data() ?? null
}

export const save = async (entry: CachedScanResult): Promise<CachedScanResult> => {
  await cache().doc(cacheId(entry.imageHash, entry.language)).set(entry)
  return entry
}
