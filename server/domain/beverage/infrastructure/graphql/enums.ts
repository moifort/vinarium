import { builder } from '~/domain/shared/graphql/builder'

export const WineColorEnum = builder.enumType('WineColor', {
  description: 'Beverage color category',
  values: {
    RED: { value: 'red' },
    WHITE: { value: 'white' },
    ROSE: { value: 'rosé' },
  } as const,
})

export const BeverageSubtypeEnum = builder.enumType('BeverageSubtype', {
  description:
    'Structured refinement of a beverage type. Validity depends on the beverageType ' +
    '(an IPA on a spirit is rejected); OTHER fits every type.',
  values: {
    SPARKLING: { value: 'sparkling' },
    SWEET: { value: 'sweet' },
    LATE_HARVEST: { value: 'late-harvest' },
    VIN_JAUNE: { value: 'vin-jaune' },
    PORTO: { value: 'porto' },
    FORTIFIED: { value: 'fortified' },
    RUM: { value: 'rum' },
    WHISKY: { value: 'whisky' },
    GIN: { value: 'gin' },
    VODKA: { value: 'vodka' },
    COGNAC: { value: 'cognac' },
    ARMAGNAC: { value: 'armagnac' },
    TEQUILA: { value: 'tequila' },
    LIQUEUR: { value: 'liqueur' },
    EAU_DE_VIE: { value: 'eau-de-vie' },
    BLONDE: { value: 'blonde' },
    BLANCHE: { value: 'blanche' },
    AMBER: { value: 'amber' },
    BRUNE: { value: 'brune' },
    IPA: { value: 'ipa' },
    STOUT: { value: 'stout' },
    PILS: { value: 'pils' },
    TRIPLE: { value: 'triple' },
    JUNMAI: { value: 'junmai' },
    GINJO: { value: 'ginjo' },
    DAIGINJO: { value: 'daiginjo' },
    HONJOZO: { value: 'honjozo' },
    NIGORI: { value: 'nigori' },
    BRUT: { value: 'brut' },
    DOUX: { value: 'doux' },
    DEMI_SEC: { value: 'demi-sec' },
    POIRE: { value: 'poire' },
    OTHER: { value: 'other' },
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

export const BeverageSortEnum = builder.enumType('BeverageSort', {
  description: 'Field used to sort the beverage list',
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

export const BeverageListModeEnum = builder.enumType('BeverageListMode', {
  description: 'Which view of the beverage list to page through',
  values: {
    ALL: { value: 'all' },
    FAVORITES: { value: 'favorites' },
    GIFTED: { value: 'gifted' },
    RECOMMENDED: { value: 'recommended' },
  } as const,
})

export const BeverageStatusFilterEnum = builder.enumType('BeverageStatusFilter', {
  description: 'Optional lifecycle filter applied to the beverage list',
  values: {
    ALL: { value: 'all' },
    IN_CELLAR: { value: 'in-cellar' },
    CONSUMED: { value: 'consumed' },
  } as const,
})

export const BeverageStatusEnum = builder.enumType('BeverageStatus', {
  description: 'Lifecycle status of a beverage',
  values: {
    IN_CELLAR: { value: 'in-cellar' },
    CONSUMED: { value: 'consumed' },
    GIFTED: { value: 'gifted' },
    RECOMMENDED: { value: 'recommended' },
  } as const,
})
