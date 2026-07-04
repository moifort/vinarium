import type { WriteBatch } from 'firebase-admin/firestore'
import type { JournalEntry } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { db } from '~/system/firebase'
import { memoizedPerRequest } from '~/system/request-cache'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const journal = () => db().collection('journal').withConverter(genericDataConverter<JournalEntry>())

export const findAllByUser = (userId: UserId): Promise<JournalEntry[]> =>
  memoizedPerRequest(`journal:all:${userId}`, async () => {
    const snap = await journal().where('userId', '==', userId).orderBy('date', 'desc').get()
    return snap.docs.map((doc) => doc.data())
  })

// One page of journal entries, most recent first. Offset-based: the journal grows
// slowly and its events carry no stable id to use as a cursor.
export const findPage = async (
  userId: UserId,
  { limit, offset }: { limit: number; offset: number },
): Promise<{ entries: JournalEntry[]; hasMore: boolean }> => {
  const snap = await journal()
    .where('userId', '==', userId)
    .orderBy('date', 'desc')
    .offset(offset)
    .limit(limit + 1)
    .get()
  const entries = snap.docs.map((doc) => doc.data())
  const hasMore = entries.length > limit
  return { entries: hasMore ? entries.slice(0, limit) : entries, hasMore }
}

export const findByWineId = async (userId: UserId, wineId: WineId): Promise<JournalEntry[]> => {
  const snap = await journal()
    .where('userId', '==', userId)
    .where('wineId', '==', wineId)
    .orderBy('date', 'desc')
    .get()
  return snap.docs.map((doc) => doc.data())
}

export const removeByWineId = async (
  userId: UserId,
  wineId: WineId,
  batch?: WriteBatch,
): Promise<void> => {
  const snap = await journal().where('userId', '==', userId).where('wineId', '==', wineId).get()
  // A wine's journal holds a handful of in/out movements — far below the
  // 500-writes Firestore batch cap, so enlisting them all in one batch is safe.
  const target = batch ?? db().batch()
  for (const doc of snap.docs) target.delete(doc.ref)
  if (!batch) await target.commit()
}

export const save = async (entry: JournalEntry, batch?: WriteBatch): Promise<JournalEntry> => {
  if (batch) batch.set(journal().doc(), entry)
  else await journal().add(entry)
  return entry
}

export const removeAllByUser = async (userId: UserId): Promise<void> => {
  const snap = await journal().where('userId', '==', userId).get()
  await deleteInBatches(snap.docs.map((doc) => doc.ref))
}
