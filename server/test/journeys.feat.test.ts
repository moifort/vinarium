import { expect } from 'bun:test'
import * as cellarRepo from '~/domain/cellar/repository'
import * as giftRepo from '~/domain/gift/repository'
import * as journalRepo from '~/domain/journal/repository'
import * as tastingRepo from '~/domain/tasting/repository'
import { and, feature, given, scenario, then, when } from '~/test/bdd'
import { mockEvent } from '~/test/setup'
import placeHandler from '../routes/cellar/place.post'
import removeHandler from '../routes/cellar/remove.post'
import deleteWineHandler from '../routes/wines/[id].delete'
import getWineHandler from '../routes/wines/[id].get'
import putWineHandler from '../routes/wines/[id].put'
import listWinesHandler from '../routes/wines/index.get'
import createWineHandler from '../routes/wines/index.post'

feature('Business journeys', () => {
  scenario('full bottle lifecycle: add, place, remove with tasting', async () => {
    given('a wine added to the catalog')
    const createEvent = mockEvent({
      body: { name: 'Château Margaux', color: 'red', purchasePrice: 45 },
    })
    const created = await createWineHandler(createEvent as any)
    const wineId = created.data.id

    and('the bottle placed in the cellar at A1')
    const placeEvent = mockEvent({
      body: { wineId, row: 'A', col: 1 },
    })
    await placeHandler(placeEvent as any)

    when('the bottle is removed with a 4-star tasting note')
    const removeEvent = mockEvent({
      body: { wineId, rating: 4, tastingNotes: 'Excellent millésime' },
    })
    await removeHandler(removeEvent as any)

    then('the wine is no longer in the cellar')
    const cellarEntry = await cellarRepo.findBy(wineId)
    expect(cellarEntry).toBeNull()

    and('the tasting note is recorded')
    const tasting = await tastingRepo.findBy(wineId)
    expect(tasting).not.toBeNull()
    expect(tasting?.rating as number).toBe(4)

    and('the journal tracks both placement and removal')
    const journal = await journalRepo.findByWineId(wineId)
    expect(journal).toHaveLength(2)
    expect(journal[0].type).toBe('in')
    expect(journal[1].type).toBe('out')
  })

  scenario('gifting a bottle from the cellar', async () => {
    given('a wine in the catalog placed in the cellar')
    const createEvent = mockEvent({
      body: { name: 'Pétrus', color: 'red' },
    })
    const created = await createWineHandler(createEvent as any)
    const wineId = created.data.id

    const placeEvent = mockEvent({
      body: { wineId, row: 'B', col: 2 },
    })
    await placeHandler(placeEvent as any)

    when('the bottle is removed as a gift for a friend')
    const removeEvent = mockEvent({
      body: {
        wineId,
        gift: { recipientName: 'Marie', giftedDate: '2024-12-25' },
      },
    })
    await removeHandler(removeEvent as any)

    then('the gift is recorded with the recipient name')
    const gift = await giftRepo.findBy(wineId)
    expect(gift).not.toBeNull()
    expect(gift?.recipientName as string).toBe('Marie')

    and('the wine is no longer in the cellar')
    const cellarEntry = await cellarRepo.findBy(wineId)
    expect(cellarEntry).toBeNull()

    and('the journal records the gifting')
    const journal = await journalRepo.findByWineId(wineId)
    const outEntry = journal.find((e) => e.type === 'out')
    expect(outEntry).toBeDefined()
  })

  scenario('managing a wine through its catalog lifecycle', async () => {
    given('a wine added to the catalog')
    const createEvent = mockEvent({
      body: { name: 'Chablis Premier Cru', color: 'white', vintage: 2019 },
    })
    const created = await createWineHandler(createEvent as any)
    const wineId = created.data.id

    when('the wine details are updated')
    const updateEvent = mockEvent({
      params: { id: wineId },
      body: { name: 'Chablis Grand Cru', vintage: 2020 },
    })
    await putWineHandler(updateEvent as any)

    then('the updated details are visible')
    const getEvent = mockEvent({ params: { id: wineId } })
    const detail = await getWineHandler(getEvent as any)
    expect(detail.data.name as string).toBe('Chablis Grand Cru')
    expect(detail.data.vintage as number).toBe(2020)

    when('the wine is deleted from the catalog')
    const deleteEvent = mockEvent({ params: { id: wineId } })
    await deleteWineHandler(deleteEvent as any)

    then('the wine no longer appears in the catalog')
    const listEvent = mockEvent()
    const list = await listWinesHandler(listEvent as any)
    const found = (list.data as any[]).find((w: any) => w.id === wineId)
    expect(found).toBeUndefined()

    and('the wine details return 404')
    await expect(getWineHandler(getEvent as any)).rejects.toMatchObject({ statusCode: 404 })
  })
})
