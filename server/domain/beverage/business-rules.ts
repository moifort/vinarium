import {
  BEER_SUBTYPES,
  CIDER_SUBTYPES,
  OTHER_SUBTYPES,
  SAKE_SUBTYPES,
  SPIRIT_SUBTYPES,
  WINE_SUBTYPES,
} from '~/domain/beverage/primitives'
import type {
  Beverage,
  BeverageStatus,
  BeverageSubtype,
  BeverageType,
  ErasableField,
  LabelFamily,
  WineDetails,
} from '~/domain/beverage/types'

// Years as plain numbers: the drink-window rules are pure arithmetic, decoupled
// from the branded Year of the aggregate (a Year is assignable to number).
type YearRange = { from?: number; until?: number }

// Where each erasable field lives in the stored document. A write model that
// nests (purchase, place, wine, drinkWindow) still has to answer a flat "empty
// this one".
const fieldLocation: Record<ErasableField, readonly string[]> = {
  alcoholContent: ['alcoholContent'],
  producer: ['producer'],
  region: ['region'],
  country: ['country'],
  notes: ['notes'],
  subtype: ['subtype'],
  purchasePrice: ['purchase', 'price'],
  purchaseDate: ['purchase', 'date'],
  latitude: ['place', 'latitude'],
  longitude: ['place', 'longitude'],
  placeName: ['place', 'name'],
  color: ['wine', 'color'],
  vintage: ['wine', 'vintage'],
  appellation: ['wine', 'appellation'],
  cuvee: ['wine', 'cuvee'],
  classification: ['wine', 'classification'],
  grapeVarieties: ['wine', 'grapeVarieties'],
  servingTemperature: ['wine', 'servingTemperature'],
  drinkFrom: ['wine', 'drinkWindow', 'from'],
  drinkUntil: ['wine', 'drinkWindow', 'until'],
}

// Remove the named fields from a record, then drop the containers they leave
// empty: a purchase with neither price nor date is no purchase at all, and an
// empty object read back as `{}` would make the API answer a hollow node.
export const withoutFields = <T extends Record<string, unknown>>(
  record: T,
  fields: readonly ErasableField[],
): T => {
  if (fields.length === 0) return record
  const copy = structuredClone(record) as Record<string, unknown>
  for (const field of fields) {
    const path = fieldLocation[field]
    const parent = path.slice(0, -1).reduce<Record<string, unknown> | undefined>((node, key) => {
      const child = node?.[key]
      return child && typeof child === 'object' ? (child as Record<string, unknown>) : undefined
    }, copy)
    if (parent) delete parent[path[path.length - 1] as string]
  }
  pruneEmptyContainers(copy)
  return copy as T
}

// A wine always keeps its `wine` object (the type demands it); every other
// container disappears once it holds nothing.
const pruneEmptyContainers = (record: Record<string, unknown>) => {
  const wine = record.wine as Record<string, unknown> | undefined
  if (wine && isEmpty(wine.drinkWindow)) delete wine.drinkWindow
  for (const key of ['purchase', 'place'] as const) {
    if (isEmpty(record[key])) delete record[key]
  }
}

const isEmpty = (value: unknown) =>
  typeof value === 'object' && value !== null && Object.keys(value).length === 0

export const beverageStatus = (context: {
  inCellar: boolean
  gifted: boolean
  recommended: boolean
}): BeverageStatus => {
  if (context.inCellar) return 'in-cellar'
  if (context.gifted) return 'gifted'
  if (context.recommended) return 'recommended'
  return 'consumed'
}

export const readyToDrink = (window: YearRange, year: number) => {
  if (!window.from && !window.until) return false
  return (!window.from || window.from <= year) && (!window.until || window.until >= year)
}

export const urgentToDrink = (window: YearRange, year: number) => {
  if (!window.until) return false
  return window.until <= year + 1
}

// A wine is the only type that must declare its color.
export const requiresColor = (beverageType: BeverageType) => beverageType === 'wine'

// The wine-only details of a beverage, or undefined for any other type. Lets
// read models reach color/vintage/drinkWindow without re-narrowing the union.
export const wineDetails = (beverage: Beverage): WineDetails | undefined =>
  beverage.beverageType === 'wine' ? beverage.wine : undefined

// Which subtype values make sense for each beverage type — derived from the
// per-type sets in primitives.ts. 'sparkling' is shared by wine and sake (saké
// pétillant); 'other' is the escape hatch everywhere. Mirrored in iOS
// BeverageSubtype.allowed(for:) — keep both in sync.
export const SUBTYPES_BY_BEVERAGE: Record<BeverageType, readonly BeverageSubtype[]> = {
  wine: WINE_SUBTYPES,
  spirit: SPIRIT_SUBTYPES,
  beer: BEER_SUBTYPES,
  sake: SAKE_SUBTYPES,
  cider: CIDER_SUBTYPES,
  other: OTHER_SUBTYPES,
}

export const subtypeAllowed = (beverageType: BeverageType, subtype: BeverageSubtype) =>
  SUBTYPES_BY_BEVERAGE[beverageType].includes(subtype)

// When a beverage changes type, an inherited subtype survives only if it still
// makes sense: a sparkling wine turned sake stays sparkling, a beer turned wine
// loses its IPA.
export const retainedSubtype = (
  beverageType: BeverageType,
  subtype?: BeverageSubtype,
): BeverageSubtype | undefined =>
  subtype !== undefined && subtypeAllowed(beverageType, subtype) ? subtype : undefined

// Free text folded for matching: lower case, without accents, so "Rhône",
// "rhone" and "RHÔNE" read the same.
const folded = (text?: string) => (text ?? '').normalize('NFD').replace(/\p{M}/gu, '').toLowerCase()

// The regions whose labels have a house style, in the seven languages a region
// may be written in. Region is free text: a scan writes it in the user's
// language, a hand-typed one in any.
const REGION_FAMILIES: readonly [RegExp, LabelFamily][] = [
  [/alsace|elsass|alsazia|alsacia|アルザス/, 'alsace'],
  [/bourgogne|burgund|borgogna|borgona|borgonha|beaujolais|chablis|ブルゴーニュ/, 'burgundy'],
  [/bordeaux|bordeus|burdeos|bordo|medoc|graves|saint-emilion|pomerol|ボルドー/, 'chateau'],
  [/rhone|rodano|languedoc|roussillon|provence|provenza|corse|corsica|corcega|ローヌ/, 'south'],
]

// Wines drawn with the sweet label: what is served with dessert or after it.
const SWEET_SUBTYPES: readonly BeverageSubtype[] = ['sweet', 'late-harvest', 'porto', 'fortified']

// Appellations that say the wine stands outside the appellation system: the
// natural-wine label, loose and hand-drawn.
const NATURAL_APPELLATION = /vin de france|vin de table|vino da tavola|vino de mesa/

// The label family a bottle is drawn with. What the wine is decides first (a
// spirit, a sparkling wine, a sweet one), then where it comes from (Italy, a
// rosé, a region with a house style), then how it names itself (a château, a
// domaine); a white falls back to the Burgundy label, everything else to the
// château.
export const labelFamily = (beverage: Beverage): LabelFamily => {
  if (beverage.beverageType !== 'wine') return 'spirit'
  const { subtype } = beverage
  // A wine stored before the details object existed carries none.
  const wine: WineDetails = beverage.wine ?? {}
  if (subtype === 'sparkling') return 'champagne'
  if (SWEET_SUBTYPES.includes(subtype as BeverageSubtype)) return 'sweet'
  const country = folded(beverage.country)
  if (/ital|イタリア/.test(country)) return 'italy'
  if (wine.color === 'rosé') return 'provence'
  const region = folded(beverage.region)
  const byRegion = REGION_FAMILIES.find(([pattern]) => pattern.test(region))
  if (byRegion) return byRegion[1]
  if (NATURAL_APPELLATION.test(folded(wine.appellation))) return 'natural'
  const producer = folded(beverage.producer)
  if (/^(chateau|castello|castillo)\b/.test(producer)) return 'chateau'
  if (/^(domaine|clos)\b/.test(producer)) return 'burgundy'
  return wine.color === 'white' ? 'burgundy' : 'chateau'
}
