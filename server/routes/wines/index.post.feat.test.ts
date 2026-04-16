import { expect } from 'bun:test'
import * as tastingRepo from '~/domain/tasting/repository'
import * as wineRepo from '~/domain/wine/repository'
import { and, feature, given, scenario, then, when } from '~/test/bdd'
import { mockEvent } from '~/test/setup'
import handler from './index.post'

feature('Adding a wine to the catalog', () => {
  scenario('adding a wine with full details', async () => {
    given('complete wine information')
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

    when('the wine is added')
    const result = await handler(event as any)

    then('the wine is created')
    expect(result.status).toBe(201)
    expect(result.data.name as string).toBe('Château Margaux')
    expect(result.data.color as string).toBe('red')
    expect(result.data.id).toBeDefined()

    and('the wine is persisted')
    const saved = await wineRepo.findBy(result.data.id)
    expect(saved).not.toBeNull()
  })

  scenario('adding a wine with a tasting note', async () => {
    given('wine information with a rating and tasting notes')
    const event = mockEvent({
      body: {
        name: 'Pétrus',
        color: 'red',
        rating: 5,
        tastingNotes: 'Exceptionnel',
      },
    })

    when('the wine is added')
    const result = await handler(event as any)

    then('the wine is created with the tasting note')
    expect(result.status).toBe(201)

    and('the tasting note is recorded')
    const tasting = await tastingRepo.findBy(result.data.id)
    expect(tasting).not.toBeNull()
    expect(tasting?.rating as number).toBe(5)
    expect(tasting?.tastingNotes as string).toBe('Exceptionnel')
  })

  scenario('rejecting missing body', async () => {
    given('no wine information')
    const event = mockEvent({ body: undefined })

    when('a wine is added without a body')

    then('the request is rejected')
    await expect(handler(event as any)).rejects.toThrow()
  })

  scenario('adding a wine with a discovery location', async () => {
    given('wine information including coordinates and place name')
    const event = mockEvent({
      body: {
        name: 'Château Latour',
        color: 'red',
        latitude: 45.115,
        longitude: -0.748,
        placeName: 'Pauillac, France',
      },
    })

    when('the wine is added')
    const result = await handler(event as any)

    then('the location is persisted with the wine')
    expect(result.status).toBe(201)
    const saved = await wineRepo.findBy(result.data.id)
    expect(saved?.latitude as number).toBe(45.115)
    expect(saved?.longitude as number).toBe(-0.748)
    expect(saved?.placeName as string).toBe('Pauillac, France')
  })

  scenario('rejecting a partial coordinate pair', async () => {
    given('wine information with latitude only')
    const event = mockEvent({
      body: {
        name: 'Château Lafite',
        color: 'red',
        latitude: 45.18,
      },
    })

    when('the wine is submitted')

    then('the request is rejected because longitude is missing')
    await expect(handler(event as any)).rejects.toThrow(/together/)
  })
})
