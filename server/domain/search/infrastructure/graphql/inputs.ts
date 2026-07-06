import {
  BeverageStatusFilterEnum,
  BeverageTypeEnum,
  WineColorEnum,
} from '~/domain/beverage/infrastructure/graphql/enums'
import { builder } from '~/domain/shared/graphql/builder'

export const SearchFiltersInput = builder.inputType('SearchFiltersInput', {
  description: 'Facet filters combinable with the text query. Absent facets are not filtered on.',
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
