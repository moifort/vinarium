import { describe, expect, test } from 'bun:test'
import { RecommendationQuery } from '~/domain/recommendation/query'
import * as repository from '~/domain/recommendation/repository'
import { aRecommendation } from '~/test/fixtures'

describe('RecommendationQuery', () => {
  describe('getAll', () => {
    test('returns all recommendations', async () => {
      const rec1 = aRecommendation()
      const rec2 = aRecommendation()
      await repository.save(rec1)
      await repository.save(rec2)

      const result = await RecommendationQuery.getAll()
      expect(result).toHaveLength(2)
    })
  })

  describe('getByWineId', () => {
    test('returns recommendation when found', async () => {
      const rec = aRecommendation()
      await repository.save(rec)

      const result = await RecommendationQuery.getByWineId(rec.wineId)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.wineId).toBe(rec.wineId)
      expect(result.recommenderName).toBe(rec.recommenderName)
    })

    test('returns not-found when absent', async () => {
      const rec = aRecommendation()
      const result = await RecommendationQuery.getByWineId(rec.wineId)
      expect(result).toBe('not-found')
    })
  })
})
