import { describe, expect, test } from 'bun:test'
import * as wineRepo from '~/domain/wine/repository'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './[id].get'

describe('GET /wines/:id', () => {
  test('returns wine detail', async () => {
    const wine = aWine()
    await wineRepo.save(wine)

    const event = mockEvent({ params: { id: wine.id } })
    const result = await handler(event as any)
    expect(result.status).toBe(200)
    expect(result.data.id).toBe(wine.id)
    expect(result.data.name).toBe(wine.name)
  })

  test('throws 404 for missing wine', async () => {
    const event = mockEvent({ params: { id: crypto.randomUUID() } })
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
