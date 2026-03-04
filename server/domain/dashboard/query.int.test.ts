import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import * as cellarRepo from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import { DashboardQuery } from '~/domain/dashboard/query'
import * as journalRepo from '~/domain/journal/repository'
import type { Eur, Year } from '~/domain/shared/types'
import * as tastingRepo from '~/domain/tasting/repository'
import type { Rating } from '~/domain/tasting/types'
import * as wineRepo from '~/domain/wine/repository'
import {
  aCellarBottle,
  aJournalEntryIn,
  aJournalEntryOut,
  aTastingNote,
  aWine,
} from '~/test/fixtures'

describe('DashboardQuery', () => {
  describe('get', () => {
    test('empty cellar returns zero counts', async () => {
      const result = await DashboardQuery.get()
      expect(result.bottleCount).toBe(0)
      expect(result.totalValue).toBe(0)
      expect(result.readyToDrink).toHaveLength(0)
      expect(result.favorites).toHaveLength(0)
      expect(result.lastBottle).toBeUndefined()
      expect(result.lastExit).toBeUndefined()
      expect(result.history).toHaveLength(0)
    })

    test('bottleCount reflects number of bottles in cellar', async () => {
      const wine1 = aWine()
      const wine2 = aWine()
      await wineRepo.save(wine1)
      await wineRepo.save(wine2)
      await cellarRepo.save(aCellarBottle({ wineId: wine1.id }))
      await cellarRepo.save(
        aCellarBottle({ wineId: wine2.id, row: make<CellarRow>()(0), col: make<CellarCol>()(1) }),
      )

      const result = await DashboardQuery.get()
      expect(result.bottleCount).toBe(2)
    })

    test('totalValue sums purchasePrice', async () => {
      const wine1 = aWine({ purchasePrice: make<Eur>()(15) })
      const wine2 = aWine({ purchasePrice: make<Eur>()(25) })
      await wineRepo.save(wine1)
      await wineRepo.save(wine2)
      await cellarRepo.save(aCellarBottle({ wineId: wine1.id }))
      await cellarRepo.save(
        aCellarBottle({ wineId: wine2.id, row: make<CellarRow>()(0), col: make<CellarCol>()(1) }),
      )

      const result = await DashboardQuery.get()
      expect(result.totalValue).toBe(40)
    })

    test('readyToDrink includes wines within drink window', async () => {
      const currentYear = new Date().getFullYear()
      const wine = aWine({
        drinkFrom: make<Year>()(currentYear - 1),
        drinkUntil: make<Year>()(currentYear + 2),
      })
      await wineRepo.save(wine)
      await cellarRepo.save(aCellarBottle({ wineId: wine.id }))

      const result = await DashboardQuery.get()
      expect(result.readyToDrink).toHaveLength(1)
      expect(result.readyToDrink[0].id).toBe(wine.id)
      expect(result.readyToDrink[0].urgent).toBe(false)
    })

    test('urgent when drinkUntil <= currentYear + 1', async () => {
      const currentYear = new Date().getFullYear()
      const wine = aWine({
        drinkFrom: make<Year>()(currentYear - 2),
        drinkUntil: make<Year>()(currentYear + 1),
      })
      await wineRepo.save(wine)
      await cellarRepo.save(aCellarBottle({ wineId: wine.id }))

      const result = await DashboardQuery.get()
      expect(result.readyToDrink).toHaveLength(1)
      expect(result.readyToDrink[0].urgent).toBe(true)
    })

    test('wine without drink dates is not readyToDrink', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await cellarRepo.save(aCellarBottle({ wineId: wine.id }))

      const result = await DashboardQuery.get()
      expect(result.readyToDrink).toHaveLength(0)
    })

    test('favorites are tastings with rating 5', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await tastingRepo.save(aTastingNote({ wineId: wine.id, rating: make<Rating>()(5) }))

      const result = await DashboardQuery.get()
      expect(result.favorites).toHaveLength(1)
      expect(result.favorites[0].id).toBe(wine.id)
    })

    test('lastBottle is the most recently placed bottle', async () => {
      const wine1 = aWine()
      const wine2 = aWine()
      await wineRepo.save(wine1)
      await wineRepo.save(wine2)
      await cellarRepo.save(aCellarBottle({ wineId: wine1.id, createdAt: new Date('2024-01-01') }))
      await cellarRepo.save(
        aCellarBottle({
          wineId: wine2.id,
          row: make<CellarRow>()(0),
          col: make<CellarCol>()(1),
          createdAt: new Date('2024-06-01'),
        }),
      )

      const result = await DashboardQuery.get()
      expect(result.lastBottle).toBeDefined()
      expect(result.lastBottle?.wine.id).toBe(wine2.id)
    })

    test('lastExit is the first out event in history', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await journalRepo.save(aJournalEntryIn({ wineId: wine.id }))
      await journalRepo.save(aJournalEntryOut({ wineId: wine.id }))

      const result = await DashboardQuery.get()
      expect(result.lastExit).toBeDefined()
      expect(result.lastExit?.type).toBe('out')
    })

    test('history is limited to 10 events', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      for (let i = 0; i < 12; i++) {
        await journalRepo.save(
          aJournalEntryIn({
            wineId: wine.id,
            dateIn: new Date(`2024-${String(i + 1).padStart(2, '0')}-01`),
          }),
        )
      }

      const result = await DashboardQuery.get()
      expect(result.history).toHaveLength(10)
    })
  })
})
