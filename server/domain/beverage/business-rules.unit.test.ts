import { describe, expect, test } from 'bun:test'
import {
  beverageStatus,
  labelFamily,
  readyToDrink,
  requiresColor,
  retainedSubtype,
  SUBTYPES_BY_BEVERAGE,
  subtypeAllowed,
  urgentToDrink,
  wineDetails,
} from '~/domain/beverage/business-rules'
import { BEVERAGE_SUBTYPE_VALUES } from '~/domain/beverage/primitives'
import type { Beverage } from '~/domain/beverage/types'

describe('beverageStatus', () => {
  test('in-cellar when bottle present', () => {
    expect(beverageStatus({ inCellar: true, gifted: false, recommended: false })).toBe('in-cellar')
  })

  test('gifted when not in cellar and gifted', () => {
    expect(beverageStatus({ inCellar: false, gifted: true, recommended: false })).toBe('gifted')
  })

  test('recommended when not in cellar, not gifted, and recommended', () => {
    expect(beverageStatus({ inCellar: false, gifted: false, recommended: true })).toBe(
      'recommended',
    )
  })

  test('consumed when not in cellar, not gifted, not recommended', () => {
    expect(beverageStatus({ inCellar: false, gifted: false, recommended: false })).toBe('consumed')
  })

  test('in-cellar takes priority over gifted', () => {
    expect(beverageStatus({ inCellar: true, gifted: true, recommended: false })).toBe('in-cellar')
  })

  test('gifted takes priority over recommended', () => {
    expect(beverageStatus({ inCellar: false, gifted: true, recommended: true })).toBe('gifted')
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

describe('wineDetails', () => {
  test('returns the wine details of a wine', () => {
    const wine = {
      beverageType: 'wine',
      wine: { color: 'red', vintage: 2015 },
    } as Beverage
    expect(wineDetails(wine)?.color).toBe('red')
  })

  test.each(['spirit', 'beer', 'sake', 'cider', 'other'] as const)(
    'a %s has no wine details',
    (beverageType) => {
      expect(wineDetails({ beverageType } as Beverage)).toBeUndefined()
    },
  )
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

  test.each(['wine', 'spirit', 'beer', 'sake', 'cider', 'other'] as const)(
    "every type accepts 'other'",
    (beverageType) => {
      expect(subtypeAllowed(beverageType, 'other')).toBe(true)
    },
  )

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

describe('requiresColor', () => {
  test('wine requires a color', () => {
    expect(requiresColor('wine')).toBe(true)
  })

  test.each(['spirit', 'beer', 'sake', 'cider', 'other'] as const)(
    '%s does not require a color',
    (beverageType) => {
      expect(requiresColor(beverageType)).toBe(false)
    },
  )
})

describe('labelFamily', () => {
  const wine = (fields: Record<string, unknown> = {}, details: Record<string, unknown> = {}) =>
    ({ beverageType: 'wine', ...fields, wine: { color: 'red', ...details } }) as Beverage

  test.each(['spirit', 'beer', 'sake', 'cider', 'other'] as const)(
    'a %s wears the spirit label',
    (beverageType) => {
      expect(labelFamily({ beverageType } as Beverage)).toBe('spirit')
    },
  )

  test('a sparkling wine wears the champagne label, whatever its region', () => {
    expect(labelFamily(wine({ subtype: 'sparkling', region: 'Alsace' }, { color: 'white' }))).toBe(
      'champagne',
    )
  })

  test.each(['sweet', 'late-harvest', 'porto', 'fortified'])(
    'a %s wine wears the sweet label',
    (subtype) => {
      expect(labelFamily(wine({ subtype, region: 'Bordeaux' }, { color: 'white' }))).toBe('sweet')
    },
  )

  test.each(['Italie', 'Italy', 'Italia', 'Italien', 'イタリア'])(
    'a wine from %s wears the Italian label',
    (country) => {
      expect(labelFamily(wine({ country, region: 'Piemonte' }))).toBe('italy')
    },
  )

  test('a rosé wears the Provence label, even from Bordeaux', () => {
    expect(labelFamily(wine({ region: 'Bordeaux' }, { color: 'rosé' }))).toBe('provence')
  })

  test.each([
    ['Alsace', 'alsace'],
    ['Elsass', 'alsace'],
    ['Bourgogne', 'burgundy'],
    ['Burgundy', 'burgundy'],
    ['Borgoña', 'burgundy'],
    ['ブルゴーニュ', 'burgundy'],
    ['Bordeaux', 'chateau'],
    ['Médoc', 'chateau'],
    ['Vallée du Rhône', 'south'],
    ['RHÔNE', 'south'],
    ['Languedoc-Roussillon', 'south'],
  ] as const)('a wine from %s wears the %s label', (region, family) => {
    expect(labelFamily(wine({ region, producer: 'Domaine X' }))).toBe(family)
  })

  test('a Vin de France wears the natural label', () => {
    expect(
      labelFamily(wine({ producer: 'Domaine de l’Écu' }, { appellation: 'Vin de France' })),
    ).toBe('natural')
  })

  test('a producer named Château wears the château label', () => {
    expect(labelFamily(wine({ producer: 'Château Musar' }, { color: 'white' }))).toBe('chateau')
  })

  test('a producer named Domaine or Clos wears the Burgundy label', () => {
    expect(labelFamily(wine({ producer: 'Domaine Gauby' }))).toBe('burgundy')
    expect(labelFamily(wine({ producer: 'Clos Rougeard' }))).toBe('burgundy')
  })

  test('with nothing else to go on, a white wears the Burgundy label and a red the château', () => {
    expect(labelFamily(wine({}, { color: 'white' }))).toBe('burgundy')
    expect(labelFamily(wine())).toBe('chateau')
    expect(labelFamily(wine({}, { color: undefined }))).toBe('chateau')
  })
})
