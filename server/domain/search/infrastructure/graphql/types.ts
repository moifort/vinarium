import { BeverageType } from '~/domain/beverage/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { SearchHit } from '../../types'
import { SearchMatchedFieldEnum } from './enums'

export const SearchHitType = builder.objectRef<SearchHit>('SearchHit').implement({
  description:
    'A single wine that matched the search, paired with why it matched.\n\n' +
    'The `matchedFields` list explains which attributes hit the query so the client can group ' +
    'and highlight results. The underlying relevance score orders the hits but is not exposed.',
  fields: (t) => ({
    wine: t.field({
      type: BeverageType,
      description: 'The matched wine',
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
  description:
    'A page of relevance-ranked search results.\n\n' +
    'Holds the best-matching hits (capped at the requested limit) plus the `totalCount` of ' +
    'matches before the limit, so the client can show a "showing N of M" summary.\n\n' +
    '```graphql\n' +
    'query {\n' +
    '  searchBeverages(query: "bordeaux", filters: { colors: [RED] }, limit: 20) {\n' +
    '    totalCount\n' +
    '    hits {\n' +
    '      matchedFields\n' +
    '      wine { name vintage }\n' +
    '    }\n' +
    '  }\n' +
    '}\n' +
    '```',
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
