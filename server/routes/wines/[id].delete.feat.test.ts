import { expect } from 'bun:test'
import * as wineRepo from '~/domain/wine/repository'
import { and, feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './[id].delete'

feature('Deleting a wine', () => {
  scenario('deleting an existing wine', async () => {
    given('a wine in the catalog')
    const wine = aWine()
    await wineRepo.save(wine)

    when('the wine is deleted')
    const event = mockEvent({ params: { id: wine.id } })
    const result = await handler(event as any)

    then('the deletion is confirmed')
    expect(result.status).toBe(200)

    and('the wine no longer exists')
    const deleted = await wineRepo.findBy(wine.id)
    expect(deleted).toBeNull()
  })

  scenario('wine not found returns 404', async () => {
    given('no wine in the catalog')

    when('a non-existing wine is deleted')
    const event = mockEvent({ params: { id: crypto.randomUUID() } })

    then('a 404 error is returned')
    await expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
