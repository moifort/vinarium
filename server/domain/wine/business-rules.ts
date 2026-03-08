import type { WineStatus } from '~/domain/wine/types'

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

export const FAVORITE_RATING = 5

export const isFavorite = (rating?: number) => rating === FAVORITE_RATING
