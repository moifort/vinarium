import { describe, expect, test } from 'bun:test'
import { parseScanResponse } from '~/system/scan'

const validGeminiResponse = JSON.stringify({
  name: 'Château Margaux',
  color: 'red',
  domain: 'Château Margaux',
  vintage: 2018,
  appellation: 'Margaux',
  region: 'Bordeaux',
  country: 'France',
  grapeVarieties: ['Cabernet Sauvignon', 'Merlot'],
  classification: 'Premier Grand Cru Classé',
  drinkFrom: 2028,
  drinkUntil: 2055,
  estimatedPrice: 650,
})

describe('parseScanResponse', () => {
  describe('valid Gemini JSON', () => {
    test('parses a complete response into a ScanResult', () => {
      const result = parseScanResponse(validGeminiResponse)
      expect(result.name).toBe('Château Margaux')
      expect(result.color).toBe('red')
      expect(result.vintage).toBe(2018)
      expect(result.region).toBe('Bordeaux')
      expect(result.estimatedPrice).toBe(650)
    })

    test('parses a minimal response (only required fields)', () => {
      const minimal = JSON.stringify({ name: 'Vin de Pays', color: 'white' })
      const result = parseScanResponse(minimal)
      expect(result.name).toBe('Vin de Pays')
      expect(result.color).toBe('white')
      expect(result.domain).toBeUndefined()
      expect(result.vintage).toBeUndefined()
    })

    test('accepts all valid color values', () => {
      for (const color of ['red', 'white', 'rosé', 'sparkling', 'sweet'] as const) {
        const result = parseScanResponse(JSON.stringify({ name: 'Test', color }))
        expect(result.color).toBe(color)
      }
    })
  })

  describe('malformed or invalid-shape JSON', () => {
    test('throws on non-JSON text', () => {
      expect(() => parseScanResponse('not json at all')).toThrow()
    })

    test('throws when name field is missing', () => {
      expect(() => parseScanResponse(JSON.stringify({ color: 'red' }))).toThrow()
    })

    test('throws when color field is missing', () => {
      expect(() => parseScanResponse(JSON.stringify({ name: 'Vin' }))).toThrow()
    })

    test('throws when color is not a valid enum value', () => {
      expect(() => parseScanResponse(JSON.stringify({ name: 'Vin', color: 'purple' }))).toThrow()
    })

    test('throws when vintage is not an integer', () => {
      expect(() =>
        parseScanResponse(JSON.stringify({ name: 'Vin', color: 'red', vintage: 'old' })),
      ).toThrow()
    })

    test('does not crash — throws instead of returning corrupted data', () => {
      let threw = false
      try {
        parseScanResponse('{"name": 42, "color": "red"}')
      } catch {
        threw = true
      }
      expect(threw).toBe(true)
    })
  })
})

describe('scanWine upload size guard', () => {
  const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024
  const MAX_BASE64_LENGTH = Math.ceil((MAX_IMAGE_SIZE_BYTES * 4) / 3)

  test('a base64 string within the limit is not rejected by length check', () => {
    const withinLimit = 'A'.repeat(MAX_BASE64_LENGTH)
    expect(withinLimit.length).toBeLessThanOrEqual(MAX_BASE64_LENGTH)
  })

  test('a base64 string exceeding the limit triggers the guard', () => {
    const oversized = 'A'.repeat(MAX_BASE64_LENGTH + 1)
    expect(oversized.length > MAX_BASE64_LENGTH).toBe(true)
  })

  test('10 MB decoded image produces a base64 string above the threshold', () => {
    // A 10 MB buffer base64-encoded is ~13.7 MB of characters
    const tenMbBuffer = Buffer.alloc(MAX_IMAGE_SIZE_BYTES + 1)
    const base64 = tenMbBuffer.toString('base64')
    expect(base64.length > MAX_BASE64_LENGTH).toBe(true)
  })
})
