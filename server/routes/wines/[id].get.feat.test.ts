import { expect } from 'bun:test'
import * as wineRepo from '~/domain/wine/repository'
import { feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './[id].get'

feature('Viewing wine details', () => {
  scenario('existing wine returns its details', async () => {
    given('a wine in the catalog')
    const wine = aWine()
    await wineRepo.save(wine)

    when('the wine details are requested')
    const event = mockEvent({ params: { id: wine.id } })
    const result = await handler(event as any)

    then('the wine details are returned')
    expect(result.status).toBe(200)
    expect(result.data.id).toBe(wine.id)
    expect(result.data.name).toBe(wine.name)
  })

  scenario('wine not found returns 404', async () => {
    given('no wine in the catalog')

    when('a non-existing wine is requested')
    const event = mockEvent({ params: { id: crypto.randomUUID() } })

    then('a 404 error is returned')
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
