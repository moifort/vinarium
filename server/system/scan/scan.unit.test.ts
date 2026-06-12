import { describe, expect, test } from 'bun:test'
import { imageWithinSizeLimit, MAX_BASE64_LENGTH, MAX_IMAGE_SIZE_BYTES } from '~/system/scan/limits'
import { parseScanResponse } from '~/system/scan/primitives'

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
      expect(() => parseScanResponse('{"name": 42, "color": "red"}')).toThrow()
    })
  })
})

describe('scanWine upload size guard', () => {
  test('accepts a payload exactly at the limit', () => {
    expect(imageWithinSizeLimit(MAX_BASE64_LENGTH)).toBe(true)
  })

  test('rejects a payload one character over the limit', () => {
    expect(imageWithinSizeLimit(MAX_BASE64_LENGTH + 1)).toBe(false)
  })

  test('a 10 MB decoded image base64-encodes to a length that exceeds the limit', () => {
    // MAX_IMAGE_SIZE_BYTES is the decoded ceiling; base64 adds ~33 % overhead,
    // so a buffer of that size + 1 byte must produce a base64 string that fails the guard.
    const tenMbPlusOneBuffer = Buffer.alloc(MAX_IMAGE_SIZE_BYTES + 1)
    const base64 = tenMbPlusOneBuffer.toString('base64')
    expect(imageWithinSizeLimit(base64.length)).toBe(false)
  })
})
