import type { WriteBatch } from 'firebase-admin/firestore'
import type { CellarBottle } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { memoizedPerRequest } from '~/system/request-cache'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const cellar = () => db().collection('cellar').withConverter(genericDataConverter<CellarBottle>())

const docId = (userId: UserId, wineId: WineId) => `${userId}_${wineId}`

export const findAllByUser = (userId: UserId): Promise<CellarBottle[]> =>
  memoizedPerRequest(`cellar:all:${userId}`, async () => {
    const snap = await cellar().where('userId', '==', userId).orderBy('createdAt', 'desc').get()
    return snap.docs.map((doc) => doc.data())
  })

export const findBy = async (userId: UserId, wineId: WineId): Promise<CellarBottle | null> => {
  const doc = await cellar().doc(docId(userId, wineId)).get()
  return doc.data() ?? null
}

// One page of cellar wine ids ordered by placement date (cellar docs always
// carry createdAt), newest first / oldest first per `order`.
export const findPage = async (
  userId: UserId,
  args: { limit: number; after?: WineId; order: 'asc' | 'desc' },
): Promise<{ wineIds: WineId[]; hasMore: boolean }> => {
  let query = cellar().where('userId', '==', userId).orderBy('createdAt', args.order)
  if (args.after) {
    const cursor = await cellar().doc(docId(userId, args.after)).get()
    if (cursor.exists) query = query.startAfter(cursor)
  }
  const snap = await query.limit(args.limit + 1).get()
  const docs = snap.docs.map((doc) => doc.data())
  const hasMore = docs.length > args.limit
  return { wineIds: (hasMore ? docs.slice(0, args.limit) : docs).map((b) => b.wineId), hasMore }
}

// One page of cellar bottles in grid order (row then column): the cave screen
// groups by row, so pages must fill the grid top-to-bottom — paginating by date
// would make rows appear incomplete and sections jump around while scrolling.
export const findBottlesPage = async (
  userId: UserId,
  { limit, after }: { limit: number; after?: WineId },
): Promise<{ bottles: CellarBottle[]; hasMore: boolean }> => {
  let query = cellar().where('userId', '==', userId).orderBy('row', 'asc').orderBy('col', 'asc')
  if (after) {
    const cursor = await cellar().doc(docId(userId, after)).get()
    if (cursor.exists) query = query.startAfter(cursor)
  }
  const snap = await query.limit(limit + 1).get()
  const bottles = snap.docs.map((doc) => doc.data())
  const hasMore = bottles.length > limit
  return { bottles: hasMore ? bottles.slice(0, limit) : bottles, hasMore }
}

// Batch-load cellar placements for a page of wines with a single getAll.
export const findManyByWineIds = async (
  userId: UserId,
  wineIds: WineId[],
): Promise<CellarBottle[]> => {
  if (wineIds.length === 0) return []
  const refs = wineIds.map((wineId) => cellar().doc(docId(userId, wineId)))
  const snaps = await db().getAll(...refs)
  return snaps.map((snap) => snap.data()).filter((b): b is CellarBottle => b !== undefined)
}

export const save = async (entry: CellarBottle, batch?: WriteBatch): Promise<CellarBottle> => {
  const ref = cellar().doc(docId(entry.userId, entry.wineId))
  if (batch) batch.set(ref, entry)
  else await ref.set(entry)
  return entry
}

export const remove = async (userId: UserId, wineId: WineId, batch?: WriteBatch): Promise<void> => {
  const ref = cellar().doc(docId(userId, wineId))
  if (batch) batch.delete(ref)
  else await ref.delete()
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await cellar().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
