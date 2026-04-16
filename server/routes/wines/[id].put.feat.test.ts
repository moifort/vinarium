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

  scenario('updating the discovery location', async () => {
    given('a wine without a location')
    const wine = aWine()
    await wineRepo.save(wine)

    when('latitude, longitude and placeName are submitted')
    const event = mockEvent({
      params: { id: wine.id },
      body: {
        latitude: 48.5734,
        longitude: 7.7521,
        placeName: 'Strasbourg, France',
      },
    })
    const result = await handler(event as any)

    then('the location is saved')
    expect(result.status).toBe(200)
    expect(result.data.latitude as number).toBe(48.5734)
    expect(result.data.longitude as number).toBe(7.7521)
    expect(result.data.placeName as string).toBe('Strasbourg, France')
  })

  scenario('rejecting a partial coordinate update', async () => {
    given('a wine in the catalog')
    const wine = aWine()
    await wineRepo.save(wine)

    when('only the longitude is submitted')
    const event = mockEvent({
      params: { id: wine.id },
      body: { longitude: 7.7521 },
    })

    then('the request is rejected')
    await expect(handler(event as any)).rejects.toThrow(/together/)
  })

  scenario('rejecting out-of-range latitude', async () => {
    given('a wine in the catalog')
    const wine = aWine()
    await wineRepo.save(wine)

    when('a latitude above 90 is submitted')
    const event = mockEvent({
      params: { id: wine.id },
      body: { latitude: 120, longitude: 5 },
    })

    then('the request is rejected')
    await expect(handler(event as any)).rejects.toThrow()
  })
})
