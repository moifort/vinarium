import { describe, expect, test } from 'bun:test'
import { mockEvent } from '~/test/setup'
import handler from './suggest.post'

describe('POST /cellar/suggest', () => {
  test('empty cellar suggests A1', async () => {
    const event = mockEvent()
    const result = await handler(event as any)
    expect(result.status).toBe(200)
    expect(result.data.rowLabel as string).toBe('A')
    expect(result.data.colLabel as number).toBe(1)
  })
})
