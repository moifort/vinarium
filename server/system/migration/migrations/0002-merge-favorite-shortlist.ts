import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

// Favorites used to mean rating === 5, and "à retenir" was a separate `shortlist`
// boolean. Both collapse into a single explicit `favorite` heart flag, decoupled
// from the star rating: any 5-star or shortlisted tasting becomes a favorite, and
// the legacy `shortlist` field is dropped everywhere it lingers.
export const migration0002: Migration = {
  version: MigrationVersion(2),
  name: MigrationName('merge-favorite-shortlist'),
  migrate: async ({ db }) => {
    const snapshot = await db.collection('tasting').get()
    const affected = snapshot.docs.filter((doc) => {
      const data = doc.data()
      return data.rating === 5 || 'shortlist' in data
    })

    // Firestore caps a batch at 500 operations
    for (let start = 0; start < affected.length; start += 500) {
      const batch = db.batch()
      for (const doc of affected.slice(start, start + 500)) {
        const { shortlist, ...rest } = doc.data()
        const favorite = rest.rating === 5 || shortlist === true
        // set() replaces the doc, so omitting `shortlist` drops the legacy field
        batch.set(doc.ref, favorite ? { ...rest, favorite: true } : rest)
      }
      await batch.commit()
    }
    return { ok: true, transformed: affected.length }
  },
}
