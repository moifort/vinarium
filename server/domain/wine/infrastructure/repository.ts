import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import type { SortOrder, Wine, WineId, WineSort } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { isInRequestCache, memoizedPerRequest } from '~/system/request-cache'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const wines = () => db().collection('wines').withConverter(genericDataConverter<Wine>())

// The wine document fields each sort option maps to.
const sortField = (sort: WineSort) => (sort === 'price' ? 'purchasePrice' : sort)

export type WinePage = { wines: Wine[]; hasMore: boolean }
export type PageArgs = { limit: number; after?: WineId; sort: WineSort; order: SortOrder }

const allCacheKey = (userId: UserId) => `wines:all:${userId}`

export const findAllByUser = (userId: UserId): Promise<Wine[]> =>
  memoizedPerRequest(allCacheKey(userId), async () => {
    const snap = await wines().where('userId', '==', userId).orderBy('createdAt', 'desc').get()
    return snap.docs.map((doc) => doc.data())
  })

export const findBy = async (userId: UserId, id: WineId): Promise<Wine | null> => {
  const doc = await wines().doc(id).get()
  const data = doc.data()
  return data && data.userId === userId ? data : null
}

// One page of wines ordered by the chosen field. Reads limit+1 docs to know if a
// next page exists, then trims. Nullable sort fields (vintage/region/color/price)
// drop wines missing that field — expected Firestore orderBy behaviour.
export const findPage = async (userId: UserId, args: PageArgs): Promise<WinePage> => {
  let query = wines().where('userId', '==', userId).orderBy(sortField(args.sort), args.order)
  if (args.after) {
    const cursor = await wines().doc(args.after).get()
    if (cursor.exists) query = query.startAfter(cursor)
  }
  const snap = await query.limit(args.limit + 1).get()
  const docs = snap.docs.map((doc) => doc.data())
  const hasMore = docs.length > args.limit
  return { wines: hasMore ? docs.slice(0, args.limit) : docs, hasMore }
}

// Batch-load a page of wines by id with a single getAll — no full-collection scan.
// When the full scan already ran in this request, reuse it: zero extra reads.
export const findManyByWineIds = async (userId: UserId, wineIds: WineId[]): Promise<Wine[]> => {
  if (wineIds.length === 0) return []
  if (isInRequestCache(allCacheKey(userId))) {
    const wanted = new Set(wineIds)
    return (await findAllByUser(userId)).filter((wine) => wanted.has(wine.id))
  }
  const refs = wineIds.map((id) => wines().doc(id))
  const snaps = await db().getAll(...refs)
  return snaps
    .map((snap) => snap.data())
    .filter((wine): wine is Wine => wine !== undefined && wine.userId === userId)
}

export const save = async (wine: Wine): Promise<Wine> => {
  await wines().doc(wine.id).set(wine)
  return wine
}

export const remove = async (id: WineId, batch?: WriteBatch): Promise<void> => {
  const ref = wines().doc(id)
  if (batch) batch.delete(ref)
  else await ref.delete()
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await wines().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
