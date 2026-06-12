import type { WriteBatch } from 'firebase-admin/firestore'
import type { Gift } from '~/domain/gift/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const gifts = () => db().collection('gift').withConverter(genericDataConverter<Gift>())

const docId = (userId: UserId, wineId: WineId) => `${userId}_${wineId}`

export const findAllByUser = async (userId: UserId): Promise<Gift[]> => {
  const snap = await gifts().where('userId', '==', userId).get()
  return snap.docs.map((doc) => doc.data())
}

export const findBy = async (userId: UserId, wineId: WineId): Promise<Gift | null> => {
  const doc = await gifts().doc(docId(userId, wineId)).get()
  return doc.data() ?? null
}

export const save = async (gift: Gift): Promise<Gift> => {
  await gifts().doc(docId(gift.userId, gift.wineId)).set(gift)
  return gift
}

export const remove = async (userId: UserId, wineId: WineId, batch?: WriteBatch): Promise<void> => {
  const ref = gifts().doc(docId(userId, wineId))
  if (batch) batch.delete(ref)
  else await ref.delete()
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await gifts().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
