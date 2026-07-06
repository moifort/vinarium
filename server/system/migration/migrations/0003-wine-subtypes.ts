import { subtypeFromLegacy } from '~/domain/beverage/legacy-mapping'
import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

// The structured subtype replaces the free-text `style`, and sparkling/sweet
// leave the color enum (they were wine subtypes, not colors). Their actual robe
// was never captured: white is the safest guess (rosé effervescents lose their
// robe — the user can fix it by hand). Unmapped styles become 'other' rather
// than silently losing the fact that the bottle had one.
export const migration0003: Migration = {
  version: MigrationVersion(3),
  name: MigrationName('wine-subtypes'),
  migrate: async ({ db }) => {
    const snapshot = await db.collection('wines').get()
    const stale = snapshot.docs.filter((doc) => {
      const data = doc.data()
      return data.color === 'sparkling' || data.color === 'sweet' || 'style' in data
    })

    // Firestore caps a batch at 500 operations
    for (let start = 0; start < stale.length; start += 500) {
      const batch = db.batch()
      for (const doc of stale.slice(start, start + 500)) {
        const { style, ...data } = doc.data()
        const next = { ...data }
        const legacy = subtypeFromLegacy({ style, color: data.color })
        if (data.color === 'sparkling' || data.color === 'sweet') next.color = 'white'
        // A null style is an empty fact — dropping the field is enough, no 'other'.
        if (next.subtype === undefined && (legacy !== undefined || style != null))
          next.subtype = legacy ?? 'other'
        // Full set (not merge) so the legacy `style` field disappears from the doc.
        batch.set(doc.ref, next)
      }
      await batch.commit()
    }
    return { ok: true, transformed: stale.length }
  },
}
