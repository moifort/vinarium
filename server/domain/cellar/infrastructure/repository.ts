import type { WriteBatch } from 'firebase-admin/firestore'
import type { CellarBottle } from '~/domain/cellar/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const cellar = () => db().collection('cellar').withConverter(genericDataConverter<CellarBottle>())

const docId = (userId: UserId, wineId: WineId) => `${userId}_${wineId}`

export const findAllByUser = async (userId: UserId): Promise<CellarBottle[]> => {
  const snap = await cellar().where('userId', '==', userId).orderBy('createdAt', 'desc').get()
  return snap.docs.map((doc) => doc.data())
}

export const findBy = async (userId: UserId, wineId: WineId): Promise<CellarBottle | null> => {
  const doc = await cellar().doc(docId(userId, wineId)).get()
  return doc.data() ?? null
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
