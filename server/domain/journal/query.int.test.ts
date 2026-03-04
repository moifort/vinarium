import { describe, expect, test } from 'bun:test'
import { JournalQuery } from '~/domain/journal/query'
import * as journalRepo from '~/domain/journal/repository'
import * as wineRepo from '~/domain/wine/repository'
import { aJournalEntryIn, aJournalEntryOut, aWine } from '~/test/fixtures'

describe('JournalQuery', () => {
  describe('getCellarDates', () => {
    test('returns not-found when no entries', async () => {
      const wine = aWine()
      const result = await JournalQuery.getCellarDates(wine.id)
      expect(result).toBe('not-found')
    })

    test('returns dateIn without dateOut when only entry in', async () => {
      const wine = aWine()
      const entry = aJournalEntryIn({ wineId: wine.id })
      await journalRepo.save(entry)

      const result = await JournalQuery.getCellarDates(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.dateIn).toEqual(entry.dateIn)
      expect(result.dateOut).toBeUndefined()
      expect(result.rowLabel).toBe(entry.rowLabel)
      expect(result.colLabel).toBe(entry.colLabel)
    })

    test('returns both dates when entry in + out', async () => {
      const wine = aWine()
      const entryIn = aJournalEntryIn({ wineId: wine.id })
      const entryOut = aJournalEntryOut({ wineId: wine.id })
      await journalRepo.save(entryIn)
      await journalRepo.save(entryOut)

      const result = await JournalQuery.getCellarDates(wine.id)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.dateIn).toEqual(entryIn.dateIn)
      expect(result.dateOut).toEqual(entryOut.dateOut)
    })
  })

  describe('getAll', () => {
    test('returns entries sorted by date descending', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      const older = aJournalEntryIn({ wineId: wine.id, dateIn: new Date('2024-01-01') })
      const newer = aJournalEntryOut({ wineId: wine.id, dateOut: new Date('2024-06-01') })
      await journalRepo.save(older)
      await journalRepo.save(newer)

      const result = await JournalQuery.getAll()
      expect(result).toHaveLength(2)
      expect(result[0].type).toBe('out')
      expect(result[1].type).toBe('in')
    })

    test('maps to JournalEventView with wine info', async () => {
      const wine = aWine()
      await wineRepo.save(wine)
      const entry = aJournalEntryIn({ wineId: wine.id })
      await journalRepo.save(entry)

      const result = await JournalQuery.getAll()
      expect(result[0].wineName).toBe(wine.name)
      expect(result[0].wineColor).toBe(wine.color)
      expect(result[0].position).toBe(`${entry.rowLabel}${entry.colLabel}`)
    })
  })
})
