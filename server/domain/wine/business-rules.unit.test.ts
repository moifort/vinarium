import { describe, expect, test } from 'bun:test'
import {
  irrelevantAttributes,
  isFavorite,
  readyToDrink,
  requiresColor,
  urgentToDrink,
  wineStatus,
} from '~/domain/wine/business-rules'

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
  test('a wine has no style', () => {
    expect(irrelevantAttributes('wine')).toEqual(['style'])
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
