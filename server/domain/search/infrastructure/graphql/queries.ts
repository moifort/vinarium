import type { BeverageStatusFilter, BeverageType, WineColor } from '~/domain/beverage/types'
import { builder } from '~/domain/shared/graphql/builder'
import { SearchQuery } from '../../query'
import type { SearchFilters } from '../../types'
import { SearchFiltersInput } from './inputs'
import { SearchResultsType } from './types'

builder.queryField('searchBeverages', (t) =>
  t.field({
    type: SearchResultsType,
    description:
      'Search the whole collection by name, producer, subtype, region, vintage or person, ' +
      'ranked by relevance. Spans the viewer’s wines plus household members’ wines placed ' +
      'in the shared cellar; tastings, gifts and recommendations stay the viewer’s own. ' +
      'An empty query with facet filters browses by filters alone; ' +
      'an empty query with no filter returns nothing.',
    args: {
      query: t.arg.string({ description: 'Free text — case- and accent-insensitive' }),
      filters: t.arg({ type: SearchFiltersInput, description: 'Combinable facet filters' }),
      limit: t.arg.int({ defaultValue: 50, description: 'Max hits returned' }),
    },
    resolve: async (_root, args, { userId }) => {
      const filters: SearchFilters = {
        colors: (args.filters?.colors as WineColor[] | null) ?? undefined,
        beverageTypes: (args.filters?.beverageTypes as BeverageType[] | null) ?? undefined,
        favorite: args.filters?.favorite ?? undefined,
        status: (args.filters?.status as BeverageStatusFilter | null) ?? undefined,
        gifted: args.filters?.gifted ?? undefined,
      }
      return SearchQuery.acrossCollections(userId, {
        query: args.query ?? '',
        filters,
        limit: args.limit ?? 50,
      })
    },
  }),
)
