import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import * as cellarRepo from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import * as giftRepo from '~/domain/gift/repository'
import * as journalRepo from '~/domain/journal/repository'
import * as recommendationRepo from '~/domain/recommendation/repository'
import * as tastingRepo from '~/domain/tasting/repository'
import * as wineRepo from '~/domain/wine/repository'
import { WineDetailReadModel } from '~/read-model/wine/wine-detail'
import {
  aCellarBottle,
  aGift,
  aJournalEntryIn,
  aJournalEntryOut,
  aRecommendation,
  aTastingNote,
  aWine,
} from '~/test/fixtures'

describe('WineDetailReadModel', () => {
  describe('byId', () => {
    test('returns not-found for missing wine', async () => {
      const wine = aWine()
      const result = await WineDetailReadModel.byId(wine.id)
      expect(result).toBe('not-found')
    })

    test('includes cellar position when in cellar', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await cellarRepo.save(
        aCellarBottle({ wineId: wine.id, row: make<CellarRow>()(1), col: make<CellarCol>()(2) }),
      )

      const result = await WineDetailReadModel.byId(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.cellar?.rowLabel as string).toBe('B')
      expect(result.cellar?.colLabel as number).toBe(3)
    })

    test('reconstructs position from journal when not in cellar', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await journalRepo.save(aJournalEntryIn({ wineId: wine.id }))
      await journalRepo.save(aJournalEntryOut({ wineId: wine.id }))

      const result = await WineDetailReadModel.byId(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.cellar).toBeDefined()
      expect((result.cellar as any)?.dateOut).toBeDefined()
    })

    test('aggregates tasting, gift, recommendation', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(aTastingNote({ wineId: wine.id }))
      await giftRepo.save(aGift({ wineId: wine.id }))
      await recommendationRepo.save(aRecommendation({ wineId: wine.id }))

      const result = await WineDetailReadModel.byId(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.consumption).toBeDefined()
      expect(result.gift).toBeDefined()
      expect(result.recommendation).toBeDefined()
    })
  })
})
