import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import type { TastingNote } from '~/domain/tasting/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const tasting = () => db().collection('tasting').withConverter(genericDataConverter<TastingNote>())

const docId = (userId: UserId, wineId: WineId) => `${userId}_${wineId}`

export const findAllByUser = async (userId: UserId): Promise<TastingNote[]> => {
  const snap = await tasting().where('userId', '==', userId).get()
  return snap.docs.map((doc) => doc.data())
}

export const findBy = async (userId: UserId, wineId: WineId): Promise<TastingNote | null> => {
  const doc = await tasting().doc(docId(userId, wineId)).get()
  return doc.data() ?? null
}

export const save = async (note: TastingNote): Promise<TastingNote> => {
  await tasting().doc(docId(note.userId, note.wineId)).set(note)
  return note
}

export const remove = async (userId: UserId, wineId: WineId, batch?: WriteBatch): Promise<void> => {
  const ref = tasting().doc(docId(userId, wineId))
  if (batch) batch.delete(ref)
  else await ref.delete()
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await tasting().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
