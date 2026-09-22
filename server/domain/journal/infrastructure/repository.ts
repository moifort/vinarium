import type { WriteBatch } from 'firebase-admin/firestore'
import { chunk } from 'lodash-es'
import type { BeverageId } from '~/domain/beverage/types'
import type { JournalEntry, JournalEntryId } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import { db } from '~/system/firebase'
import { memoizedPerRequest } from '~/system/request-cache'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const journal = () => db().collection('journal').withConverter(genericDataConverter<JournalEntry>())

const allCacheKey = (userId: UserId) => `journal:all:${userId}`

export const findAllByUser = (userId: UserId): Promise<JournalEntry[]> =>
  memoizedPerRequest(allCacheKey(userId), async () => {
    const snap = await journal().where('userId', '==', userId).orderBy('date', 'desc').get()
    return snap.docs.map((doc) => doc.data())
  })

// Firestore caps `in` disjunctions at 30 values per query.
const IN_QUERY_LIMIT = 30

// --- Household-scoped reads -------------------------------------------------
// A shared cellar has one journal: every member's movements belong to it. Each
// read below spans the member set from cellarScope(), degenerating to a single
// user's view when the scope is a lone user ([userId]).

// Every journal entry of a page of wines, batched with `in` queries — one query
// per 30 wines instead of one per wine. Unordered: callers sort per wine. Only
// `beverageId` is disjoined (Firestore rejects two `in` filters in one query), so
// the member set is applied in memory — a cheap guard, since a beverage id is
// globally unique and only its owner's household ever journals it.
export const findByBeverageIdsForUsers = async (
  memberIds: UserId[],
  beverageIds: BeverageId[],
): Promise<JournalEntry[]> => {
  if (beverageIds.length === 0) return []
  const members = new Set(memberIds)
  const slices = await Promise.all(
    chunk(beverageIds, IN_QUERY_LIMIT).map(async (slice) => {
      const snap = await journal().where('beverageId', 'in', slice).get()
      return snap.docs.map((doc) => doc.data())
    }),
  )
  return slices.flat().filter((entry) => members.has(entry.userId))
}

// The household's most recent exit event, read with a limit(1) query instead of
// scanning the whole journal — the dashboard's "last exit" tile is the only
// consumer and never needs more than one entry.
export const findLatestExitForUsers = async (
  memberIds: UserId[],
): Promise<JournalEntry | undefined> => {
  const snap = await journal()
    .where('userId', 'in', memberIds)
    .where('type', '==', 'out')
    .orderBy('date', 'desc')
    .limit(1)
    .get()
  return snap.docs[0]?.data()
}

// One page of the shared journal, most recent first. `after` is the id of the
// last entry of the previous page: Firestore resumes right after it and bills
// only the page. `offset` stays for the app versions that page by count — every
// skipped entry is billed as a read, so a deep page costs the whole way down.
export const findPageForUsers = async (
  memberIds: UserId[],
  { limit, offset, after }: { limit: number; offset?: number; after?: JournalEntryId },
): Promise<{ entries: JournalEntry[]; hasMore: boolean; endCursor?: JournalEntryId }> => {
  let query = journal().where('userId', 'in', memberIds).orderBy('date', 'desc')
  if (after) {
    const cursor = await journal().doc(after).get()
    if (cursor.exists) query = query.startAfter(cursor)
  } else if (offset) {
    query = query.offset(offset)
  }
  const snap = await query.limit(limit + 1).get()
  const docs = snap.docs.slice(0, limit)
  return {
    entries: docs.map((doc) => doc.data()),
    hasMore: snap.docs.length > limit,
    endCursor: docs.at(-1)?.id as JournalEntryId | undefined,
  }
}

export const removeByBeverageId = async (
  userId: UserId,
  beverageId: BeverageId,
  batch?: WriteBatch,
): Promise<void> => {
  const snap = await journal()
    .where('userId', '==', userId)
    .where('beverageId', '==', beverageId)
    .get()
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
