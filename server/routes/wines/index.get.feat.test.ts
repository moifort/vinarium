import { expect } from 'bun:test'
import * as cellarRepo from '~/domain/cellar/repository'
import * as wineRepo from '~/domain/wine/repository'
import { feature, given, scenario, then, when } from '~/test/bdd'
import { aCellarBottle, aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './index.get'

feature('Browsing the wine catalog', () => {
  scenario('listing all wines', async () => {
    given('two wines in the catalog')
    await wineRepo.save(aWine())
    await wineRepo.save(aWine())

    when('the full catalog is requested')
    const event = mockEvent()
    const result = await handler(event as any)

    then('both wines are returned')
    expect(result.status).toBe(200)
    expect(result.data).toHaveLength(2)
  })

  scenario('filtering by color', async () => {
    given('a red wine and a white wine in the catalog')
    await wineRepo.save(aWine({ color: 'red' }))
    await wineRepo.save(aWine({ color: 'white' }))

    when('filtering by white color')
    const event = mockEvent({ query: { color: 'white' } })
    const result = await handler(event as any)

    then('only the white wine is returned')
    expect(result.data).toHaveLength(1)
    expect((result.data as any[])[0].color).toBe('white')
  })

  scenario('filtering by cellar status', async () => {
    given('one wine in the cellar and one not')
    const inCellar = aWine()
    const consumed = aWine()
    await wineRepo.save(inCellar)
    await wineRepo.save(consumed)
    await cellarRepo.save(aCellarBottle({ wineId: inCellar.id }))

    when('filtering by in-cellar status')
    const event = mockEvent({ query: { status: 'in-cellar' } })
    const result = await handler(event as any)

    then('only the cellared wine is returned')
    expect(result.data).toHaveLength(1)
    expect((result.data as any[])[0].id).toBe(inCellar.id)
  })
})
