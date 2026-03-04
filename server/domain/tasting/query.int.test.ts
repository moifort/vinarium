import { describe, expect, test } from 'bun:test'
import { TastingQuery } from '~/domain/tasting/query'
import * as repository from '~/domain/tasting/repository'
import { aTastingNote } from '~/test/fixtures'

describe('TastingQuery', () => {
  describe('getAll', () => {
    test('returns all tasting notes', async () => {
      const note1 = aTastingNote()
      const note2 = aTastingNote()
      await repository.save(note1)
      await repository.save(note2)

      const result = await TastingQuery.getAll()
      expect(result).toHaveLength(2)
    })
  })

  describe('getByWineId', () => {
    test('returns note when found', async () => {
      const note = aTastingNote()
      await repository.save(note)

      const result = await TastingQuery.getByWineId(note.wineId)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.wineId).toBe(note.wineId)
      expect(result.rating).toBe(note.rating)
    })

    test('returns not-found when absent', async () => {
      const note = aTastingNote()
      const result = await TastingQuery.getByWineId(note.wineId)
      expect(result).toBe('not-found')
    })
  })
})
