import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

// Group the flat purchase / drink-window / place fields into sub-objects so a
// wine carries what it is, not a scatter of loose keys. Each sub-object appears
// only when at least one of its fields was set; the old flat keys are removed.
const FLAT_KEYS = [
  'purchasePrice',
  'purchaseDate',
  'drinkFrom',
  'drinkUntil',
  'latitude',
  'longitude',
  'placeName',
] as const

const defined = <T>(...pairs: [string, T | undefined][]) => {
  const entries = pairs.filter(([, value]) => value !== undefined && value !== null)
  return entries.length > 0 ? Object.fromEntries(entries) : undefined
}

export const migration0004: Migration = {
  version: MigrationVersion(4),
  name: MigrationName('wine-sub-objects'),
  migrate: async ({ db }) => {
    const snapshot = await db.collection('wines').get()
    const stale = snapshot.docs.filter((doc) => FLAT_KEYS.some((key) => key in doc.data()))

    // Firestore caps a batch at 500 operations.
    for (let start = 0; start < stale.length; start += 500) {
      const batch = db.batch()
      for (const doc of stale.slice(start, start + 500)) {
        const {
          purchasePrice,
          purchaseDate,
          drinkFrom,
          drinkUntil,
          latitude,
          longitude,
          placeName,
          ...rest
        } = doc.data()
        const next = { ...rest }
        const purchase = defined(['price', purchasePrice], ['date', purchaseDate])
        if (purchase) next.purchase = purchase
        const drinkWindow = defined(['from', drinkFrom], ['until', drinkUntil])
        if (drinkWindow) next.drinkWindow = drinkWindow
        const place = defined(['latitude', latitude], ['longitude', longitude], ['name', placeName])
        if (place) next.place = place
        // Full set (not merge) so the flat keys disappear from the document.
        batch.set(doc.ref, next)
      }
      await batch.commit()
    }
    return { ok: true, transformed: stale.length }
  },
}
