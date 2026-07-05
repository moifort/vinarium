import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import type { Wine, WineColor, WineId, WineName } from '~/domain/wine/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { WineCommand } = await import('~/domain/wine/command')

const userId = 'user-1' as UserId
const name = (value: string) => value as WineName

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('WineCommand.add', () => {
  test('saves a wine with its color', async () => {
    const result = await WineCommand.add(userId, name('Margaux'), 'wine', {
      color: 'red' as WineColor,
    })

    expect(result).not.toBe('color-required')
    const wine = result as Wine
    expect(wine.beverageType).toBe('wine')
    expect(wine.color).toBe('red')
    expect(fake.snapshot('wines').get(wine.id as string)?.beverageType).toBe('wine')
  })

  test('rejects a wine without color and writes nothing', async () => {
    const result = await WineCommand.add(userId, name('Margaux'), 'wine', {})

    expect(result).toBe('color-required')
    expect(fake.snapshot('wines').size).toBe(0)
    expect(fake.directWrites).toEqual([])
  })

  test('saves a spirit without color', async () => {
    const result = await WineCommand.add(userId, name('Lagavulin 16'), 'spirit', {
      subtype: 'whisky',
      alcoholContent: 43,
    })

    expect(result).not.toBe('color-required')
    const spirit = result as Wine
    expect(spirit.beverageType).toBe('spirit')
    expect(spirit.color).toBeUndefined()
    expect(spirit.subtype).toBe('whisky')
    expect(spirit.alcoholContent).toBe(43)
  })

  test('rejects a subtype foreign to the beverage type and writes nothing', async () => {
    const result = await WineCommand.add(userId, name('Lagavulin 16'), 'spirit', {
      subtype: 'ipa',
    })

    expect(result).toBe('subtype-invalid')
    expect(fake.snapshot('wines').size).toBe(0)
  })

  test('saves a wine with a wine subtype', async () => {
    const result = await WineCommand.add(userId, name('Taylor’s Tawny'), 'wine', {
      color: 'red' as WineColor,
      subtype: 'porto',
    })

    expect(result).not.toBe('subtype-invalid')
    expect((result as Wine).subtype).toBe('porto')
  })
})

describe('WineCommand.update', () => {
  const seedBeer = () => {
    const beer: Wine = {
      id: 'b06cd9e2-8a7f-4a05-9b0e-111111111111' as WineId,
      userId,
      name: name('Chouffe'),
      beverageType: 'beer',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    }
    fake.seed('wines', beer.id as string, beer)
    return beer
  }

  test('rejects switching to wine without providing a color', async () => {
    const beer = seedBeer()

    const result = await WineCommand.update(userId, beer.id, { beverageType: 'wine' })

    expect(result).toBe('color-required')
    expect(fake.snapshot('wines').get(beer.id as string)?.beverageType).toBe('beer')
  })

  test('switches to wine when a color is provided', async () => {
    const beer = seedBeer()

    const result = await WineCommand.update(userId, beer.id, {
      beverageType: 'wine',
      color: 'white' as WineColor,
    })

    expect(result).not.toBe('color-required')
    expect(fake.snapshot('wines').get(beer.id as string)?.beverageType).toBe('wine')
  })

  test('updates a beverage without color when its type does not require one', async () => {
    const beer = seedBeer()

    const result = await WineCommand.update(userId, beer.id, { subtype: 'blonde' })

    expect(result).not.toBe('color-required')
    expect(fake.snapshot('wines').get(beer.id as string)?.subtype).toBe('blonde')
  })

  test('rejects an explicit subtype foreign to the (new) beverage type', async () => {
    const beer = seedBeer()

    const result = await WineCommand.update(userId, beer.id, { subtype: 'junmai' })

    expect(result).toBe('subtype-invalid')
    expect(fake.snapshot('wines').get(beer.id as string)?.subtype).toBeUndefined()
  })

  test('clears wine-specific attributes when a wine becomes a beer', async () => {
    const wine: Wine = {
      id: 'b06cd9e2-8a7f-4a05-9b0e-222222222222' as WineId,
      userId,
      name: name('Margaux'),
      beverageType: 'wine',
      color: 'red' as WineColor,
      grapeVarieties: ['Merlot'],
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    }
    fake.seed('wines', wine.id as string, wine)

    const result = await WineCommand.update(userId, wine.id, { beverageType: 'beer' })

    expect(result).not.toBe('color-required')
    const saved = fake.snapshot('wines').get(wine.id as string)
    expect(saved?.color).toBeUndefined()
    expect(saved?.grapeVarieties).toBeUndefined()
    expect(saved?.beverageType).toBe('beer')
  })

  test('drops an inherited subtype that no longer fits the new type', async () => {
    const beer = seedBeer()
    fake.seed('wines', beer.id as string, { ...beer, subtype: 'ipa' })

    const result = await WineCommand.update(userId, beer.id, {
      beverageType: 'wine',
      color: 'white' as WineColor,
    })

    expect(result).not.toBe('subtype-invalid')
    const saved = fake.snapshot('wines').get(beer.id as string)
    expect(saved?.subtype).toBeUndefined()
    expect(saved?.color).toBe('white')
  })

  test('keeps an inherited subtype still valid for the new type', async () => {
    const wine: Wine = {
      id: 'b06cd9e2-8a7f-4a05-9b0e-333333333333' as WineId,
      userId,
      name: name('Crémant'),
      beverageType: 'wine',
      color: 'white' as WineColor,
      subtype: 'sparkling',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    }
    fake.seed('wines', wine.id as string, wine)

    const result = await WineCommand.update(userId, wine.id, { beverageType: 'sake' })

    expect(result).not.toBe('subtype-invalid')
    const saved = fake.snapshot('wines').get(wine.id as string)
    expect(saved?.beverageType).toBe('sake')
    expect(saved?.subtype).toBe('sparkling')
  })
})
