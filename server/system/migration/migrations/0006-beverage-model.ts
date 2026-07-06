import type { Firestore } from 'firebase-admin/firestore'
import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

// The wine → beverage remodel. Two moves:
//   1. Collection `wines` → `beverages`, with the wine-only fields grouped under
//      a `wine` sub-object (the discriminated-union shape) and `domain` renamed
//      to `producer`. A wine keeps a `wine` object (possibly empty); any other
//      type carries none.
//   2. The satellite collections rename their `wineId` field to `beverageId`.
//      Their doc id is `${userId}_${wineId}` where the id is the beverage's UUID,
//      unchanged here — so the doc id stays valid as `${userId}_${beverageId}`
//      and only the field is rewritten.

const WINE_DETAIL_KEYS = [
  'color',
  'vintage',
  'appellation',
  'classification',
  'grapeVarieties',
  'drinkWindow',
  'servingTemperature',
] as const

const SATELLITE_COLLECTIONS = ['cellar', 'journal', 'tasting', 'gift', 'recommendation'] as const

// Move every wine document into the beverages collection, reshaped.
const moveWinesToBeverages = async (db: Firestore): Promise<number> => {
  const snapshot = await db.collection('wines').get()
  // Two ops per document (set new + delete old) — stay under the 500-op cap.
  for (let start = 0; start < snapshot.docs.length; start += 250) {
    const batch = db.batch()
    for (const doc of snapshot.docs.slice(start, start + 250)) {
      const { domain, ...data } = doc.data() as Record<string, unknown>
      const wine: Record<string, unknown> = {}
      for (const key of WINE_DETAIL_KEYS) {
        if (key in data && data[key] !== undefined && data[key] !== null) wine[key] = data[key]
        delete data[key]
      }
      const next: Record<string, unknown> = { ...data }
      if (domain !== undefined && domain !== null) next.producer = domain
      if (data.beverageType === 'wine') next.wine = wine
      batch.set(db.collection('beverages').doc(doc.ref.id), next)
      batch.delete(doc.ref)
    }
    await batch.commit()
  }
  return snapshot.docs.length
}

// Rename the `wineId` field to `beverageId` in a satellite collection.
const renameWineIdField = async (db: Firestore, collection: string): Promise<number> => {
  const snapshot = await db.collection(collection).get()
  const stale = snapshot.docs.filter((doc) => 'wineId' in doc.data())
  for (let start = 0; start < stale.length; start += 500) {
    const batch = db.batch()
    for (const doc of stale.slice(start, start + 500)) {
      const { wineId, ...rest } = doc.data() as Record<string, unknown>
      // Full set (not merge) so the old `wineId` key disappears.
      batch.set(doc.ref, { ...rest, beverageId: wineId })
    }
    await batch.commit()
  }
  return stale.length
}

export const migration0006: Migration = {
  version: MigrationVersion(6),
  name: MigrationName('beverage-model'),
  migrate: async ({ db }) => {
    let transformed = await moveWinesToBeverages(db)
    for (const collection of SATELLITE_COLLECTIONS) {
      transformed += await renameWineIdField(db, collection)
    }
    return { ok: true, transformed }
  },
}
