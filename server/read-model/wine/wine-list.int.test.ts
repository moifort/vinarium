import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import * as cellarRepo from '~/domain/cellar/repository'
import * as giftRepo from '~/domain/gift/repository'
import * as recommendationRepo from '~/domain/recommendation/repository'
import type { Eur, PersonName, Year } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/repository'
import type { Rating } from '~/domain/tasting/types'
import * as wineRepo from '~/domain/wine/repository'
import { WineListReadModel } from '~/read-model/wine/wine-list'
import { aCellarBottle, aGift, aRecommendation, aTastingNote, aWine } from '~/test/fixtures'

// Helper to access results without lodash union type issues
const all = async (...args: Parameters<typeof WineListReadModel.all>) =>
  (await WineListReadModel.all(...args)) as any[]

describe('WineListReadModel', () => {
  describe('status filtering', () => {
    test('status=in-cellar returns only wines with cellar entry', async () => {
      const inCellar = aWine()
      const notInCellar = aWine()
      await wineRepo.save(inCellar)
      await wineRepo.save(notInCellar)
      await cellarRepo.save(aCellarBottle({ wineId: inCellar.id }))

      const result = await all({ status: 'in-cellar' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(inCellar.id)
    })

    test('status=gifted returns wines not in cellar with gift', async () => {
      const gifted = aWine()
      const inCellar = aWine()
      await wineRepo.save(gifted)
      await wineRepo.save(inCellar)
      await giftRepo.save(aGift({ wineId: gifted.id }))
      await cellarRepo.save(aCellarBottle({ wineId: inCellar.id }))

      const result = await all({ status: 'gifted' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(gifted.id)
    })

    test('status=recommended returns wines not in cellar, not gifted, with recommendation', async () => {
      const recommended = aWine()
      await wineRepo.save(recommended)
      await recommendationRepo.save(aRecommendation({ wineId: recommended.id }))

      const result = await all({ status: 'recommended' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(recommended.id)
    })

    test('status=consumed returns wines not in cellar, not gifted, not recommended', async () => {
      const consumed = aWine()
      await wineRepo.save(consumed)

      const result = await all({ status: 'consumed' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(consumed.id)
    })

    test('no status filter returns all', async () => {
      await wineRepo.save(aWine())
      await wineRepo.save(aWine())
      const result = await all()
      expect(result).toHaveLength(2)
    })
  })

  describe('color filtering', () => {
    test('filters by color', async () => {
      await wineRepo.save(aWine({ color: 'red' }))
      await wineRepo.save(aWine({ color: 'white' }))

      const result = await all({ color: 'white' })
      expect(result).toHaveLength(1)
      expect(result[0].color).toBe('white')
    })
  })

  describe('sorting', () => {
    test('sorts by vintage asc', async () => {
      await wineRepo.save(aWine({ vintage: make<Year>()(2020) }))
      await wineRepo.save(aWine({ vintage: make<Year>()(2018) }))

      const result = await all({ sort: 'vintage', order: 'asc' })
      expect(result[0].vintage).toBe(2018)
      expect(result[1].vintage).toBe(2020)
    })

    test('sorts by price desc', async () => {
      await wineRepo.save(aWine({ purchasePrice: make<Eur>()(10) }))
      await wineRepo.save(aWine({ purchasePrice: make<Eur>()(50) }))

      const result = await all({ sort: 'price', order: 'desc' })
      expect(result[0].purchasePrice).toBe(50)
      expect(result[1].purchasePrice).toBe(10)
    })
  })

  describe('enrichment', () => {
    test('adds rating from tasting', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(aTastingNote({ wineId: wine.id, rating: make<Rating>()(5) }))

      const result = await all()
      expect(result[0].rating).toBe(5)
    })

    test('adds shortlist flag from tasting', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(
        aTastingNote({ wineId: wine.id, rating: make<Rating>()(3), shortlist: true }),
      )

      const result = await all()
      expect(result[0].shortlist).toBe(true)
    })

    test('shortlist defaults to false when tasting has no flag', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(aTastingNote({ wineId: wine.id, rating: make<Rating>()(4) }))

      const result = await all()
      expect(result[0].shortlist).toBe(false)
    })

    test('adds giftedTo from gift', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await giftRepo.save(aGift({ wineId: wine.id }))

      const result = await all()
      expect(result[0].giftedTo).toBe('Jean Dupont')
    })

    test('adds recommendedBy from recommendation', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await recommendationRepo.save(aRecommendation({ wineId: wine.id }))

      const result = await all()
      expect(result[0].recommendedBy).toBe('Marie Martin')
    })

    test('deduplicates contacts', async () => {
      const wine = aWine({ giftedBy: make<PersonName>()('Jean Dupont') })
      await wineRepo.save(wine)
      await giftRepo.save(aGift({ wineId: wine.id }))

      const result = await all()
      const jeanCount = result[0].contacts.filter((c: string) => c === 'Jean Dupont').length
      expect(jeanCount).toBe(1)
    })
  })
})
