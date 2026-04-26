import type { UserId } from '~/domain/shared/types'
import type { Wine, WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const wines = () => db().collection('wines').withConverter(genericDataConverter<Wine>())

export const findAllByUser = async (userId: UserId): Promise<Wine[]> => {
  const snap = await wines().where('userId', '==', userId).orderBy('createdAt', 'desc').get()
  return snap.docs.map((doc) => doc.data())
}

export const findBy = async (userId: UserId, id: WineId): Promise<Wine | null> => {
  const doc = await wines().doc(id).get()
  const data = doc.data()
  return data && data.userId === userId ? data : null
}

export const save = async (wine: Wine): Promise<Wine> => {
  await wines().doc(wine.id).set(wine)
  return wine
}

export const remove = async (id: WineId): Promise<void> => {
  await wines().doc(id).delete()
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await wines().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
