import { expect } from 'bun:test'
import * as wineRepo from '~/domain/wine/repository'
import { feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './[id].put'

feature('Updating a wine', () => {
  scenario('updating wine fields', async () => {
    given('a wine in the catalog')
    const wine = aWine()
    await wineRepo.save(wine)

    when('the wine name and vintage are updated')
    const event = mockEvent({
      params: { id: wine.id },
      body: { name: 'Updated Name', vintage: 2020 },
    })
    const result = await handler(event as any)

    then('the updated details are returned')
    expect(result.status).toBe(200)
    expect(result.data.name as string).toBe('Updated Name')
    expect(result.data.vintage as number).toBe(2020)
  })

  scenario('wine not found returns 404', async () => {
    given('no wine in the catalog')

    when('a non-existing wine is updated')
    const event = mockEvent({
      params: { id: crypto.randomUUID() },
      body: { name: 'Test' },
    })

    then('a 404 error is returned')
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
