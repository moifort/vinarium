import { describe, expect, test } from 'bun:test'
import * as wineRepo from '~/domain/wine/repository'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './[id].delete'

describe('DELETE /wines/:id', () => {
  test('deletes existing wine', async () => {
    const wine = aWine()
    await wineRepo.save(wine)

    const event = mockEvent({ params: { id: wine.id } })
    const result = await handler(event as any)
    expect(result.status).toBe(200)

    const deleted = await wineRepo.findBy(wine.id)
    expect(deleted).toBeNull()
  })

  test('throws 404 for missing wine', async () => {
    const event = mockEvent({ params: { id: crypto.randomUUID() } })
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
