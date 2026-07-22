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
  WineDetails,
} from '~/domain/beverage/types'

// Years as plain numbers: the drink-window rules are pure arithmetic, decoupled
// from the branded Year of the aggregate (a Year is assignable to number).
type YearRange = { from?: number; until?: number }

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
