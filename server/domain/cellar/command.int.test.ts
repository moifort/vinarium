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

  describe('moveBottle', () => {
    test('returns not-in-cellar when absent', async () => {
      const wine = aWine()
      const result = await CellarCommand.moveBottle(
        wine.id,
        make<CellarRow>()(0),
        make<CellarCol>()(0),
      )
      expect(result).toBe('not-in-cellar')
    })

    test('is a no-op when target equals current position', async () => {
      const wine = aWine()
      const row = make<CellarRow>()(1)
      const col = make<CellarCol>()(2)

      await CellarCommand.placeWine(wine.id, row, col)
      await CellarCommand.moveBottle(wine.id, row, col)

      const journal = await journalRepo.findByWineId(wine.id)
      expect(journal).toHaveLength(1)
    })

    test('moves to an empty position and journals out + in', async () => {
      const wine = aWine()
      await CellarCommand.placeWine(wine.id, make<CellarRow>()(0), make<CellarCol>()(0))

      const moved = await CellarCommand.moveBottle(
        wine.id,
        make<CellarRow>()(2),
        make<CellarCol>()(3),
      )

      expect(moved).not.toBe('not-in-cellar')
      const entry = await cellarRepo.findBy(wine.id)
      expect(entry?.row as number).toBe(2)
      expect(entry?.col as number).toBe(3)

      const journal = await journalRepo.findByWineId(wine.id)
      expect(journal.map((j) => j.type)).toEqual(['in', 'out', 'in'])
    })

    test('swaps with an occupant and journals both bottles', async () => {
      const wineA = aWine()
      const wineB = aWine()
      await CellarCommand.placeWine(wineA.id, make<CellarRow>()(0), make<CellarCol>()(0))
      await CellarCommand.placeWine(wineB.id, make<CellarRow>()(3), make<CellarCol>()(4))

      await CellarCommand.moveBottle(wineA.id, make<CellarRow>()(3), make<CellarCol>()(4))

      const entryA = await cellarRepo.findBy(wineA.id)
      const entryB = await cellarRepo.findBy(wineB.id)
      expect(entryA?.row as number).toBe(3)
      expect(entryA?.col as number).toBe(4)
      expect(entryB?.row as number).toBe(0)
      expect(entryB?.col as number).toBe(0)

      const journalA = await journalRepo.findByWineId(wineA.id)
      const journalB = await journalRepo.findByWineId(wineB.id)
      expect(journalA.map((j) => j.type)).toEqual(['in', 'out', 'in'])
      expect(journalB.map((j) => j.type)).toEqual(['in', 'out', 'in'])
    })
  })
})
