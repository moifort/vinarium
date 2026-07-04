import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import type { Wine, WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { memoizedPerRequest } from '~/system/request-cache'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const wines = () => db().collection('wines').withConverter(genericDataConverter<Wine>())

export const findAllByUser = (userId: UserId): Promise<Wine[]> =>
  memoizedPerRequest(`wines:all:${userId}`, async () => {
    const snap = await wines().where('userId', '==', userId).orderBy('createdAt', 'desc').get()
    return snap.docs.map((doc) => doc.data())
  })

export const findBy = async (userId: UserId, id: WineId): Promise<Wine | null> => {
  const doc = await wines().doc(id).get()
  const data = doc.data()
  return data && data.userId === userId ? data : null
}

// Batch-load a page of wines by id with a single getAll — no full-collection scan.
export const findManyByWineIds = async (userId: UserId, wineIds: WineId[]): Promise<Wine[]> => {
  if (wineIds.length === 0) return []
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
