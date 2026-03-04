import { describe, expect, test } from 'bun:test'
import * as tastingRepo from '~/domain/tasting/repository'
import * as wineRepo from '~/domain/wine/repository'
import { mockEvent } from '~/test/setup'
import handler from './index.post'

describe('POST /wines', () => {
  test('creates a wine with all fields', async () => {
    const event = mockEvent({
      body: {
        name: 'Château Margaux',
        color: 'red',
        domain: 'Margaux',
        vintage: 2018,
        region: 'Bordeaux',
        country: 'France',
        purchasePrice: 150,
      },
    })

    const result = await handler(event as any)
    expect(result.status).toBe(201)
    expect(result.data.name as string).toBe('Château Margaux')
    expect(result.data.color as string).toBe('red')
    expect(result.data.id).toBeDefined()

    const saved = await wineRepo.findBy(result.data.id)
    expect(saved).not.toBeNull()
  })

  test('creates wine with rating and tasting note', async () => {
    const event = mockEvent({
      body: {
        name: 'Pétrus',
        color: 'red',
        rating: 5,
        tastingNotes: 'Exceptionnel',
      },
    })

    const result = await handler(event as any)
    expect(result.status).toBe(201)

    const tasting = await tastingRepo.findBy(result.data.id)
    expect(tasting).not.toBeNull()
    expect(tasting?.rating as number).toBe(5)
    expect(tasting?.tastingNotes as string).toBe('Exceptionnel')
  })

  test('rejects missing body', async () => {
    const event = mockEvent({ body: undefined })
    expect(handler(event as any)).rejects.toThrow()
  })
})
