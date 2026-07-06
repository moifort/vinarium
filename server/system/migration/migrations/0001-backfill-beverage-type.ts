import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

// Beverages created before the multi-beverage support have no beverageType: they are all wines.
export const migration0001: Migration = {
  version: MigrationVersion(1),
  name: MigrationName('backfill-beverage-type'),
  migrate: async ({ db }) => {
    const snapshot = await db.collection('wines').get()
    const missing = snapshot.docs.filter((doc) => !('beverageType' in doc.data()))

    // Firestore caps a batch at 500 operations
    for (let start = 0; start < missing.length; start += 500) {
      const batch = db.batch()
      for (const doc of missing.slice(start, start + 500)) {
        batch.set(doc.ref, { ...doc.data(), beverageType: 'wine' })
      }
      await batch.commit()
    }
    return { ok: true, transformed: missing.length }
  },
}
