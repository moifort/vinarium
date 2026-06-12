import type { WriteBatch } from 'firebase-admin/firestore'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const recommendations = () =>
  db().collection('recommendation').withConverter(genericDataConverter<Recommendation>())

const docId = (userId: UserId, wineId: WineId) => `${userId}_${wineId}`

export const findAllByUser = async (userId: UserId): Promise<Recommendation[]> => {
  const snap = await recommendations().where('userId', '==', userId).get()
  return snap.docs.map((doc) => doc.data())
}

export const findBy = async (userId: UserId, wineId: WineId): Promise<Recommendation | null> => {
  const doc = await recommendations().doc(docId(userId, wineId)).get()
  return doc.data() ?? null
}

export const save = async (rec: Recommendation): Promise<Recommendation> => {
  await recommendations().doc(docId(rec.userId, rec.wineId)).set(rec)
  return rec
}

export const remove = async (userId: UserId, wineId: WineId, batch?: WriteBatch): Promise<void> => {
  const ref = recommendations().doc(docId(userId, wineId))
  if (batch) batch.delete(ref)
  else await ref.delete()
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await recommendations().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
