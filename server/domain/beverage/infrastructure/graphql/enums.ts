import { builder } from '~/domain/shared/graphql/builder'

export const WineColorEnum = builder.enumType('WineColor', {
  description:
    'The color category of a wine.\n\n' +
    'Only meaningful for a wine, where it is required. It drives the `color` facet on ' +
    'the `beverages` query and the `COLOR` sort.',
  values: {
    RED: { value: 'red', description: 'Red wine' },
    WHITE: { value: 'white', description: 'White wine' },
    ROSE: { value: 'rosé', description: 'Rose wine' },
  } as const,
})

export const BeverageSubtypeEnum = builder.enumType('BeverageSubtype', {
  description:
    'A structured refinement of a beverage type.\n\n' +
    'Each subtype is only valid for one beverage type (an `IPA` sits on a beer, a ' +
    '`WHISKY` on a spirit), and an invalid pairing is rejected on add and update. ' +
    '`SPARKLING` is shared by wine and sake; `OTHER` is the escape hatch that fits ' +
    'every type.',
  values: {
    SPARKLING: { value: 'sparkling', description: 'Sparkling wine or sparkling sake' },
    SWEET: { value: 'sweet', description: 'Sweet wine' },
    LATE_HARVEST: { value: 'late-harvest', description: 'Late-harvest wine (vendange tardive)' },
    VIN_JAUNE: { value: 'vin-jaune', description: 'Vin jaune (Jura)' },
    PORTO: { value: 'porto', description: 'Port wine' },
    FORTIFIED: { value: 'fortified', description: 'Fortified wine' },
    RUM: { value: 'rum', description: 'Rum (spirit)' },
    WHISKY: { value: 'whisky', description: 'Whisky (spirit)' },
    GIN: { value: 'gin', description: 'Gin (spirit)' },
    VODKA: { value: 'vodka', description: 'Vodka (spirit)' },
    COGNAC: { value: 'cognac', description: 'Cognac (spirit)' },
    ARMAGNAC: { value: 'armagnac', description: 'Armagnac (spirit)' },
    TEQUILA: { value: 'tequila', description: 'Tequila (spirit)' },
    LIQUEUR: { value: 'liqueur', description: 'Liqueur (spirit)' },
    EAU_DE_VIE: { value: 'eau-de-vie', description: 'Eau-de-vie (spirit)' },
    BLONDE: { value: 'blonde', description: 'Blonde beer' },
    BLANCHE: { value: 'blanche', description: 'Wheat beer (blanche)' },
    AMBER: { value: 'amber', description: 'Amber beer' },
    BRUNE: { value: 'brune', description: 'Brown beer (brune)' },
    IPA: { value: 'ipa', description: 'India pale ale (beer)' },
    STOUT: { value: 'stout', description: 'Stout (beer)' },
    PILS: { value: 'pils', description: 'Pilsner (beer)' },
    TRIPLE: { value: 'triple', description: 'Triple (beer)' },
    JUNMAI: { value: 'junmai', description: 'Junmai sake' },
    GINJO: { value: 'ginjo', description: 'Ginjo sake' },
    DAIGINJO: { value: 'daiginjo', description: 'Daiginjo sake' },
    HONJOZO: { value: 'honjozo', description: 'Honjozo sake' },
    NIGORI: { value: 'nigori', description: 'Nigori (cloudy) sake' },
    BRUT: { value: 'brut', description: 'Brut cider' },
    DOUX: { value: 'doux', description: 'Sweet cider (doux)' },
    DEMI_SEC: { value: 'demi-sec', description: 'Off-dry cider (demi-sec)' },
    POIRE: { value: 'poire', description: 'Perry (cidre de poire)' },
    OTHER: { value: 'other', description: 'Any other subtype; valid for every beverage type' },
  } as const,
})

export const BeverageTypeEnum = builder.enumType('BeverageType', {
  description:
    'The kind of beverage a bottle contains.\n\n' +
    'This is the discriminant of a `Beverage`: it selects the applicable subtypes and, ' +
    'for `WINE`, the presence of wine-only details.',
  values: {
    WINE: { value: 'wine', description: 'Wine; the only type carrying wine-specific details' },
    SPIRIT: { value: 'spirit', description: 'Spirit (rum, whisky, gin, ...)' },
    BEER: { value: 'beer', description: 'Beer' },
    SAKE: { value: 'sake', description: 'Sake' },
    CIDER: { value: 'cider', description: 'Cider' },
    OTHER: { value: 'other', description: 'Any beverage that fits none of the above' },
  } as const,
})

export const BeverageSortEnum = builder.enumType('BeverageSort', {
  description:
    'The field the beverage list is ordered by.\n\n' +
    'Paired with a `SortOrder` on the `beverages` query.',
  values: {
    CREATED_AT: { value: 'createdAt', description: 'Order by when the beverage was added' },
    UPDATED_AT: { value: 'updatedAt', description: 'Order by when the beverage was last changed' },
    VINTAGE: { value: 'vintage', description: 'Order by wine vintage year' },
    REGION: { value: 'region', description: 'Order by region name' },
    COLOR: { value: 'color', description: 'Order by wine color' },
    PRICE: { value: 'price', description: 'Order by purchase price' },
  } as const,
})

export const SortOrderEnum = builder.enumType('SortOrder', {
  description: 'The direction a sorted list runs in.',
  values: {
    ASC: { value: 'asc', description: 'Ascending order' },
    DESC: { value: 'desc', description: 'Descending order' },
  } as const,
})

export const BeverageListModeEnum = builder.enumType('BeverageListMode', {
  description:
    'The preset view of the beverage list to page through.\n\n' +
    'Chooses which collection of beverages the `beverages` query returns, before the ' +
    'other facets are applied.',
  values: {
    ALL: { value: 'all', description: 'Every beverage in the collection' },
    FAVORITES: { value: 'favorites', description: 'Beverages marked as a favorite' },
    GIFTED: { value: 'gifted', description: 'Beverages given away as a gift' },
    RECOMMENDED: { value: 'recommended', description: 'Beverages recommended by someone' },
  } as const,
})

export const BeverageStatusFilterEnum = builder.enumType('BeverageStatusFilter', {
  description:
    'An optional lifecycle filter applied to the beverage list.\n\n' +
    'Narrows the `beverages` query to a single cellar status.',
  values: {
    ALL: { value: 'all', description: 'No status filter' },
    IN_CELLAR: { value: 'in-cellar', description: 'Keep only bottles still in the cellar' },
    CONSUMED: { value: 'consumed', description: 'Keep only bottles that have been consumed' },
  } as const,
})

export const BeverageStatusEnum = builder.enumType('BeverageStatus', {
  description:
    'The lifecycle status of a beverage.\n\n' +
    'Where a bottle stands in its journey from the cellar to gone.',
  values: {
    IN_CELLAR: { value: 'in-cellar', description: 'Still stored in the cellar' },
    CONSUMED: { value: 'consumed', description: 'Opened and consumed' },
    GIFTED: { value: 'gifted', description: 'Given away as a gift' },
    RECOMMENDED: { value: 'recommended', description: 'Recommended, not owned' },
  } as const,
})
