import type {
  DocumentData,
  DocumentReference,
  FirestoreDataConverter,
  QueryDocumentSnapshot,
  WriteBatch,
} from 'firebase-admin/firestore'
import { chunk } from 'lodash-es'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { isInRequestCache, memoizedPerRequest } from '~/system/request-cache'

// Generic Firestore converter that preserves type information when reading
// documents and recursively turns Timestamp instances back into JS Date.
// Pattern from https://github.com/moifort/price-it back/src/utils/firestore.ts
export const genericDataConverter = <T extends DocumentData>(): FirestoreDataConverter<T> => ({
  toFirestore: (data: T) => data,
  fromFirestore: (snapshot: QueryDocumentSnapshot) => toDate(snapshot.data()) as T,
})

const toDate = (value: unknown): unknown => {
  if (!value || typeof value !== 'object') return value
  const obj = value as Record<string, unknown>
  for (const key of Object.keys(obj)) {
    const v = obj[key] as { toDate?: () => Date } | unknown
    if (v && typeof v === 'object' && typeof (v as { toDate?: unknown }).toDate === 'function') {
      obj[key] = (v as { toDate: () => Date }).toDate()
    } else if (v && typeof v === 'object') {
      toDate(v)
    }
  }
  return obj
}

// Firestore batches accept at most 500 operations.
const BATCH_LIMIT = 400

export const deleteInBatches = async (refs: DocumentReference[]): Promise<void> => {
  for (const slice of chunk(refs, BATCH_LIMIT)) {
    const batch = db().batch()
    for (const ref of slice) batch.delete(ref)
    await batch.commit()
  }
}

// Repository for collections holding one record per (user, wine) pair, stored
// under the deterministic doc id `${userId}_${wineId}` — the shared shape of
// the tasting/gift/recommendation satellite collections.
export const userWineRecordRepository = <T extends { userId: UserId; wineId: WineId }>(
  collectionName: string,
) => {
  const records = () => db().collection(collectionName).withConverter(genericDataConverter<T>())
  const docId = (userId: UserId, wineId: WineId) => `${userId}_${wineId}`
  const allCacheKey = (userId: UserId) => `${collectionName}:all:${userId}`

  const findAllByUser = (userId: UserId): Promise<T[]> =>
    memoizedPerRequest(allCacheKey(userId), async () => {
      const snap = await records().where('userId', '==', userId).get()
      return snap.docs.map((doc) => doc.data())
    })

  return {
    findAllByUser,
    findBy: async (userId: UserId, wineId: WineId): Promise<T | null> => {
      const doc = await records().doc(docId(userId, wineId)).get()
      return doc.data() ?? null
    },
    // Batch-load the records for a page of wines with a single getAll — one read
    // per id, no full-collection scan. Missing docs come back undefined. When the
    // full scan already ran in this request, reuse it: zero extra reads. Safe as
    // long as no mutation scans then writes this collection then re-resolves a
    // satellite in the same request (the read-then-write caveat in request-cache.ts);
    // evictFromRequestCache is the escape hatch if that flow ever appears.
    findManyByWineIds: async (userId: UserId, wineIds: WineId[]): Promise<T[]> => {
      if (wineIds.length === 0) return []
      if (isInRequestCache(allCacheKey(userId))) {
        const wanted = new Set(wineIds)
        return (await findAllByUser(userId)).filter((record) => wanted.has(record.wineId))
      }
      const refs = wineIds.map((wineId) => records().doc(docId(userId, wineId)))
      const snaps = await db().getAll(...refs)
      return snaps.map((snap) => snap.data()).filter((data): data is T => data !== undefined)
    },
    save: async (record: T): Promise<T> => {
      await records().doc(docId(record.userId, record.wineId)).set(record)
      return record
    },
    remove: async (userId: UserId, wineId: WineId, batch?: WriteBatch): Promise<void> => {
      const ref = records().doc(docId(userId, wineId))
      if (batch) batch.delete(ref)
      else await ref.delete()
    },
    removeAllByUser: async (userId: UserId): Promise<void> => {
      const snap = await records().where('userId', '==', userId).get()
      await deleteInBatches(snap.docs.map((doc) => doc.ref))
    },
  }
}

// Runs `enlist` against a fresh WriteBatch and commits it once: either every
// enlisted write lands or none does. Reads inside `enlist` see pre-batch state —
// batched writes are invisible until commit. Firestore caps a batch at 500
// writes; callers enlist a handful of documents, far below the cap.
export const atomically = async <T>(enlist: (batch: WriteBatch) => Promise<T>): Promise<T> => {
  const batch = db().batch()
  const result = await enlist(batch)
  await batch.commit()
  return result
}
