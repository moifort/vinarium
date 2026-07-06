import type { DocumentReference } from 'firebase-admin/firestore'
import { MigrationName, MigrationVersion } from '~/system/migration/primitives'
import type { Migration } from '~/system/migration/types'

// `giftedBy` (who gave me the bottle) leaves the wine document — a wine carries
// what it is, not a gifting transaction. It joins the gift domain as the
// `received` facet, alongside the existing gift record which becomes the `given`
// facet ({ giftedDate, recipientName } → given: { date, recipientName }). A wine
// can end up with both facets (received from someone, later given to another).
export const migration0005: Migration = {
  version: MigrationVersion(5),
  name: MigrationName('gifted-by-to-gift'),
  migrate: async ({ db }) => {
    const [wineSnap, giftSnap] = await Promise.all([
      db.collection('wines').get(),
      db.collection('gift').get(),
    ])

    // The pre-migration gift docs, keyed by their id (`${userId}_${beverageId}`).
    const giftById = new Map(giftSnap.docs.map((doc) => [doc.ref.id, doc.data()]))

    // Compute the final shape of every touched gift doc in memory first, so the
    // wine's `received` merges cleanly onto the restructured `given`.
    const nextGift = new Map<string, { ref: DocumentReference; data: Record<string, unknown> }>()

    for (const doc of giftSnap.docs) {
      const data = doc.data()
      if (!('giftedDate' in data) && !('recipientName' in data)) continue
      const { giftedDate, recipientName, ...rest } = data
      // No undefined reaches Firestore (it rejects undefined values); giftedDate
      // was a required field, so this is belt-and-suspenders.
      const given: Record<string, unknown> = {}
      if (giftedDate != null) given.date = giftedDate
      if (recipientName != null) given.recipientName = recipientName
      nextGift.set(doc.ref.id, { ref: doc.ref, data: { ...rest, given } })
    }

    const staleWines: { ref: DocumentReference; data: Record<string, unknown> }[] = []
    for (const doc of wineSnap.docs) {
      const data = doc.data()
      if (!('giftedBy' in data)) continue
      const { giftedBy, ...rest } = data
      staleWines.push({ ref: doc.ref, data: rest })
      if (giftedBy == null) continue
      const giftId = `${data.userId}_${data.id}`
      const existing = nextGift.get(giftId)?.data ??
        giftById.get(giftId) ?? { userId: data.userId, beverageId: data.id }
      const ref = db.collection('gift').doc(giftId)
      nextGift.set(giftId, { ref, data: { ...existing, received: { from: giftedBy } } })
    }

    const writes = [...nextGift.values(), ...staleWines]
    // Firestore caps a batch at 500 operations.
    for (let start = 0; start < writes.length; start += 500) {
      const batch = db.batch()
      for (const { ref, data } of writes.slice(start, start + 500)) batch.set(ref, data)
      await batch.commit()
    }
    return { ok: true, transformed: writes.length }
  },
}
