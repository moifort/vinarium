import { expect } from 'bun:test'
import { feature, given, scenario, then, when } from '~/test/bdd'
import { mockEvent } from '~/test/setup'
import handler from './suggest.post'

feature('Suggesting a cellar position', () => {
  scenario('empty cellar suggests A1', async () => {
    given('an empty cellar')
    const event = mockEvent()

    when('a position suggestion is requested')
    const result = await handler(event as any)

    then('the suggested position is A1')
    expect(result.status).toBe(200)
    expect(result.data.rowLabel as string).toBe('A')
    expect(result.data.colLabel as number).toBe(1)
  })
})
