import { builder } from '~/domain/shared/graphql/builder'
import { WineType } from '~/domain/wine/infrastructure/graphql/types'
import type { SearchHit } from '../../types'
import { SearchMatchedFieldEnum } from './enums'

export const SearchHitType = builder.objectRef<SearchHit>('SearchHit').implement({
  description: 'A wine that matched the search, with the fields that matched it',
  fields: (t) => ({
    wine: t.field({
      type: WineType,
      description: 'The matched wine, with its satellites already attached',
      resolve: (hit) => hit.item,
    }),
    matchedFields: t.field({
      type: [SearchMatchedFieldEnum],
      description: 'Which fields matched — empty when only facet filters applied',
      resolve: (hit) => hit.matchedFields,
    }),
  }),
})

export type SearchResults = { hits: SearchHit[]; totalCount: number }

export const SearchResultsType = builder.objectRef<SearchResults>('SearchResults').implement({
  description: 'Search results ranked by relevance',
  fields: (t) => ({
    hits: t.field({
      type: [SearchHitType],
      description: 'Matched wines, best relevance first (capped at the requested limit)',
      resolve: (results) => results.hits,
    }),
    totalCount: t.exposeInt('totalCount', {
      description: 'Total number of matches before the limit was applied',
    }),
  }),
})
