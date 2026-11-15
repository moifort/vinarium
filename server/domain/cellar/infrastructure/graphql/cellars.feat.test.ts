import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

let compedUserIds: string[] = []
mock.module('~/system/config/index', () => ({
  config: () => ({ premiumUserIds: compedUserIds }),
}))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId
const W1 = '11111111-1111-4111-8111-111111111111'
const W2 = '22222222-2222-4222-8222-222222222222'

const wine = (id: string) => ({
  id,
  userId,
  name: `Wine ${id}`,
  beverageType: 'beer',
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
})

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
  compedUserIds = [userId]
  fake.seed('cellar-configs', 'usr_user-1', { rows: 2, cols: 2, zones: 1 })
  fake.seed('beverages', W1, wine(W1))
  fake.seed('beverages', W2, wine(W2))
})

const execute = async (source: string) => {
  const result = await graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })
  return result as {
    data?: Record<string, unknown> | null
    errors?: readonly { message: string; extensions: { code?: string } }[]
  }
}

const createGarage = async () => {
  const result = await execute(
    'mutation { createCellar(name: "Garage", rows: 3, cols: 4) { id name isPrimary capacity } }',
  )
  const cellar = result.data?.createCellar as { id: string } | undefined
  if (!cellar) throw new Error(`createCellar failed: ${JSON.stringify(result.errors)}`)
  return cellar.id
}

const place = (beverageId: string, row: number, col: number, cellarId?: string) =>
  execute(`mutation {
    placeBottle(beverageId: "${beverageId}", row: ${row}, col: ${col}${
      cellarId ? `, cellarId: "${cellarId}"` : ''
    }) { cellarId rowLabel colLabel }
  }`)

describe('several cellars', () => {
  test('a free account cannot add a cellar', async () => {
    compedUserIds = []
    const result = await execute(
      'mutation { createCellar(name: "Garage", rows: 3, cols: 4) { id } }',
    )
    expect(result.errors?.[0]?.extensions.code).toBe('PREMIUM_REQUIRED')
  })

  test('a Premium account adds a cellar, listed after the primary one', async () => {
    const garage = await createGarage()

    const result = await execute('{ cellars { id name isPrimary capacity placedCount } }')

    expect(result.data?.cellars).toEqual([
      { id: 'usr_user-1', name: null, isPrimary: true, capacity: 4, placedCount: 0 },
      { id: garage, name: 'Garage', isPrimary: false, capacity: 12, placedCount: 0 },
    ])
  })

  test('the same slot is free in each cellar, and each grid lists only its own bottles', async () => {
    const garage = await createGarage()

    expect((await place(W1, 0, 0)).errors).toBeUndefined()
    expect((await place(W2, 0, 0, garage)).data?.placeBottle).toEqual({
      cellarId: garage,
      rowLabel: 'A',
      colLabel: 1,
    })

    const grids = await execute(`{
      primary: cellarBottles(limit: 100) { items { beverageId cellarId } }
      garage: cellarBottles(cellarId: "${garage}", limit: 100) { items { beverageId } }
      dashboard { capacity bottleCount }
    }`)
    expect(grids.data).toEqual({
      primary: { items: [{ beverageId: W1, cellarId: 'usr_user-1' }] },
      garage: { items: [{ beverageId: W2 }] },
      dashboard: { capacity: 16, bottleCount: 2 },
    })
  })

  test('a bottle moves to another cellar, swapping with the one standing there', async () => {
    const garage = await createGarage()
    await place(W1, 1, 1)
    await place(W2, 2, 3, garage)

    const moved = await execute(`mutation {
      moveBottle(beverageId: "${W1}", row: 2, col: 3, cellarId: "${garage}") { cellarId row col }
    }`)

    expect(moved.data?.moveBottle).toEqual({ cellarId: garage, row: 2, col: 3 })
    expect(fake.snapshot('cellar').get(`user-1_${W2}`)).toMatchObject({
      cellarId: 'usr_user-1',
      row: 1,
      col: 1,
    })
  })

  test('a bottle naming a cellar the household does not hold stands in the primary one', async () => {
    fake.seed('cellar', `user-1_${W1}`, {
      userId,
      beverageId: W1,
      cellarId: 'hh_a-household-left-behind',
      row: 0,
      col: 1,
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-01-01'),
    })

    const result = await execute(`{
      cellarBottles(limit: 100) { items { beverageId cellarId } }
      suggestCellarPosition { cellarId row col }
    }`)

    expect(result.data).toEqual({
      cellarBottles: { items: [{ beverageId: W1, cellarId: 'usr_user-1' }] },
      suggestCellarPosition: { cellarId: 'usr_user-1', row: 0, col: 0 },
    })
  })

  test('a cellar is deleted once empty, the primary one never', async () => {
    const garage = await createGarage()
    await place(W1, 0, 0, garage)

    const busy = await execute(`mutation { deleteCellar(id: "${garage}") }`)
    expect(busy.errors?.[0]?.extensions.code).toBe('CELLAR_NOT_EMPTY')

    await execute(`mutation { removeBottle(beverageId: "${W1}") }`)
    expect((await execute(`mutation { deleteCellar(id: "${garage}") }`)).data).toEqual({
      deleteCellar: true,
    })

    const primary = await execute('mutation { deleteCellar(id: "usr_user-1") }')
    expect(primary.errors?.[0]?.extensions.code).toBe('PRIMARY_CELLAR')
  })

  test('the primary cellar can be named, keeping its size', async () => {
    const result = await execute(
      'mutation { renameCellar(id: "usr_user-1", name: "Cuisine") { name rows cols } }',
    )
    expect(result.data?.renameCellar).toEqual({ name: 'Cuisine', rows: 2, cols: 2 })
  })

  test('a cellar resizes on its own, refusing to strand its bottles', async () => {
    const garage = await createGarage()
    await place(W1, 2, 3, garage)

    const blocked = await execute(`mutation {
      reconfigureCellar(cellarId: "${garage}", rows: 2, cols: 2, zones: 1) {
        __typename ... on CellarReconfigureBlocked { outOfBoundsCount }
      }
    }`)
    expect(blocked.data?.reconfigureCellar).toEqual({
      __typename: 'CellarReconfigureBlocked',
      outOfBoundsCount: 1,
    })

    // The primary cellar is empty: the garage's bottle does not hold it back.
    const primary = await execute(`mutation {
      reconfigureCellar(rows: 1, cols: 1, zones: 1) { __typename ... on CellarInfo { capacity } }
    }`)
    expect(primary.data?.reconfigureCellar).toEqual({ __typename: 'CellarInfo', capacity: 1 })
  })
})

describe('cellars read budget', () => {
  // Seeded rather than created: the request memo spans a whole test, so a
  // mutation first would leave the reads below already paid.
  const GARAGE = 'garage-1'
  const seedTwoCellars = () => {
    fake.seed('cellar-configs', GARAGE, {
      scopeKey: 'usr_user-1',
      name: 'Garage',
      rows: 3,
      cols: 4,
      zones: 1,
      createdAt: new Date('2026-02-01'),
    })
    const bottle = (beverageId: string, cellarId: string) =>
      fake.seed('cellar', `${userId}_${beverageId}`, {
        userId,
        beverageId,
        cellarId,
        row: 0,
        col: 0,
        createdAt: new Date('2026-02-02'),
        updatedAt: new Date('2026-02-02'),
      })
    bottle(W1, 'usr_user-1')
    bottle(W2, GARAGE)
  }

  test('naming the cellars and drawing their grids never scans the bottles', async () => {
    seedTwoCellars()

    const before = { docReads: fake.docReads, queryReads: fake.queryReads }
    const result = await execute('{ cellars { id name isPrimary rows cols capacity } }')

    expect(result.errors).toBeUndefined()
    expect(result.data?.cellars).toEqual([
      { id: 'usr_user-1', name: null, isPrimary: true, rows: 2, cols: 2, capacity: 4 },
      { id: GARAGE, name: 'Garage', isPrimary: false, rows: 3, cols: 4, capacity: 12 },
    ])
    // The membership probe and the primary cellar, then the household's other
    // cellars: what a wine's sheet asks, whatever the size of the cellar.
    expect(fake.docReads - before.docReads).toBe(2)
    expect(fake.queryReads - before.queryReads).toBe(1)
  })

  test('the count, when asked, scans the bottles once for every cellar', async () => {
    seedTwoCellars()

    const before = { queryReads: fake.queryReads }
    const result = await execute('{ cellars { id placedCount } }')

    expect(result.data?.cellars).toEqual([
      { id: 'usr_user-1', placedCount: 1 },
      { id: GARAGE, placedCount: 1 },
    ])
    // The household's other cellars, then one scan of its bottles.
    expect(fake.queryReads - before.queryReads).toBe(2)
  })
})
