import { describe, expect, test } from 'bun:test'
import {
  irrelevantAttributes,
  isFavorite,
  pureColor,
  readyToDrink,
  requiresColor,
  retainedSubtype,
  SUBTYPES_BY_BEVERAGE,
  subtypeAllowed,
  subtypeFromLegacy,
  urgentToDrink,
  wineStatus,
} from '~/domain/wine/business-rules'
import { BEVERAGE_SUBTYPE_VALUES } from '~/domain/wine/primitives'

describe('wineStatus', () => {
  test('in-cellar when bottle present', () => {
    expect(wineStatus({ inCellar: true, gifted: false, recommended: false })).toBe('in-cellar')
  })

  test('gifted when not in cellar and gifted', () => {
    expect(wineStatus({ inCellar: false, gifted: true, recommended: false })).toBe('gifted')
  })

  test('recommended when not in cellar, not gifted, and recommended', () => {
    expect(wineStatus({ inCellar: false, gifted: false, recommended: true })).toBe('recommended')
  })

  test('consumed when not in cellar, not gifted, not recommended', () => {
    expect(wineStatus({ inCellar: false, gifted: false, recommended: false })).toBe('consumed')
  })

  test('in-cellar takes priority over gifted', () => {
    expect(wineStatus({ inCellar: true, gifted: true, recommended: false })).toBe('in-cellar')
  })

  test('gifted takes priority over recommended', () => {
    expect(wineStatus({ inCellar: false, gifted: true, recommended: true })).toBe('gifted')
  })
})

describe('readyToDrink', () => {
  test('false when no drink window', () => {
    expect(readyToDrink({}, 2026)).toBe(false)
  })

  test('true when current year within window', () => {
    expect(readyToDrink({ from: 2024, until: 2028 }, 2026)).toBe(true)
  })

  test('false when before window', () => {
    expect(readyToDrink({ from: 2028, until: 2030 }, 2026)).toBe(false)
  })

  test('false when after window', () => {
    expect(readyToDrink({ from: 2020, until: 2024 }, 2026)).toBe(false)
  })

  test('true with only from in the past', () => {
    expect(readyToDrink({ from: 2024 }, 2026)).toBe(true)
  })

  test('true with only until in the future', () => {
    expect(readyToDrink({ until: 2028 }, 2026)).toBe(true)
  })
})

describe('urgentToDrink', () => {
  test('false when no drinkUntil', () => {
    expect(urgentToDrink({}, 2026)).toBe(false)
  })

  test('true when drinkUntil is next year', () => {
    expect(urgentToDrink({ until: 2027 }, 2026)).toBe(true)
  })

  test('true when drinkUntil is this year', () => {
    expect(urgentToDrink({ until: 2026 }, 2026)).toBe(true)
  })

  test('false when drinkUntil is 2+ years away', () => {
    expect(urgentToDrink({ until: 2030 }, 2026)).toBe(false)
  })
})

describe('isFavorite', () => {
  test('true when favorite flag is true', () => {
    expect(isFavorite({ favorite: true })).toBe(true)
  })

  test('false when favorite flag is false', () => {
    expect(isFavorite({ favorite: false })).toBe(false)
  })

  test('false when favorite flag is missing', () => {
    expect(isFavorite({})).toBe(false)
  })

  test('false when tasting is undefined', () => {
    expect(isFavorite(undefined)).toBe(false)
  })
})

describe('irrelevantAttributes', () => {
  test('a wine keeps every attribute (the subtype is relevant everywhere)', () => {
    expect(irrelevantAttributes('wine')).toEqual([])
  })

  test.each([
    'spirit',
    'beer',
    'sake',
    'cider',
    'other',
  ] as const)('a %s has no wine-specific attributes', (beverageType) => {
    expect(irrelevantAttributes(beverageType)).toEqual([
      'color',
      'grapeVarieties',
      'appellation',
      'classification',
      'drinkFrom',
      'drinkUntil',
      'servingTemperature',
    ])
  })
})

describe('subtypeAllowed', () => {
  test.each([
    ['wine', 'porto'],
    ['wine', 'sparkling'],
    ['wine', 'sweet'],
    ['spirit', 'rum'],
    ['spirit', 'whisky'],
    ['beer', 'blonde'],
    ['beer', 'ipa'],
    ['sake', 'junmai'],
    ['sake', 'sparkling'],
    ['cider', 'poire'],
  ] as const)('%s accepts %s', (beverageType, subtype) => {
    expect(subtypeAllowed(beverageType, subtype)).toBe(true)
  })

  test.each([
    ['spirit', 'ipa'],
    ['wine', 'rum'],
    ['beer', 'junmai'],
    ['sake', 'blonde'],
    ['cider', 'porto'],
    ['other', 'whisky'],
  ] as const)('%s rejects %s', (beverageType, subtype) => {
    expect(subtypeAllowed(beverageType, subtype)).toBe(false)
  })

  test.each([
    'wine',
    'spirit',
    'beer',
    'sake',
    'cider',
    'other',
  ] as const)("every type accepts 'other'", (beverageType) => {
    expect(subtypeAllowed(beverageType, 'other')).toBe(true)
  })

  test('the allowance table only contains known subtype values', () => {
    for (const subtypes of Object.values(SUBTYPES_BY_BEVERAGE)) {
      for (const subtype of subtypes) expect(BEVERAGE_SUBTYPE_VALUES).toContain(subtype)
    }
  })

  test('every subtype value belongs to at least one beverage type', () => {
    const reachable = new Set(Object.values(SUBTYPES_BY_BEVERAGE).flat())
    for (const subtype of BEVERAGE_SUBTYPE_VALUES) expect(reachable.has(subtype)).toBe(true)
  })
})

describe('retainedSubtype', () => {
  test('keeps a subtype still valid for the new type (sparkling wine → sake)', () => {
    expect(retainedSubtype('sake', 'sparkling')).toBe('sparkling')
  })

  test('drops a subtype invalid for the new type (IPA beer → wine)', () => {
    expect(retainedSubtype('wine', 'ipa')).toBeUndefined()
  })

  test('passes through an absent subtype', () => {
    expect(retainedSubtype('wine', undefined)).toBeUndefined()
  })
})

describe('pureColor', () => {
  test.each(['red', 'white', 'rosé'] as const)('keeps the pure color "%s"', (color) => {
    expect(pureColor(color)).toBe(color)
  })

  test.each(['sparkling', 'sweet'] as const)('maps legacy "%s" to white', (color) => {
    expect(pureColor(color)).toBe('white')
  })

  test('yields undefined for an unknown value', () => {
    expect(pureColor('blue')).toBeUndefined()
  })

  test('yields undefined when absent', () => {
    expect(pureColor(undefined)).toBeUndefined()
  })
})

describe('subtypeFromLegacy', () => {
  test('legacy sparkling color wins over the style text', () => {
    expect(subtypeFromLegacy({ color: 'sparkling', style: 'IPA' })).toBe('sparkling')
  })

  test('legacy sweet color maps to sweet', () => {
    expect(subtypeFromLegacy({ color: 'sweet' })).toBe('sweet')
  })

  test.each([
    ['Daiginjo', 'daiginjo'],
    ['Junmai Ginjo', 'ginjo'],
    ['Junmai', 'junmai'],
    ['Honjozo', 'honjozo'],
    ['Nigori', 'nigori'],
    ['Single Malt', 'whisky'],
    ['Whisky tourbé', 'whisky'],
    ['Whiskey', 'whisky'],
    ['Bourbon', 'whisky'],
    ['Blended', 'whisky'],
    ['Rhum agricole', 'rum'],
    ['Dark Rum', 'rum'],
    ['London Dry', 'gin'],
    ['Gin', 'gin'],
    ['Vodka', 'vodka'],
    ['Cognac XO', 'cognac'],
    ['Armagnac', 'armagnac'],
    ['Tequila reposado', 'tequila'],
    ['Mezcal', 'tequila'],
    ['Liqueur de poire', 'liqueur'],
    ['Eau-de-vie de prune', 'eau-de-vie'],
    ['Eau de vie', 'eau-de-vie'],
    ['IPA', 'ipa'],
    ['Imperial Stout', 'stout'],
    ['Pils', 'pils'],
    ['Lager', 'pils'],
    ['Triple', 'triple'],
    ['Blonde forte', 'blonde'],
    ['Blanche', 'blanche'],
    ['Ambrée', 'amber'],
    ['Amber Ale', 'amber'],
    ['Brune', 'brune'],
    ['Porto Tawny', 'porto'],
    ['Demi-sec', 'demi-sec'],
    ['Brut', 'brut'],
    ['Doux', 'doux'],
    ['Poiré', 'poire'],
    ['Pétillant', 'sparkling'],
    ['Sparkling', 'sparkling'],
    ['Mousseux', 'sparkling'],
    ['Moelleux', 'sweet'],
  ] as const)('maps legacy style "%s" to %s', (style, expected) => {
    expect(subtypeFromLegacy({ style })).toBe(expected)
  })

  test('daiginjo is matched before ginjo', () => {
    expect(subtypeFromLegacy({ style: 'Junmai Daiginjo' })).toBe('daiginjo')
  })

  test('yields undefined for an unmapped style', () => {
    expect(subtypeFromLegacy({ style: 'Fermier' })).toBeUndefined()
  })

  test('yields undefined without style nor legacy color', () => {
    expect(subtypeFromLegacy({ color: 'red' })).toBeUndefined()
    expect(subtypeFromLegacy({})).toBeUndefined()
  })
})

describe('requiresColor', () => {
  test('wine requires a color', () => {
    expect(requiresColor('wine')).toBe(true)
  })

  test.each([
    'spirit',
    'beer',
    'sake',
    'cider',
    'other',
  ] as const)('%s does not require a color', (beverageType) => {
    expect(requiresColor(beverageType)).toBe(false)
  })
})
