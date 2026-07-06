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
import type { WineId } from '~/domain/wine/types'

// Per-request loaders for the satellite fields of WineType. One loader instance
// set lives on each GraphQL context (built per request in routes/graphql.ts), so
// nothing leaks across requests. A loader memoizes per wineId and batches every
// id requested in the same resolution tick into a single keyed read — a page of
// 40 wines selecting `cellar` costs one 40-ref getAll, never 40 fallback reads,
// and a satellite the client did not select costs nothing at all.

export type WineLoader<T> = { load: (wineId: WineId) => Promise<T | undefined> }

// The flush is scheduled after the promise-job queue drains (`then` + nextTick —
// the DataLoader trick): by then graphql-js has invoked the resolver of every
// sibling list item, so their loads land in one batch.
const batchedByWineId = <T>(
  batch: (wineIds: WineId[]) => Promise<Map<WineId, T>>,
): WineLoader<T> => {
  const cache = new Map<WineId, Promise<T | undefined>>()
  let pending: {
    wineId: WineId
    resolve: (value: T | undefined) => void
    reject: (error: unknown) => void
  }[] = []
  const flush = async () => {
    const calls = pending
    pending = []
    try {
      const results = await batch(calls.map(({ wineId }) => wineId))
      for (const { wineId, resolve } of calls) resolve(results.get(wineId))
    } catch (error) {
      for (const { reject } of calls) reject(error)
    }
  }
  return {
    load: (wineId) => {
      const cached = cache.get(wineId)
      if (cached) return cached
      const loading = new Promise<T | undefined>((resolve, reject) => {
        if (pending.length === 0) Promise.resolve().then(() => process.nextTick(flush))
        pending.push({ wineId, resolve, reject })
      })
      cache.set(wineId, loading)
      return loading
    },
  }
}

const indexByWineId = <T extends { wineId: WineId }>(records: T[]) =>
  new Map(records.map((record) => [record.wineId, record]))

export type WineSatelliteLoaders = {
  cellar: WineLoader<CellarBottleView>
  consumption: WineLoader<TastingNote>
  gift: WineLoader<Gift>
  recommendation: WineLoader<Recommendation>
  history: WineLoader<JournalEntry[]>
}

export const wineSatelliteLoaders = (userId: UserId): WineSatelliteLoaders => ({
  cellar: batchedByWineId(async (wineIds) =>
    indexByWineId(await CellarQuery.getPlacementsByWineIds(userId, wineIds)),
  ),
  consumption: batchedByWineId(async (wineIds) =>
    indexByWineId(await TastingQuery.getManyByWineIds(userId, wineIds)),
  ),
  gift: batchedByWineId(async (wineIds) =>
    indexByWineId(await GiftQuery.getManyByWineIds(userId, wineIds)),
  ),
  recommendation: batchedByWineId(async (wineIds) =>
    indexByWineId(await RecommendationQuery.getManyByWineIds(userId, wineIds)),
  ),
  history: batchedByWineId(async (wineIds) => {
    const entries = await JournalQuery.entriesByWineIds(userId, wineIds)
    const grouped = new Map<WineId, JournalEntry[]>(wineIds.map((wineId) => [wineId, []]))
    for (const entry of entries) grouped.get(entry.wineId)?.push(entry)
    return grouped
  }),
})
