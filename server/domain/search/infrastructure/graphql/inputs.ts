import {
  BeverageStatusFilterEnum,
  BeverageTypeEnum,
  WineColorEnum,
} from '~/domain/beverage/infrastructure/graphql/enums'
import { builder } from '~/domain/shared/graphql/builder'

export const SearchFiltersInput = builder.inputType('SearchFiltersInput', {
  description:
    'Facet filters combinable with the free-text search query.\n\n' +
    'Each facet narrows the result set; they combine as a logical AND. An absent (null) facet is ' +
    'not filtered on, and a `false` boolean facet is treated the same as absent (never inverts). ' +
    'Supplying only facets with an empty query browses the collection by filters alone.',
  fields: (t) => ({
    colors: t.field({ type: [WineColorEnum], description: 'Keep only these wine colors' }),
    beverageTypes: t.field({
      type: [BeverageTypeEnum],
      description: 'Keep only these beverage types',
    }),
    favorite: t.boolean({ description: 'Keep only wines flagged as favorite' }),
    status: t.field({
      type: BeverageStatusFilterEnum,
      description: 'Keep only wines in the cellar or already consumed',
    }),
    gifted: t.boolean({ description: 'Keep only wines received or given as a gift' }),
  }),
})
