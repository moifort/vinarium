import type { BeverageId } from '~/domain/beverage/types'
import { CellarQuery } from '~/domain/cellar/query'
import type { CellarBottleView } from '~/domain/cellar/types'
import { GiftQuery } from '~/domain/gift/query'
import type { Gift } from '~/domain/gift/types'
import { JournalQuery } from '~/domain/journal/query'
import type { JournalEntry } from '~/domain/journal/types'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { Recommendation } from '~/domain/recommendation/types'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import type { TastingNote } from '~/domain/tasting/types'

// Per-request loaders for the satellite fields of BeverageType. One loader
// instance set lives on each GraphQL context (built per request in
// routes/graphql.ts), so nothing leaks across requests. A loader memoizes per
// beverageId and batches every id requested in the same resolution tick into a
// single keyed read — a page of 40 beverages selecting `cellar` costs one 40-ref
// getAll, never 40 fallback reads, and a satellite the client did not select
// costs nothing at all.

export type BeverageLoader<T> = { load: (beverageId: BeverageId) => Promise<T | undefined> }

// The flush is scheduled after the promise-job queue drains (`then` + nextTick —
// the DataLoader trick): by then graphql-js has invoked the resolver of every
// sibling list item, so their loads land in one batch.
const batchedByBeverageId = <T>(
  batch: (beverageIds: BeverageId[]) => Promise<Map<BeverageId, T>>,
): BeverageLoader<T> => {
  const cache = new Map<BeverageId, Promise<T | undefined>>()
  let pending: {
    beverageId: BeverageId
    resolve: (value: T | undefined) => void
    reject: (error: unknown) => void
  }[] = []
  const flush = async () => {
    const calls = pending
    pending = []
    try {
      const results = await batch(calls.map(({ beverageId }) => beverageId))
      for (const { beverageId, resolve } of calls) resolve(results.get(beverageId))
    } catch (error) {
      for (const { reject } of calls) reject(error)
    }
  }
  return {
    load: (beverageId) => {
      const cached = cache.get(beverageId)
      if (cached) return cached
      const loading = new Promise<T | undefined>((resolve, reject) => {
        if (pending.length === 0) Promise.resolve().then(() => process.nextTick(flush))
        pending.push({ beverageId, resolve, reject })
      })
      cache.set(beverageId, loading)
      return loading
    },
  }
}

const indexByBeverageId = <T extends { beverageId: BeverageId }>(records: T[]) =>
  new Map(records.map((record) => [record.beverageId, record]))

export type BeverageSatelliteLoaders = {
  cellar: BeverageLoader<CellarBottleView>
  consumption: BeverageLoader<TastingNote>
  gift: BeverageLoader<Gift>
  recommendation: BeverageLoader<Recommendation>
  history: BeverageLoader<JournalEntry[]>
}

export const beverageSatelliteLoaders = (userId: UserId): BeverageSatelliteLoaders => ({
  cellar: batchedByBeverageId(async (beverageIds) =>
    indexByBeverageId(await CellarQuery.placementsByBeverageIds(userId, beverageIds)),
  ),
  consumption: batchedByBeverageId(async (beverageIds) =>
    indexByBeverageId(await TastingQuery.byBeverageIds(userId, beverageIds)),
  ),
  gift: batchedByBeverageId(async (beverageIds) =>
    indexByBeverageId(await GiftQuery.byBeverageIds(userId, beverageIds)),
  ),
  recommendation: batchedByBeverageId(async (beverageIds) =>
    indexByBeverageId(await RecommendationQuery.byBeverageIds(userId, beverageIds)),
  ),
  history: batchedByBeverageId(async (beverageIds) => {
    const entries = await JournalQuery.entriesByBeverageIds(userId, beverageIds)
    const grouped = new Map<BeverageId, JournalEntry[]>(
      beverageIds.map((beverageId) => [beverageId, []]),
    )
    for (const entry of entries) grouped.get(entry.beverageId)?.push(entry)
    return grouped
  }),
})
