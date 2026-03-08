import { expect } from 'bun:test'
import * as cellarRepo from '~/domain/cellar/repository'
import * as journalRepo from '~/domain/journal/repository'
import { and, feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './place.post'

feature('Placing a bottle in the cellar', () => {
  scenario('placing at a specific position', async () => {
    given('a wine in the catalog')
    const wine = aWine()

    when('the bottle is placed at position A1')
    const event = mockEvent({
      body: { wineId: wine.id, row: 'A', col: 1 },
    })
    const result = await handler(event as any)

    then('the placement is confirmed')
    expect(result.status).toBe(201)
    expect(result.data.wineId).toBe(wine.id)
    expect(result.data.row as number).toBe(0)
    expect(result.data.col as number).toBe(0)

    and('the bottle is in the cellar')
    const cellarEntry = await cellarRepo.findBy(wine.id)
    expect(cellarEntry).not.toBeNull()

    and('the journal records the placement')
    const journal = await journalRepo.findByWineId(wine.id)
    expect(journal).toHaveLength(1)
    expect(journal[0].type).toBe('in')
  })
})
