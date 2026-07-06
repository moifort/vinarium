import type { BeverageSubtype, WineColor } from '~/domain/wine/types'

// Best-effort translation of the pre-subtype data model (free-text style, a
// 5-value color enum that smuggled sparkling/sweet in) into today's structured
// fields. Shared by the Firestore migration (0003) and the scan-cache re-parse
// so both normalize identically. Pure, no IO — 100% covered in the sibling test.

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

// Maps the legacy free-text style (or the color that carried the subtype) to a
// structured subtype. No match yields undefined.
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
