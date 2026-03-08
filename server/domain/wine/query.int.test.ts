import { describe, expect, test } from 'bun:test'
import { WineQuery } from '~/domain/wine/query'
import * as wineRepo from '~/domain/wine/repository'
import { aWine } from '~/test/fixtures'

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
})
