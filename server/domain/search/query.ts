import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
import { WineQuery } from '~/domain/wine/query'
import type { WineId } from '~/domain/wine/types'
import { rankedHits } from './business-rules'
import type { SearchableWine, SearchFilters } from './types'

export namespace SearchQuery {
  // Global search across the whole collection: every domain is loaded in full
  // (the per-request cache dedupes these reads with any other resolver), joined
  // per wine, then matched and ranked in memory — same pattern as the filtered
  // wine list views, which Firestore's lack of full-text search imposes.
  export const acrossCollections = async (
    userId: UserId,
    { query, filters, limit }: { query: string; filters: SearchFilters; limit: number },
  ) => {
    const [wines, placements, tastings, gifts, recommendations] = await Promise.all([
      WineQuery.findAll(userId),
      CellarQuery.getAllPlacements(userId),
      TastingQuery.getAll(userId),
      GiftQuery.getAll(userId),
      RecommendationQuery.getAll(userId),
    ])
    const cellar = indexByWineId(placements)
    const consumption = indexByWineId(tastings)
    const gift = indexByWineId(gifts)
    const recommendation = indexByWineId(recommendations)
    const items: SearchableWine[] = wines.map((wine) => ({
      ...wine,
      cellar: cellar.get(wine.id) ?? null,
      consumption: consumption.get(wine.id) ?? null,
      gift: gift.get(wine.id) ?? null,
      recommendation: recommendation.get(wine.id) ?? null,
    }))
    const hits = rankedHits(items, query, filters)
    return { hits: hits.slice(0, limit), totalCount: hits.length }
  }

  const indexByWineId = <T extends { wineId: WineId }>(records: T[]) =>
    new Map(records.map((record) => [record.wineId, record]))
}
