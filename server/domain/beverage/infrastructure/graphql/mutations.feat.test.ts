import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId
const wineId = '00000000-0000-4000-8000-000000000001'

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
  fake.seed('beverages', wineId, {
    id: wineId,
    userId,
    name: 'Margaux',
    beverageType: 'wine',
    producer: 'Château Margaux',
    region: 'Bordeaux',
    notes: 'À boire sur un gibier',
    purchase: { price: 350, date: new Date('2026-01-05') },
    wine: { color: 'red', vintage: 2015, appellation: 'Margaux' },
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  })
})

const execute = (source: string) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const stored = () => fake.snapshot('beverages').get(wineId)

describe('updateBeverage', () => {
  test('erases the fields sent as an explicit null', async () => {
    const result = await execute(`
      mutation {
        updateBeverage(id: "${wineId}", input: { notes: null, purchasePrice: null }) { id }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(stored()).not.toHaveProperty('notes')
    expect(stored()?.purchase).toEqual({ date: new Date('2026-01-05') })
  })

  // The difference the erasure rests on: a field the client leaves out is a field
  // it says nothing about, and must survive the update untouched.
  test('leaves an omitted field alone', async () => {
    const result = await execute(`
      mutation {
        updateBeverage(id: "${wineId}", input: { region: "Médoc" }) { id }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(stored()?.region).toBe('Médoc')
    expect(stored()?.notes).toBe('À boire sur un gibier')
    expect(stored()?.producer).toBe('Château Margaux')
  })

  test('refuses to erase the colour of a wine', async () => {
    const result = await execute(`
      mutation {
        updateBeverage(id: "${wineId}", input: { color: null }) { id }
      }
    `)

    expect(result.errors?.[0]?.extensions?.code).toBe('BAD_USER_INPUT')
    expect((stored()?.wine as { color?: string } | undefined)?.color).toBe('red')
  })
})

describe('addBeverage', () => {
  test('saves the bottle, its tasting note and its recommendation in one batch', async () => {
    const result = await execute(`
      mutation {
        addBeverage(input: {
          name: "Pommard"
          color: RED
          tasting: { rating: 4, favorite: true }
          recommendation: { recommenderName: "Léa" }
        }) { id consumption { rating favorite } recommendation { recommenderName } }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(result.data?.addBeverage).toMatchObject({
      consumption: { rating: 4, favorite: true },
      recommendation: { recommenderName: 'Léa' },
    })
    expect(fake.batches).toHaveLength(1)
    expect(fake.directWrites.filter(({ type }) => type === 'set')).toHaveLength(0)
  })

  test('writes nothing when the bottle is refused', async () => {
    const result = await execute(`
      mutation {
        addBeverage(input: { name: "Sans couleur", tasting: { rating: 4 } }) { id }
      }
    `)

    expect(result.errors?.[0]?.extensions?.code).toBe('BAD_USER_INPUT')
    expect(fake.snapshot('tasting').size).toBe(0)
  })
})

describe('saveBeverageSheet', () => {
  const tastingDoc = () => fake.snapshot('tasting').get(`${userId}_${wineId}`)

  test('writes the beverage and its satellites in one go', async () => {
    fake.seed('tasting', `${userId}_${wineId}`, { userId, beverageId: wineId, favorite: true })

    const result = await execute(`
      mutation {
        saveBeverageSheet(id: "${wineId}", input: {
          beverage: { region: "Médoc", notes: null }
          tasting: { rating: 5, tastingNotes: "Superbe" }
          recommendation: { recommenderName: "Marie" }
        }) { id }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(stored()?.region).toBe('Médoc')
    expect(stored()).not.toHaveProperty('notes')
    expect(tastingDoc()?.rating).toBe(5)
    // The merge still protects what the sheet did not carry.
    expect(tastingDoc()?.favorite).toBe(true)
    expect(fake.snapshot('recommendation').get(`${userId}_${wineId}`)?.recommenderName).toBe(
      'Marie',
    )
  })

  test('leaves untouched parts alone rather than creating them', async () => {
    await execute(`
      mutation {
        saveBeverageSheet(id: "${wineId}", input: { beverage: { region: "Médoc" } }) { id }
      }
    `)

    expect(tastingDoc()).toBeUndefined()
    expect(fake.snapshot('recommendation').get(`${userId}_${wineId}`)).toBeUndefined()
  })

  // The point of the single mutation: a refused beverage must not leave a tasting
  // note behind, the way four separate calls did.
  test('writes nothing at all when one part is refused', async () => {
    const result = await execute(`
      mutation {
        saveBeverageSheet(id: "${wineId}", input: {
          beverage: { color: null }
          tasting: { rating: 5 }
        }) { id }
      }
    `)

    expect(result.errors?.[0]?.extensions?.code).toBe('BAD_USER_INPUT')
    expect(tastingDoc()).toBeUndefined()
    expect((stored()?.wine as { color?: string } | undefined)?.color).toBe('red')
  })

  describe('without the bottle part', () => {
    const housemateWine = '00000000-0000-4000-8000-000000000002'
    const member = (id: string, role: 'owner' | 'member') => ({
      userId: id,
      householdId: 'h1',
      displayName: id,
      role,
      joinedAt: new Date('2026-01-01'),
    })
    const seedHousemateWine = (owner: string) =>
      fake.seed('beverages', housemateWine, {
        id: housemateWine,
        userId: owner,
        name: 'Chez Marie',
        beverageType: 'wine',
        wine: { color: 'white' },
        createdAt: new Date('2026-01-01'),
        updatedAt: new Date('2026-01-01'),
      })
    const heart = () =>
      execute(`
        mutation {
          saveBeverageSheet(id: "${housemateWine}", input: { tasting: { favorite: true } }) {
            id
            consumption { favorite }
          }
        }
      `)

    test('saves the viewer’s own note on a housemate’s wine and returns it', async () => {
      fake.seed('household-members', userId, member(userId, 'owner'))
      fake.seed('household-members', 'marie', member('marie', 'member'))
      seedHousemateWine('marie')

      const result = await heart()

      expect(result.errors).toBeUndefined()
      expect(result.data?.saveBeverageSheet).toEqual({
        id: housemateWine,
        consumption: { favorite: true },
      })
      expect(fake.snapshot('tasting').get(`${userId}_${housemateWine}`)?.favorite).toBe(true)
      // The housemate's bottle itself is left as it was.
      expect(fake.snapshot('beverages').get(housemateWine)?.name).toBe('Chez Marie')
    })

    test('refuses a stranger’s wine and writes nothing', async () => {
      seedHousemateWine('stranger')

      const result = await heart()

      expect(result.errors?.[0]?.extensions?.code).toBe('NOT_FOUND')
      expect(fake.snapshot('tasting').get(`${userId}_${housemateWine}`)).toBeUndefined()
    })
  })

  test('refuses a gift correction on a bottle never given away', async () => {
    const result = await execute(`
      mutation {
        saveBeverageSheet(id: "${wineId}", input: {
          beverage: { region: "Médoc" }
          gift: { recipientName: "Paul" }
        }) { id }
      }
    `)

    expect(result.errors?.[0]?.extensions?.code).toBe('NOT_FOUND')
    expect(stored()?.region).toBe('Bordeaux')
  })
})

// The cuvee is the wine's own name for this bottling, told apart from the estate
// that makes it. Both travel on the same sheet, so both have to survive the round
// trip and be erasable on their own.
describe('the cuvee of a wine', () => {
  const wineOf = () => stored()?.wine as { cuvee?: string; appellation?: string } | undefined

  test('is stored alongside the producer and read back with it', async () => {
    const written = await execute(`
      mutation {
        updateBeverage(id: "${wineId}", input: {
          producer: "Domaine Leflaive", cuvee: "Les Pucelles"
        }) { id }
      }
    `)

    expect(written.errors).toBeUndefined()
    expect(stored()?.producer).toBe('Domaine Leflaive')
    expect(wineOf()?.cuvee).toBe('Les Pucelles')

    const read = await execute(`
      query { beverage(id: "${wineId}") { producer details { ... on WineDetails { cuvee } } } }
    `)

    expect(read.data?.beverage).toMatchObject({
      producer: 'Domaine Leflaive',
      details: { cuvee: 'Les Pucelles' },
    })
  })

  test('is erased on its own, leaving the appellation in place', async () => {
    await execute(`
      mutation { updateBeverage(id: "${wineId}", input: { cuvee: "Les Pucelles" }) { id } }
    `)

    const result = await execute(`
      mutation { updateBeverage(id: "${wineId}", input: { cuvee: null }) { id } }
    `)

    expect(result.errors).toBeUndefined()
    expect(wineOf()).not.toHaveProperty('cuvee')
    expect(wineOf()?.appellation).toBe('Margaux')
  })
})
