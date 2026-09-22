import { describe, expect, test } from 'bun:test'
import {
  BottleDescription,
  MAX_BOTTLE_DESCRIPTION_LENGTH,
  parseScanResponse,
  scanLanguageFrom,
} from '~/domain/scan/primitives'

describe('scanLanguageFrom', () => {
  test('reads the primary subtag of the first listed language', () => {
    expect(scanLanguageFrom('de-CH,de;q=0.9,en;q=0.8')).toBe('de')
    expect(scanLanguageFrom('ja-JP')).toBe('ja')
    expect(scanLanguageFrom('PT-BR')).toBe('pt')
  })

  test('keeps a bare supported language as-is', () => {
    expect(scanLanguageFrom('fr')).toBe('fr')
    expect(scanLanguageFrom('it')).toBe('it')
  })

  test('falls back to English for an unsupported or missing language', () => {
    expect(scanLanguageFrom('nl-NL')).toBe('en')
    expect(scanLanguageFrom('')).toBe('en')
    expect(scanLanguageFrom(undefined)).toBe('en')
  })
})

describe('parseScanResponse', () => {
  // Gemini answers an absent field with an explicit null, which the model must
  // not carry: an absent cuvee is no cuvee at all.
  test('keeps the cuvee read on the label and drops an absent one', () => {
    expect(
      parseScanResponse('{"name":"Puligny","beverageType":"wine","cuvee":"Les Pucelles"}').cuvee,
    ).toBe('Les Pucelles')
    expect(
      parseScanResponse('{"name":"Margaux","beverageType":"wine","cuvee":null}').cuvee,
    ).toBeUndefined()
  })
})

describe('BottleDescription', () => {
  test('keeps what was typed, without the surrounding blanks', () => {
    expect<string>(BottleDescription('  Grange des Pères 2016 rouge \n')).toBe(
      'Grange des Pères 2016 rouge',
    )
  })

  test('refuses a description with nothing in it', () => {
    expect(() => BottleDescription('')).toThrow()
    expect(() => BottleDescription('   ')).toThrow()
  })

  test('refuses a description past the length a description needs', () => {
    expect(BottleDescription('a'.repeat(MAX_BOTTLE_DESCRIPTION_LENGTH))).toHaveLength(
      MAX_BOTTLE_DESCRIPTION_LENGTH,
    )
    expect(() => BottleDescription('a'.repeat(MAX_BOTTLE_DESCRIPTION_LENGTH + 1))).toThrow()
  })
})
