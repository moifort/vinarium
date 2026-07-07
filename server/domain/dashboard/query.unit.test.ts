import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { DashboardQuery } = await import('~/domain/dashboard/query')

const userId = 'user-1' as UserId
const currentYear = new Date().getFullYear()

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

const seedDashboardData = () => {
  fake.seed('beverages', 'w1', {
    id: 'w1',
    userId,
    name: 'Château Cave',
    beverageType: 'wine',
    purchase: { price: 30 },
    wine: { color: 'red', drinkWindow: { from: currentYear - 1, until: currentYear + 5 } },
    createdAt: new Date('2026-01-10'),
  })
  fake.seed('beverages', 'w2', {
    id: 'w2',
    userId,
    name: 'Domaine Favori',
    beverageType: 'wine',
    wine: { color: 'white', vintage: 2019 },
    createdAt: new Date('2026-01-05'),
  })
  fake.seed('cellar', `${userId}_w1`, {
    userId,
    beverageId: 'w1',
    row: 0,
    col: 0,
    createdAt: new Date('2026-01-10'),
    updatedAt: new Date('2026-01-10'),
  })
  fake.seed('tasting', `${userId}_w2`, {
    userId,
    beverageId: 'w2',
    favorite: true,
    rating: 5,
    consumedDate: new Date('2026-02-01'),
  })
  fake.seed('journal', 'j1', {
    userId,
    beverageId: 'w1',
    type: 'in',
    row: 0,
    col: 0,
    date: new Date('2026-01-10'),
  })
  fake.seed('journal', 'j2', {
    userId,
    beverageId: 'w2',
    type: 'out',
    row: 1,
    col: 1,
    date: new Date('2026-02-01'),
  })
}

describe('DashboardQuery.view', () => {
  test('assembles the dashboard view', async () => {
    seedDashboardData()

    const view = await DashboardQuery.view(userId)

    expect(view.bottleCount).toBe(1)
    expect(view.capacity).toBe(48)
    expect(view.totalValue).toBe(30)
    expect(view.readyToDrink).toMatchObject([{ id: 'w1', position: 'A1', urgent: false }])
    expect(view.favorites).toMatchObject([{ id: 'w2', name: 'Domaine Favori', rating: 5 }])
    expect(view.lastBottle).toMatchObject({ wine: { id: 'w1' }, position: 'A1' })
    expect(view.lastExit).toMatchObject({ beverageId: 'w2', type: 'out' })
    expect(view.history).toHaveLength(2)
  })

  test('reads each collection exactly once (wines is shared, not re-fetched)', async () => {
    seedDashboardData()

    const before = fake.reads
    await DashboardQuery.view(userId)

    // wines + cellar + journal + tasting = 4 collection reads, no duplicates
    expect(fake.reads - before).toBe(4)
  })
})
