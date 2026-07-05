import type { BeverageSubtype, BeverageType, WineColor, WineStatus } from '~/domain/wine/types'

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

// Normalizes the pre-subtype color enum: sparkling/sweet were wine subtypes
// crammed into the color; their actual robe was never captured, white is the
// most likely one. Unknown values yield undefined rather than a bad guess.
export const pureColor = (color?: string): WineColor | undefined => {
  if (color === 'red' || color === 'white' || color === 'rosé') return color
  if (color === 'sparkling' || color === 'sweet') return 'white'
  return undefined
}

// Ordered: more specific patterns first (daiginjo before ginjo before gin).
const LEGACY_STYLE_PATTERNS: readonly (readonly [string, BeverageSubtype])[] = [
  ['daiginjo', 'daiginjo'],
  ['ginjo', 'ginjo'],
  ['junmai', 'junmai'],
  ['honjozo', 'honjozo'],
  ['nigori', 'nigori'],
  ['single malt', 'whisky'],
  ['whisky', 'whisky'],
  ['whiskey', 'whisky'],
  ['bourbon', 'whisky'],
  ['blended', 'whisky'],
  ['rhum', 'rum'],
  ['rum', 'rum'],
  ['london dry', 'gin'],
  ['gin', 'gin'],
  ['vodka', 'vodka'],
  ['cognac', 'cognac'],
  ['armagnac', 'armagnac'],
  ['tequila', 'tequila'],
  ['mezcal', 'tequila'],
  ['liqueur', 'liqueur'],
  ['eau-de-vie', 'eau-de-vie'],
  ['eau de vie', 'eau-de-vie'],
  ['ipa', 'ipa'],
  ['stout', 'stout'],
  ['pils', 'pils'],
  ['lager', 'pils'],
  ['triple', 'triple'],
  ['blonde', 'blonde'],
  ['blanche', 'blanche'],
  ['ambrée', 'amber'],
  ['amber', 'amber'],
  ['brune', 'brune'],
  ['porto', 'porto'],
  ['demi-sec', 'demi-sec'],
  ['brut', 'brut'],
  ['doux', 'doux'],
  ['poiré', 'poire'],
  ['poire', 'poire'],
  ['pétillant', 'sparkling'],
  ['sparkling', 'sparkling'],
  ['mousseux', 'sparkling'],
  ['moelleux', 'sweet'],
] as const

// Best-effort mapping of the legacy data (free-text style, 5-value color enum)
// to a structured subtype. Shared by the Firestore migration and the scan-cache
// re-parse so both normalize identically. No match yields undefined.
export const subtypeFromLegacy = (legacy: {
  style?: string
  color?: string
}): BeverageSubtype | undefined => {
  if (legacy.color === 'sparkling') return 'sparkling'
  if (legacy.color === 'sweet') return 'sweet'
  const style = legacy.style?.toLowerCase()
  if (!style) return undefined
  return LEGACY_STYLE_PATTERNS.find(([pattern]) => style.includes(pattern))?.[1]
}

// Favorite is now an explicit heart flag, decoupled from the star rating:
// a wine can be a favorite whatever its note (or with no note at all).
export const isFavorite = (tasting?: { favorite?: boolean }) => tasting?.favorite === true
