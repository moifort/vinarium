import { expect } from 'bun:test'
import { CellarCommand } from '~/domain/cellar/command'
import { CellarCol, CellarRow } from '~/domain/cellar/primitives'
import * as cellarRepo from '~/domain/cellar/repository'
import * as journalRepo from '~/domain/journal/repository'
import { and, feature, given, scenario, then, when } from '~/test/bdd'
import { aWine } from '~/test/fixtures'
import { mockEvent } from '~/test/setup'
import handler from './move.post'

feature('Moving a bottle in the cellar', () => {
  scenario('moving to an empty position', async () => {
    given('a bottle placed at A1')
    const wine = aWine()
    await CellarCommand.placeWine(wine.id, CellarRow(0), CellarCol(0))

    when('the bottle is moved to C3')
    const event = mockEvent({ body: { wineId: wine.id, row: 'C', col: 3 } })
    const result = await handler(event as any)

    then('the move is confirmed')
    expect(result.status).toBe(200)
    expect((result.data as any).row as number).toBe(2)
    expect((result.data as any).col as number).toBe(2)

    and('the cellar reflects the new position')
    const entry = await cellarRepo.findBy(wine.id)
    expect(entry?.row as number).toBe(2)
    expect(entry?.col as number).toBe(2)

    and('the journal records out + in')
    const journal = await journalRepo.findByWineId(wine.id)
    expect(journal.map((j) => j.type)).toEqual(['in', 'out', 'in'])
  })

  scenario('swapping with an occupied position', async () => {
    given('two bottles in the cellar')
    const wineA = aWine()
    const wineB = aWine()
    await CellarCommand.placeWine(wineA.id, CellarRow(0), CellarCol(0))
    await CellarCommand.placeWine(wineB.id, CellarRow(3), CellarCol(4))

    when('bottle A is moved onto bottle B position')
    const event = mockEvent({ body: { wineId: wineA.id, row: 'D', col: 5 } })
    await handler(event as any)

    then('both bottles are swapped')
    const entryA = await cellarRepo.findBy(wineA.id)
    const entryB = await cellarRepo.findBy(wineB.id)
    expect(entryA?.row as number).toBe(3)
    expect(entryA?.col as number).toBe(4)
    expect(entryB?.row as number).toBe(0)
    expect(entryB?.col as number).toBe(0)
  })

  scenario('moving a bottle that is not in the cellar', async () => {
    given('a wine that is not placed')
    const wine = aWine()

    when('a move is requested')
    const event = mockEvent({ body: { wineId: wine.id, row: 'A', col: 1 } })

    then('the route responds 404')
    expect(handler(event as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
