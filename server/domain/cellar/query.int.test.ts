import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import { CellarQuery } from '~/domain/cellar/query'
import * as cellarRepo from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import * as wineRepo from '~/domain/wine/repository'
import { aCellarBottle, aWine } from '~/test/fixtures'

describe('CellarQuery', () => {
  describe('suggestPosition', () => {
    test('empty cellar suggests A1 (row 0, col 0)', async () => {
      const result = await CellarQuery.suggestPosition()
      expect(result).not.toBe('cellar-full')
      if (result === 'cellar-full') return
      expect(result.row).toBe(0)
      expect(result.col).toBe(0)
      expect(result.rowLabel).toBe('A')
      expect(result.colLabel).toBe(1)
    })

    test('skips occupied slots (row-major order)', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await cellarRepo.save(
        aCellarBottle({ wineId: wine.id, row: make<CellarRow>()(0), col: make<CellarCol>()(0) }),
      )

      const result = await CellarQuery.suggestPosition()
      expect(result).not.toBe('cellar-full')
      if (result === 'cellar-full') return
      expect(result.row).toBe(0)
      expect(result.col).toBe(1)
    })

    test('returns cellar-full when 48 slots occupied', async () => {
      for (let row = 0; row < 6; row++) {
        for (let col = 0; col < 8; col++) {
          const wine = aWine()
          await wineRepo.save(wine)
          await cellarRepo.save(
            aCellarBottle({
              wineId: wine.id,
              row: make<CellarRow>()(row),
              col: make<CellarCol>()(col),
            }),
          )
        }
      }
      const result = await CellarQuery.suggestPosition()
      expect(result).toBe('cellar-full')
    })
  })

  describe('getAllBottles', () => {
    test('returns bottles with wine data', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await cellarRepo.save(aCellarBottle({ wineId: wine.id }))

      const result = await CellarQuery.getAllBottles()
      expect(result).toHaveLength(1)
      expect(result[0].wine.id).toBe(wine.id)
      expect(result[0].rowLabel).toBeDefined()
      expect(result[0].colLabel).toBeDefined()
    })

    test('throws when wine is missing', async () => {
      await cellarRepo.save(aCellarBottle())
      expect(CellarQuery.getAllBottles()).rejects.toThrow()
    })
  })

  describe('getBottleByWineId', () => {
    test('returns bottle view when found', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      await cellarRepo.save(
        aCellarBottle({ wineId: wine.id, row: make<CellarRow>()(2), col: make<CellarCol>()(3) }),
      )

      const result = await CellarQuery.getBottleByWineId(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.rowLabel).toBe('C')
      expect(result.colLabel).toBe(4)
    })

    test('returns not-found when absent', async () => {
      const wine = aWine()
      const result = await CellarQuery.getBottleByWineId(wine.id)
      expect(result).toBe('not-found')
    })
  })
})
