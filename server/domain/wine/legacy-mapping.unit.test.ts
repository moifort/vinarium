import { describe, expect, test } from 'bun:test'
import { pureColor, subtypeFromLegacy } from '~/domain/wine/legacy-mapping'

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
