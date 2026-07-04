import type { BeverageType, WineStatus } from '~/domain/wine/types'

type DrinkWindow = { from?: number; until?: number }

export const wineStatus = (context?: {
  inCellar: boolean
  gifted: boolean
  recommended: boolean
}): WineStatus => {
  if (context?.inCellar) return 'in-cellar'
  if (context?.gifted) return 'gifted'
  if (context?.recommended) return 'recommended'
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
export const irrelevantAttributes = (beverageType: BeverageType) =>
  beverageType === 'wine' ? (['style'] as const) : WINE_ONLY_ATTRIBUTES

// Favorite is now an explicit heart flag, decoupled from the star rating:
// a wine can be a favorite whatever its note (or with no note at all).
export const isFavorite = (tasting?: { favorite?: boolean }) => tasting?.favorite === true
