import { builder } from '~/domain/shared/graphql/builder'

export const WineColorEnum = builder.enumType('WineColor', {
  description: 'Wine color category',
  values: {
    RED: { value: 'red' },
    WHITE: { value: 'white' },
    ROSE: { value: 'rosé' },
    SPARKLING: { value: 'sparkling' },
    SWEET: { value: 'sweet' },
  } as const,
})

export const BeverageTypeEnum = builder.enumType('BeverageType', {
  description: 'Kind of beverage a bottle contains',
  values: {
    WINE: { value: 'wine' },
    SPIRIT: { value: 'spirit' },
    BEER: { value: 'beer' },
    SAKE: { value: 'sake' },
    CIDER: { value: 'cider' },
    OTHER: { value: 'other' },
  } as const,
})

export const WineSortEnum = builder.enumType('WineSort', {
  description: 'Field used to sort the wine list',
  values: {
    CREATED_AT: { value: 'createdAt' },
    UPDATED_AT: { value: 'updatedAt' },
    VINTAGE: { value: 'vintage' },
    REGION: { value: 'region' },
    COLOR: { value: 'color' },
    PRICE: { value: 'price' },
  } as const,
})

export const SortOrderEnum = builder.enumType('SortOrder', {
  description: 'Sort direction',
  values: {
    ASC: { value: 'asc' },
    DESC: { value: 'desc' },
  } as const,
})

export const WineStatusEnum = builder.enumType('WineStatus', {
  description: 'Lifecycle status of a wine',
  values: {
    IN_CELLAR: { value: 'in-cellar' },
    CONSUMED: { value: 'consumed' },
    GIFTED: { value: 'gifted' },
    RECOMMENDED: { value: 'recommended' },
  } as const,
})
