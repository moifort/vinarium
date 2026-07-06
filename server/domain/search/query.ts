import { BeverageQuery } from '~/domain/beverage/query'
import type { BeverageId } from '~/domain/beverage/types'
import { CellarQuery } from '~/domain/cellar/query'
import { GiftQuery } from '~/domain/gift/query'
import { RecommendationQuery } from '~/domain/recommendation/query'
import type { UserId } from '~/domain/shared/types'
import { TastingQuery } from '~/domain/tasting/query'
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
      BeverageQuery.findAll(userId),
      CellarQuery.placements(userId),
      TastingQuery.all(userId),
      GiftQuery.all(userId),
      RecommendationQuery.all(userId),
    ])
    const cellar = indexByBeverageId(placements)
    const consumption = indexByBeverageId(tastings)
    const gift = indexByBeverageId(gifts)
    const recommendation = indexByBeverageId(recommendations)
    // Attach only the satellites that exist: no key rather than a null value.
    const items: SearchableWine[] = wines.map((wine) => {
      const item: SearchableWine = { ...wine }
      const bottle = cellar.get(wine.id)
      if (bottle) item.cellar = bottle
      const tasting = consumption.get(wine.id)
      if (tasting) item.consumption = tasting
      const given = gift.get(wine.id)
      if (given) item.gift = given
      const recommended = recommendation.get(wine.id)
      if (recommended) item.recommendation = recommended
      return item
    })
    const hits = rankedHits(items, query, filters)
    return { hits: hits.slice(0, limit), totalCount: hits.length }
  }

  const indexByBeverageId = <T extends { beverageId: BeverageId }>(records: T[]) =>
    new Map(records.map((record) => [record.beverageId, record]))
}
