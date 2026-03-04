import { describe, expect, test } from 'bun:test'
import * as cellarRepo from '~/domain/cellar/repository'
import * as wineRepo from '~/domain/wine/repository'
import { aCellarBottle, aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './index.get'

describe('GET /wines', () => {
  test('returns all wines', async () => {
    await wineRepo.save(aWine())
    await wineRepo.save(aWine())

    const event = mockEvent()
    const result = await handler(event as any)
    expect(result.status).toBe(200)
    expect(result.data).toHaveLength(2)
  })

  test('filters by color', async () => {
    await wineRepo.save(aWine({ color: 'red' }))
    await wineRepo.save(aWine({ color: 'white' }))

    const event = mockEvent({ query: { color: 'white' } })
    const result = await handler(event as any)
    expect(result.data).toHaveLength(1)
    expect((result.data as any[])[0].color).toBe('white')
  })

  test('filters by status', async () => {
    const inCellar = aWine()
    const consumed = aWine()
    await wineRepo.save(inCellar)
    await wineRepo.save(consumed)
    await cellarRepo.save(aCellarBottle({ wineId: inCellar.id }))

    const event = mockEvent({ query: { status: 'in-cellar' } })
    const result = await handler(event as any)
    expect(result.data).toHaveLength(1)
    expect((result.data as any[])[0].id).toBe(inCellar.id)
  })
})
