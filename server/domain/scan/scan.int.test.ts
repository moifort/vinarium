import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { createHash } from 'node:crypto'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { Scan } = await import('~/domain/scan/index')

describe('scanWithCache', () => {
  let fake = resetFakeFirestore()

  beforeEach(() => {
    fake = resetFakeFirestore()
  })

  test('normalizes legacy cached results without beverageType to wine', async () => {
    const imageBuffer = Buffer.from('fake-jpeg-bytes')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    // Cached before multi-beverage support: no beverageType field
    fake.seed('scan-cache', `${imageHash}_fr`, {
      imageHash,
      language: 'fr',
      result: { name: 'Château Margaux', color: 'red', vintage: 2018 },
      cachedAt: new Date('2026-01-01'),
    })

    const { result } = await Scan.scanWithCache(imageBuffer, 'fr')

    expect(result.beverageType).toBe('wine')
    expect(result.name).toBe('Château Margaux')
    expect(result.color).toBe('red')
  })

  test('normalizes a legacy cached free-text style to a structured subtype', async () => {
    const imageBuffer = Buffer.from('other-fake-jpeg-bytes')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    fake.seed('scan-cache', `${imageHash}_fr`, {
      imageHash,
      language: 'fr',
      result: { name: 'La Chouffe', beverageType: 'beer', style: 'Blonde forte' },
      cachedAt: new Date('2026-01-01'),
    })

    const { result } = await Scan.scanWithCache(imageBuffer, 'fr')

    expect(result.beverageType).toBe('beer')
    expect(result.subtype).toBe('blonde')
  })

  test('normalizes a legacy cached sparkling color to white + sparkling subtype', async () => {
    const imageBuffer = Buffer.from('sparkling-fake-jpeg-bytes')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    fake.seed('scan-cache', `${imageHash}_fr`, {
      imageHash,
      language: 'fr',
      result: { name: 'Crémant d’Alsace', beverageType: 'wine', color: 'sparkling' },
      cachedAt: new Date('2026-01-01'),
    })

    const { result } = await Scan.scanWithCache(imageBuffer, 'fr')

    expect(result.color).toBe('white')
    expect(result.subtype).toBe('sparkling')
  })

  test('serves each language its own cache entry for the same image', async () => {
    const imageBuffer = Buffer.from('same-label-two-languages')
    const imageHash = createHash('sha256').update(imageBuffer).digest('hex')
    // The same label, cached once per language: a hit must return the entry
    // written in the caller's language, never the other one's text.
    fake.seed('scan-cache', `${imageHash}_fr`, {
      imageHash,
      language: 'fr',
      result: { name: 'Château Margaux', beverageType: 'wine', country: 'France' },
      cachedAt: new Date('2026-01-01'),
    })
    fake.seed('scan-cache', `${imageHash}_ja`, {
      imageHash,
      language: 'ja',
      result: { name: 'シャトー・マルゴー', beverageType: 'wine', country: 'フランス' },
      cachedAt: new Date('2026-01-01'),
    })

    const fr = await Scan.scanWithCache(imageBuffer, 'fr')
    const ja = await Scan.scanWithCache(imageBuffer, 'ja')

    expect(fr.cacheHit).toBe(true)
    expect(ja.cacheHit).toBe(true)
    expect(fr.result.country).toBe('France')
    expect(ja.result.country).toBe('フランス')
  })
})
