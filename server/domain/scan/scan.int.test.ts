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
    fake.seed('scan-cache', imageHash, {
      imageHash,
      result: { name: 'Château Margaux', color: 'red', vintage: 2018 },
      cachedAt: new Date('2026-01-01'),
    })

    const { result } = await Scan.scanWithCache(imageBuffer)

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

    const { result } = await Scan.scanWithCache(imageBuffer)

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

    const { result } = await Scan.scanWithCache(imageBuffer)

    expect(result.color).toBe('white')
    expect(result.subtype).toBe('sparkling')
  })
})
