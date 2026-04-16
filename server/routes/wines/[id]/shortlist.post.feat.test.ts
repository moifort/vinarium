import { expect } from 'bun:test'
import * as tastingRepo from '~/domain/tasting/repository'
import * as wineRepo from '~/domain/wine/repository'
import { and, feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './shortlist.post'

feature('Marking a wine as à retenir (shortlist)', () => {
  scenario('marking an existing wine with a free rating', async () => {
    given('an existing wine with no tasting yet')
    const wine = aWine()
    await wineRepo.save(wine)

    when('the wine is added to the shortlist with rating 3')
    const event = mockEvent({
      params: { id: wine.id },
      body: { rating: 3, tastingNotes: 'Meilleur cidre à ce jour' },
    })
    const result = await handler(event as any)

    then('the response contains the shortlisted tasting note')
    expect(result.status).toBe(200)
    expect(result.data.shortlist).toBe(true)
    expect(result.data.rating as number).toBe(3)

    and('the tasting note is persisted with the shortlist flag')
    const saved = await tastingRepo.findBy(wine.id)
    expect(saved?.shortlist).toBe(true)
    expect(saved?.rating as number).toBe(3)
    expect(saved?.tastingNotes as string).toBe('Meilleur cidre à ce jour')
  })

  scenario('marking a wine without providing a rating', async () => {
    given('an existing wine')
    const wine = aWine()
    await wineRepo.save(wine)

    when('the wine is shortlisted with an empty body')
    const event = mockEvent({ params: { id: wine.id }, body: {} })
    const result = await handler(event as any)

    then('the shortlist flag is stored without a rating')
    expect(result.status).toBe(200)
    expect(result.data.shortlist).toBe(true)
    expect(result.data.rating).toBeUndefined()
    expect(result.data.consumedDate).toBeInstanceOf(Date)
  })

  scenario('rejecting an unknown wine', async () => {
    given('a wine id that does not exist')
    const event = mockEvent({
      params: { id: '00000000-0000-0000-0000-000000000000' },
      body: {},
    })

    when('the wine is shortlisted')

    then('the request is rejected with 404')
    await expect(handler(event as any)).rejects.toThrow('Wine not found')
  })
})
