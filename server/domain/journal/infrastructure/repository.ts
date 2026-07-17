import type { WriteBatch } from 'firebase-admin/firestore'
import { chunk } from 'lodash-es'
import type { BeverageId } from '~/domain/beverage/types'
import type { JournalEntry } from '~/domain/journal/types'
import type { UserId } from '~/domain/shared/types'
import { db } from '~/system/firebase'
import { isInRequestCache, memoizedPerRequest } from '~/system/request-cache'
import { deleteInBatches, genericDataConverter } from '~/utils/firestore'

const journal = () => db().collection('journal').withConverter(genericDataConverter<JournalEntry>())

const allCacheKey = (userId: UserId) => `journal:all:${userId}`
// A household shares one journal, so its reads are keyed by the whole member set.
// Sorted so the key is stable regardless of member order; a solo scope ([userId])
// collapses to the same key as allCacheKey(userId), sharing that request's cache.
const allUsersCacheKey = (memberIds: UserId[]) => `journal:all:${[...memberIds].sort().join(',')}`

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

export const findAllByUsers = (memberIds: UserId[]): Promise<JournalEntry[]> =>
  memoizedPerRequest(allUsersCacheKey(memberIds), async () => {
    const snap = await journal().where('userId', 'in', memberIds).orderBy('date', 'desc').get()
    return snap.docs.map((doc) => doc.data())
  })

// Every journal entry of a page of wines, batched with `in` queries — one query
// per 30 wines instead of one per wine. Unordered: callers sort per wine. Only
// `beverageId` is disjoined (Firestore rejects two `in` filters in one query), so
// the member set is applied in memory — a cheap guard, since a beverage id is
// globally unique and only its owner's household ever journals it. When the full
// scan already ran in this request, reuse it: zero extra reads.
export const findByBeverageIdsForUsers = async (
  memberIds: UserId[],
  beverageIds: BeverageId[],
): Promise<JournalEntry[]> => {
  if (beverageIds.length === 0) return []
  const members = new Set(memberIds)
  if (isInRequestCache(allUsersCacheKey(memberIds))) {
    const wanted = new Set(beverageIds)
    return (await findAllByUsers(memberIds)).filter((entry) => wanted.has(entry.beverageId))
  }
  const slices = await Promise.all(
    chunk(beverageIds, IN_QUERY_LIMIT).map(async (slice) => {
      const snap = await journal().where('beverageId', 'in', slice).get()
      return snap.docs.map((doc) => doc.data())
    }),
  )
  return slices.flat().filter((entry) => members.has(entry.userId))
}

// One page of the shared journal, most recent first. Offset-based: the journal
// grows slowly and its events carry no stable id to use as a cursor.
export const findPageForUsers = async (
  memberIds: UserId[],
  { limit, offset }: { limit: number; offset: number },
): Promise<{ entries: JournalEntry[]; hasMore: boolean }> => {
  const snap = await journal()
    .where('userId', 'in', memberIds)
    .orderBy('date', 'desc')
    .offset(offset)
    .limit(limit + 1)
    .get()
  const entries = snap.docs.map((doc) => doc.data())
  const hasMore = entries.length > limit
  return { entries: hasMore ? entries.slice(0, limit) : entries, hasMore }
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
