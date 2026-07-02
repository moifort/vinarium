import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import type { WineId } from '~/domain/wine/types'

// Per-request lazy index: the first byWineId() call loads the user's whole
// collection once, later calls hit the in-memory map. Turns the 1+4N reads of
// a wine list (one doc get per nested field per wine) into one query per domain.
// For single-wine queries this loads the full user collection instead of one
// doc — negligible for a personal cellar, same number of round-trips.
// Caveat: the index is cached for the whole request, so a document chaining
// several mutations would read state from before its own writes — fine today,
// clients send one mutation per request.
const lazyIndex = <T extends { wineId: WineId }>(loadAll: () => Promise<T[]>) => {
  let indexed: Promise<Map<WineId, T>> | undefined
  return {
    byWineId: async (wineId: WineId): Promise<T | null> => {
      indexed ??= loadAll().then((items) => new Map(items.map((item) => [item.wineId, item])))
      return (await indexed).get(wineId) ?? null
    },
  }
}

export const createLoaders = (userId: UserId) => ({
  cellarPlacement: lazyIndex(() => CellarQuery.getAllPlacements(userId)),
  consumption: lazyIndex(() => TastingQuery.getAll(userId)),
  gift: lazyIndex(() => GiftQuery.getAll(userId)),
  recommendation: lazyIndex(() => RecommendationQuery.getAll(userId)),
})

export type Loaders = ReturnType<typeof createLoaders>
