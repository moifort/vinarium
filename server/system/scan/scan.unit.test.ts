import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { createHash } from 'node:crypto'
import { imageWithinSizeLimit, MAX_BASE64_LENGTH, MAX_IMAGE_SIZE_BYTES } from '~/system/scan/limits'
import { parseScanResponse } from '~/system/scan/primitives'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { Scan } = await import('~/system/scan/index')

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
      for (const color of ['red', 'white', 'rosé'] as const) {
        const result = parseScanResponse(JSON.stringify({ name: 'Test', color }))
        expect(result.color).toBe(color)
      }
    })

    test('normalizes the legacy pseudo-colors to white plus a subtype', () => {
      const sparkling = parseScanResponse(JSON.stringify({ name: 'Crémant', color: 'sparkling' }))
      expect(sparkling.color).toBe('white')
      expect(sparkling.subtype).toBe('sparkling')

      const sweet = parseScanResponse(JSON.stringify({ name: 'Sauternes', color: 'sweet' }))
      expect(sweet.color).toBe('white')
      expect(sweet.subtype).toBe('sweet')
    })

    test('parses a non-wine beverage with subtype and alcohol content', () => {
      const beer = JSON.stringify({
        name: 'La Chouffe',
        beverageType: 'beer',
        subtype: 'blonde',
        alcoholContent: 8,
        country: 'Belgique',
      })
      const result = parseScanResponse(beer)
      expect(result.beverageType).toBe('beer')
      expect(result.subtype).toBe('blonde')
      expect(result.alcoholContent).toBe(8)
      expect(result.color).toBeUndefined()
    })

    test('maps a legacy free-text style to a structured subtype', () => {
      const beer = JSON.stringify({
        name: 'La Chouffe',
        beverageType: 'beer',
        style: 'Blonde forte',
      })
      expect(parseScanResponse(beer).subtype).toBe('blonde')
    })

    test('degrades a hallucinated out-of-enum subtype to undefined', () => {
      const result = parseScanResponse(
        JSON.stringify({ name: 'Test', beverageType: 'beer', subtype: 'super-blonde' }),
      )
      expect(result.subtype).toBeUndefined()
    })

    test('drops a subtype incoherent with the beverage type', () => {
      const result = parseScanResponse(
        JSON.stringify({ name: 'Test', beverageType: 'beer', subtype: 'junmai' }),
      )
      expect(result.subtype).toBeUndefined()
    })

    test('accepts all valid beverage types', () => {
      for (const beverageType of ['wine', 'spirit', 'beer', 'sake', 'cider', 'other'] as const) {
        const result = parseScanResponse(JSON.stringify({ name: 'Test', beverageType }))
        expect(result.beverageType).toBe(beverageType)
      }
    })

    test('defaults beverageType to wine when absent from the parsed payload', () => {
      const result = parseScanResponse(validGeminiResponse)
      expect(result.beverageType).toBe('wine')
    })

    test('accepts a wine without color — the form will require one before saving', () => {
      const result = parseScanResponse(JSON.stringify({ name: 'Vin', beverageType: 'wine' }))
      expect(result.color).toBeUndefined()
    })

    test('accepts explicit nulls — the Gemini schema marks absent fields as null', () => {
      // Reproduces the production payload that crashed the scan: the prompt
      // instructs Gemini to set unknown fields to null, not to omit them.
      const withNulls = JSON.stringify({
        name: 'Vin de Table',
        beverageType: 'wine',
        color: 'red',
        style: null,
        alcoholContent: null,
        domain: null,
        vintage: null,
        appellation: null,
        region: null,
        country: null,
        grapeVarieties: [],
        classification: null,
        drinkFrom: null,
        drinkUntil: null,
        estimatedPrice: null,
      })

      const result = parseScanResponse(withNulls)

      expect(result.name).toBe('Vin de Table')
      expect(result.domain).toBeUndefined()
      expect(result.vintage).toBeUndefined()
      expect(result.appellation).toBeUndefined()
      expect(result.subtype).toBeUndefined()
    })
  })

  describe('malformed or invalid-shape JSON', () => {
    test('throws on non-JSON text', () => {
      expect(() => parseScanResponse('not json at all')).toThrow()
    })

    test('throws when name field is missing', () => {
      expect(() => parseScanResponse(JSON.stringify({ color: 'red' }))).toThrow()
    })

    test('throws when color is not a valid enum value', () => {
      expect(() => parseScanResponse(JSON.stringify({ name: 'Vin', color: 'purple' }))).toThrow()
    })

    test('throws when beverageType is not a valid enum value', () => {
      expect(() =>
        parseScanResponse(JSON.stringify({ name: 'Jus', beverageType: 'juice' })),
      ).toThrow()
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

describe('scanWithCache', () => {
  let fake = resetFakeFirestore()

  beforeEach(() => {
    fake = resetFakeFirestore()
  })

  test('normalizes legacy cached results without beverageType to wine', async () => {
    const imageBuffer = Buffer.from('fake-jpeg-bytes')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    // Cached before multi-beverage support: no beverageType field
    fake.seed('scan-cache', imageHash, {
      imageHash,
      result: { name: 'Château Margaux', color: 'red', vintage: 2018 },
      cachedAt: new Date('2026-01-01'),
    })

    const result = await Scan.scanWithCache(imageBuffer)

    expect(result.beverageType).toBe('wine')
    expect(result.name).toBe('Château Margaux')
    expect(result.color).toBe('red')
  })

  test('normalizes a legacy cached free-text style to a structured subtype', async () => {
    const imageBuffer = Buffer.from('other-fake-jpeg-bytes')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    fake.seed('scan-cache', imageHash, {
      imageHash,
      result: { name: 'La Chouffe', beverageType: 'beer', style: 'Blonde forte' },
      cachedAt: new Date('2026-01-01'),
    })

    const result = await Scan.scanWithCache(imageBuffer)

    expect(result.beverageType).toBe('beer')
    expect(result.subtype).toBe('blonde')
  })

  test('normalizes a legacy cached sparkling color to white + sparkling subtype', async () => {
    const imageBuffer = Buffer.from('sparkling-fake-jpeg-bytes')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    fake.seed('scan-cache', imageHash, {
      imageHash,
      result: { name: 'Crémant d’Alsace', beverageType: 'wine', color: 'sparkling' },
      cachedAt: new Date('2026-01-01'),
    })

    const result = await Scan.scanWithCache(imageBuffer)

    expect(result.color).toBe('white')
    expect(result.subtype).toBe('sparkling')
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
