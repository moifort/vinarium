import { describe, expect, test } from 'bun:test'
import { parseScanResponse, scanLanguageFrom } from '~/domain/scan/primitives'

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
