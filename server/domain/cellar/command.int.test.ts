import { describe, expect, test } from 'bun:test'
import { make } from 'ts-brand'
import { CellarCommand } from '~/domain/cellar/command'
import * as cellarRepo from '~/domain/cellar/repository'
import type { CellarCol, CellarRow } from '~/domain/cellar/types'
import * as journalRepo from '~/domain/journal/repository'
import { aWine } from '~/test/fixtures'

describe('CellarCommand', () => {
  describe('placeWine', () => {
    test('creates cellar entry and journal in', async () => {
      const wine = aWine()
      const row = make<CellarRow>()(1)
      const col = make<CellarCol>()(2)

      const entry = await CellarCommand.placeWine(wine.id, row, col)

      expect(entry.wineId).toBe(wine.id)
      expect(entry.row as number).toBe(1)
      expect(entry.col as number).toBe(2)

      const cellarEntry = await cellarRepo.findBy(wine.id)
      expect(cellarEntry).not.toBeNull()

      const journal = await journalRepo.findByWineId(wine.id)
      expect(journal).toHaveLength(1)
      expect(journal[0].type).toBe('in')
    })

    test('throws on duplicate placement', async () => {
      const wine = aWine()
      const row = make<CellarRow>()(0)
      const col = make<CellarCol>()(0)

      await CellarCommand.placeWine(wine.id, row, col)
      expect(CellarCommand.placeWine(wine.id, row, col)).rejects.toThrow()
    })
  })

  describe('removeWine', () => {
    test('returns not-in-cellar when absent', async () => {
      const wine = aWine()
      const result = await CellarCommand.removeWine(wine.id)
      expect(result).toBe('not-in-cellar')
    })

    test('creates journal out and removes cellar entry', async () => {
      const wine = aWine()
      const row = make<CellarRow>()(0)
      const col = make<CellarCol>()(0)

      await CellarCommand.placeWine(wine.id, row, col)
      const result = await CellarCommand.removeWine(wine.id)
      expect(result).toBeUndefined()

      const cellarEntry = await cellarRepo.findBy(wine.id)
      expect(cellarEntry).toBeNull()

      const journal = await journalRepo.findByWineId(wine.id)
      expect(journal).toHaveLength(2)
      expect(journal[1].type).toBe('out')
    })
  })
})
