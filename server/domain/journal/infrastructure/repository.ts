import type { JournalEntry } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const journal = () => db().collection('journal').withConverter(genericDataConverter<JournalEntry>())

export const findAllByUser = async (userId: UserId): Promise<JournalEntry[]> => {
  const snap = await journal().where('userId', '==', userId).orderBy('date', 'desc').get()
  return snap.docs.map((doc) => doc.data())
}

export const findByWineId = async (userId: UserId, wineId: WineId): Promise<JournalEntry[]> => {
  const snap = await journal()
    .where('userId', '==', userId)
    .where('wineId', '==', wineId)
    .orderBy('date', 'desc')
    .get()
  return snap.docs.map((doc) => doc.data())
}

export const removeByWineId = async (userId: UserId, wineId: WineId): Promise<void> => {
  const snap = await journal().where('userId', '==', userId).where('wineId', '==', wineId).get()
  const batch = db().batch()
  for (const doc of snap.docs) batch.delete(doc.ref)
  await batch.commit()
}

export const save = async (entry: JournalEntry): Promise<JournalEntry> => {
  await journal().add(entry)
  return entry
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await journal().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
