import type { BeverageSubtype, BeverageType, WineStatus } from '~/domain/wine/types'

type DrinkWindow = { from?: number; until?: number }

export const wineStatus = (context: {
  inCellar: boolean
  gifted: boolean
  recommended: boolean
}): WineStatus => {
  if (context.inCellar) return 'in-cellar'
  if (context.gifted) return 'gifted'
  if (context.recommended) return 'recommended'
  return 'consumed'
}

export const readyToDrink = (window: DrinkWindow, year: number) => {
  if (!window.from && !window.until) return false
  return (!window.from || window.from <= year) && (!window.until || window.until >= year)
}

export const urgentToDrink = (window: DrinkWindow, year: number) => {
  if (!window.until) return false
  return window.until <= year + 1
}

export const requiresColor = (beverageType: BeverageType) => beverageType === 'wine'

const WINE_ONLY_ATTRIBUTES = [
  'color',
  'grapeVarieties',
  'appellation',
  'classification',
  'drinkFrom',
  'drinkUntil',
  'servingTemperature',
] as const

// Attributes that carry no meaning for the given beverage type — cleared on save
// so a wine turned into a beer does not keep a ghost color or grape varieties.
// The subtype is relevant to every type; its cross-validation lives below.
export const irrelevantAttributes = (beverageType: BeverageType) =>
  beverageType === 'wine' ? ([] as const) : WINE_ONLY_ATTRIBUTES

// Which subtype values make sense for each beverage type. 'sparkling' is shared
// by wine and sake (saké pétillant); 'other' is the escape hatch everywhere.
// Mirrored in iOS BeverageSubtype.allowed(for:) — keep both in sync.
export const SUBTYPES_BY_BEVERAGE: Record<BeverageType, readonly BeverageSubtype[]> = {
  wine: ['sparkling', 'sweet', 'late-harvest', 'vin-jaune', 'porto', 'fortified', 'other'],
  spirit: [
    'rum',
    'whisky',
    'gin',
    'vodka',
    'cognac',
    'armagnac',
    'tequila',
    'liqueur',
    'eau-de-vie',
    'other',
  ],
  beer: ['blonde', 'blanche', 'amber', 'brune', 'ipa', 'stout', 'pils', 'triple', 'other'],
  sake: ['junmai', 'ginjo', 'daiginjo', 'honjozo', 'nigori', 'sparkling', 'other'],
  cider: ['brut', 'doux', 'demi-sec', 'poire', 'other'],
  other: ['other'],
}

export const subtypeAllowed = (beverageType: BeverageType, subtype: BeverageSubtype) =>
  SUBTYPES_BY_BEVERAGE[beverageType].includes(subtype)

// When a beverage changes type, an inherited subtype survives only if it still
// makes sense: a sparkling wine turned sake stays sparkling, a beer turned wine
// loses its IPA.
export const retainedSubtype = (beverageType: BeverageType, subtype?: BeverageSubtype) =>
  subtype !== undefined && subtypeAllowed(beverageType, subtype) ? subtype : undefined

// Favorite is now an explicit heart flag, decoupled from the star rating:
// a wine can be a favorite whatever its note (or with no note at all).
export const isFavorite = (tasting?: { favorite?: boolean }) => tasting?.favorite === true
