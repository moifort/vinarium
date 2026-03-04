import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import * as cellarRepo from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import * as giftRepo from '~/domain/gift/repository'
import * as journalRepo from '~/domain/journal/repository'
import * as recommendationRepo from '~/domain/recommendation/repository'
import type { Eur, Year } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/repository'
import { WineQuery } from '~/domain/wine/query'
import * as wineRepo from '~/domain/wine/repository'
import {
  aCellarBottle,
  aGift,
  aJournalEntryIn,
  aJournalEntryOut,
  aRecommendation,
  aTastingNote,
  aWine,
} from '~/test/fixtures'

describe('WineQuery', () => {
  describe('getById', () => {
    test('returns wine when found', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      const result = await WineQuery.getById(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.id).toBe(wine.id)
    })

    test('returns not-found when absent', async () => {
      const wine = aWine()
      const result = await WineQuery.getById(wine.id)
      expect(result).toBe('not-found')
    })
  })

  describe('getAll — status filtering', () => {
    test('status=in-cellar returns only wines with cellar entry', async () => {
      const inCellar = aWine()
      const notInCellar = aWine()
      await wineRepo.save(inCellar)
      await wineRepo.save(notInCellar)
      await cellarRepo.save(aCellarBottle({ wineId: inCellar.id }))

      const result = await WineQuery.getAll({ status: 'in-cellar' })
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

      const result = await WineQuery.getAll({ status: 'gifted' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(gifted.id)
    })

    test('status=recommended returns wines not in cellar, not gifted, with recommendation', async () => {
      const recommended = aWine()
      await wineRepo.save(recommended)
      await recommendationRepo.save(aRecommendation({ wineId: recommended.id }))

      const result = await WineQuery.getAll({ status: 'recommended' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(recommended.id)
    })

    test('status=consumed returns wines not in cellar, not gifted, not recommended', async () => {
      const consumed = aWine()
      await wineRepo.save(consumed)

      const result = await WineQuery.getAll({ status: 'consumed' })
      expect(result).toHaveLength(1)
      expect(result[0].id).toBe(consumed.id)
    })

    test('no status filter returns all', async () => {
      await wineRepo.save(aWine())
      await wineRepo.save(aWine())
      const result = await WineQuery.getAll()
      expect(result).toHaveLength(2)
    })
  })

  describe('getAll — color filtering', () => {
    test('filters by color', async () => {
      await wineRepo.save(aWine({ color: 'red' }))
      await wineRepo.save(aWine({ color: 'white' }))

      const result = await WineQuery.getAll({ color: 'white' })
      expect(result).toHaveLength(1)
      expect(result[0].color).toBe('white')
    })
  })

  describe('getAll — sorting', () => {
    test('sorts by vintage asc', async () => {
      await wineRepo.save(aWine({ vintage: make<Year>()(2020) }))
      await wineRepo.save(aWine({ vintage: make<Year>()(2018) }))

      const result = await WineQuery.getAll({ sort: 'vintage', order: 'asc' })
      expect(result[0].vintage).toBe(2018)
      expect(result[1].vintage).toBe(2020)
    })

    test('sorts by price desc', async () => {
      await wineRepo.save(aWine({ purchasePrice: make<Eur>()(10) }))
      await wineRepo.save(aWine({ purchasePrice: make<Eur>()(50) }))

      const result = await WineQuery.getAll({ sort: 'price', order: 'desc' })
      expect(result[0].purchasePrice).toBe(50)
      expect(result[1].purchasePrice).toBe(10)
    })
  })

  describe('getAll — enrichment', () => {
    test('adds rating from tasting', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(aTastingNote({ wineId: wine.id, rating: make<Rating>()(5) }))

      const result = await WineQuery.getAll()
      expect(result[0].rating).toBe(5)
    })

    test('adds giftedTo from gift', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await giftRepo.save(aGift({ wineId: wine.id }))

      const result = await WineQuery.getAll()
      expect(result[0].giftedTo).toBe('Jean Dupont')
    })

    test('adds recommendedBy from recommendation', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await recommendationRepo.save(aRecommendation({ wineId: wine.id }))

      const result = await WineQuery.getAll()
      expect(result[0].recommendedBy).toBe('Marie Martin')
    })

    test('deduplicates contacts', async () => {
      const wine = aWine({ giftedBy: make<PersonName>()('Jean Dupont') })
      await wineRepo.save(wine)
      await giftRepo.save(aGift({ wineId: wine.id }))

      const result = await WineQuery.getAll()
      const jeanCount = result[0].contacts.filter((c: string) => c === 'Jean Dupont').length
      expect(jeanCount).toBe(1)
    })
  })

  describe('getDetail', () => {
    test('returns not-found for missing wine', async () => {
      const wine = aWine()
      const result = await WineQuery.getDetail(wine.id)
      expect(result).toBe('not-found')
    })

    test('includes cellar position when in cellar', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await cellarRepo.save(
        aCellarBottle({ wineId: wine.id, row: make<CellarRow>()(1), col: make<CellarCol>()(2) }),
      )

      const result = await WineQuery.getDetail(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.cellar?.rowLabel).toBe('B')
      expect(result.cellar?.colLabel).toBe(3)
    })

    test('reconstructs position from journal when not in cellar', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await journalRepo.save(aJournalEntryIn({ wineId: wine.id }))
      await journalRepo.save(aJournalEntryOut({ wineId: wine.id }))

      const result = await WineQuery.getDetail(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.cellar).toBeDefined()
      expect(result.cellar?.dateOut).toBeDefined()
    })

    test('aggregates tasting, gift, recommendation', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(aTastingNote({ wineId: wine.id }))
      await giftRepo.save(aGift({ wineId: wine.id }))
      await recommendationRepo.save(aRecommendation({ wineId: wine.id }))

      const result = await WineQuery.getDetail(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.consumption).toBeDefined()
      expect(result.gift).toBeDefined()
      expect(result.recommendation).toBeDefined()
    })
  })
})
