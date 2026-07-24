import { describe, expect, test } from 'bun:test'
import { scanLanguageFrom } from '~/domain/scan/primitives'

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
