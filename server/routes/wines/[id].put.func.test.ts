import { describe, expect, test } from 'bun:test'
import * as wineRepo from '~/domain/wine/repository'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './[id].put'

describe('PUT /wines/:id', () => {
  test('updates wine fields', async () => {
    const wine = aWine()
    await wineRepo.save(wine)

    const event = mockEvent({
      params: { id: wine.id },
      body: { name: 'Updated Name', vintage: 2020 },
    })
    const result = await handler(event as any)
    expect(result.status).toBe(200)
    expect(result.data.name as string).toBe('Updated Name')
    expect(result.data.vintage as number).toBe(2020)
  })

  test('throws 404 for missing wine', async () => {
    const event = mockEvent({
      params: { id: crypto.randomUUID() },
      body: { name: 'Test' },
    })
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
