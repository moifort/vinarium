import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { BeverageId } from '~/domain/beverage/types'
import type { CellarBottle, CellarCol, CellarRow } from '~/domain/cellar/types'
import type { HouseholdId, HouseholdMember } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { CellarQuery } = await import('~/domain/cellar/query')

const household = 'h1' as HouseholdId
const user = (id: string) => id as UserId
const wine = (id: string) => id as BeverageId

const member = (id: string, role: 'owner' | 'member'): HouseholdMember => ({
  userId: user(id),
  householdId: household,
  displayName: id as PersonName,
  role,
  joinedAt: new Date('2026-01-01'),
})

const bottle = (owner: string, beverageId: string, row: number, col: number): CellarBottle => ({
  userId: user(owner),
  beverageId: wine(beverageId),
  row: row as CellarRow,
  col: col as CellarCol,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
})

const beverage = (owner: string, id: string) => ({
  id: wine(id),
  userId: user(owner),
  name: `Wine ${id}`,
  beverageType: 'wine',
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
})

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

// A two-person household: 'owner' (the viewer) and 'marie', each with one bottle.
const seedHousehold = () => {
  fake.seed('household-members', 'owner', member('owner', 'owner'))
  fake.seed('household-members', 'marie', member('marie', 'member'))
  fake.seed('cellar', 'owner_w1', bottle('owner', 'w1', 0, 0))
  fake.seed('cellar', 'marie_w2', bottle('marie', 'w2', 0, 1))
  fake.seed('beverages', 'w1', beverage('owner', 'w1'))
  fake.seed('beverages', 'w2', beverage('marie', 'w2'))
}

describe('CellarQuery.bottlesPage (household)', () => {
  test('merges every member’s bottles, tagged with their owner', async () => {
    seedHousehold()

    const { items } = await CellarQuery.bottlesPage(user('owner'), { limit: 15 })

    const byBeverage = new Map(items.map((item) => [item.beverageId, item]))
    const mine = byBeverage.get(wine('w1'))
    expect(mine?.owner).toMatchObject({ userId: user('owner'), isMine: true })
    expect(mine?.owner.displayName).toBeUndefined()

    const hers = byBeverage.get(wine('w2'))
    expect(hers?.owner).toMatchObject({ userId: user('marie'), isMine: false })
    expect(hers?.owner.displayName as string).toBe('marie')
    expect(hers?.wine.id).toBe(wine('w2'))
  })

  test('a solo user only sees their own bottles, all marked mine', async () => {
    fake.seed('cellar', 'solo_w1', bottle('solo', 'w1', 0, 0))
    fake.seed('beverages', 'w1', beverage('solo', 'w1'))

    const { items } = await CellarQuery.bottlesPage(user('solo'), { limit: 15 })

    expect(items).toHaveLength(1)
    expect(items[0].owner).toMatchObject({ isMine: true })
  })
})

describe('CellarQuery.householdPlacements', () => {
  test('merges every member’s placed bottles', async () => {
    seedHousehold()
    const placements = await CellarQuery.householdPlacements(user('owner'))
    expect(placements.map((bottle) => String(bottle.beverageId)).toSorted()).toEqual(['w1', 'w2'])
  })

  test('a solo user sees only their own bottles', async () => {
    fake.seed('cellar', 'solo_w1', bottle('solo', 'w1', 0, 0))
    const placements = await CellarQuery.householdPlacements(user('solo'))
    expect(placements.map((bottle) => String(bottle.beverageId))).toEqual(['w1'])
  })
})

describe('CellarQuery.householdBottleCount', () => {
  test('counts bottles across the whole household', async () => {
    seedHousehold()
    expect(await CellarQuery.householdBottleCount(user('owner'))).toBe(2)
  })
})

describe('CellarQuery.info (household)', () => {
  test('placedCount spans the household', async () => {
    seedHousehold()
    const info = await CellarQuery.info(user('owner'))
    expect(info.placedCount).toBe(2)
  })
})

describe('CellarQuery.suggestPosition (household)', () => {
  test('skips positions occupied by any member', async () => {
    seedHousehold() // owner at (0,0), marie at (0,1)
    const suggestion = await CellarQuery.suggestPosition(user('owner'))
    expect(suggestion).toMatchObject({ row: 0, col: 2 })
  })
})

describe('CellarQuery.config', () => {
  test('falls back to the default size (1 zone) when unconfigured', async () => {
    expect(await CellarQuery.config(user('solo'))).toMatchObject({ rows: 6, cols: 8, zones: 1 })
  })

  test('honors a saved solo config (usr_ key)', async () => {
    fake.seed('cellar-configs', 'usr_solo', { rows: 10, cols: 5, zones: 2 })
    expect(await CellarQuery.config(user('solo'))).toMatchObject({ rows: 10, cols: 5, zones: 2 })
  })

  test('defaults zones to 1 for a config saved before the field existed', async () => {
    fake.seed('cellar-configs', 'usr_solo', { rows: 10, cols: 5 })
    expect(await CellarQuery.config(user('solo'))).toMatchObject({ rows: 10, cols: 5, zones: 1 })
  })

  test('both household members read the same shared config (hh_ key)', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner'))
    fake.seed('household-members', 'marie', member('marie', 'member'))
    fake.seed('cellar-configs', 'hh_h1', { rows: 12, cols: 7 })
    expect(await CellarQuery.config(user('owner'))).toMatchObject({ rows: 12, cols: 7 })
    expect(await CellarQuery.config(user('marie'))).toMatchObject({ rows: 12, cols: 7 })
  })

  test('info reflects the configured dimensions and capacity', async () => {
    fake.seed('cellar-configs', 'usr_solo', { rows: 10, cols: 5 })
    const info = await CellarQuery.info(user('solo'))
    expect(info).toMatchObject({ rows: 10, cols: 5, capacity: 50 })
  })
})
