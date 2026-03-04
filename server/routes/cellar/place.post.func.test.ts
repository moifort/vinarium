import { describe, expect, test } from 'bun:test'
import * as cellarRepo from '~/domain/cellar/repository'
import * as journalRepo from '~/domain/journal/repository'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './place.post'

describe('POST /cellar/place', () => {
  test('places wine in cellar', async () => {
    const wine = aWine()

    const event = mockEvent({
      body: { wineId: wine.id, row: 'A', col: 1 },
    })
    const result = await handler(event as any)
    expect(result.status).toBe(201)
    expect(result.data.wineId).toBe(wine.id)
    expect(result.data.row).toBe(0)
    expect(result.data.col).toBe(0)

    const cellarEntry = await cellarRepo.findBy(wine.id)
    expect(cellarEntry).not.toBeNull()

    const journal = await journalRepo.findByWineId(wine.id)
    expect(journal).toHaveLength(1)
    expect(journal[0].type).toBe('in')
  })
})
