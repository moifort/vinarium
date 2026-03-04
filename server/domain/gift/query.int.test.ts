import { describe, expect, test } from 'bun:test'
import { GiftQuery } from '~/domain/gift/query'
import * as repository from '~/domain/gift/repository'
import { aGift } from '~/test/fixtures'

describe('GiftQuery', () => {
  describe('getAll', () => {
    test('returns all gifts', async () => {
      const gift1 = aGift()
      const gift2 = aGift()
      await repository.save(gift1)
      await repository.save(gift2)

      const result = await GiftQuery.getAll()
      expect(result).toHaveLength(2)
    })
  })

  describe('getByWineId', () => {
    test('returns gift when found', async () => {
      const gift = aGift()
      await repository.save(gift)

      const result = await GiftQuery.getByWineId(gift.wineId)
      expect(result).not.toBe('not-found')
      if (result === 'not-found') return
      expect(result.wineId).toBe(gift.wineId)
      expect(result.recipientName).toBe(gift.recipientName)
    })

    test('returns not-found when absent', async () => {
      const gift = aGift()
      const result = await GiftQuery.getByWineId(gift.wineId)
      expect(result).toBe('not-found')
    })
  })
})
