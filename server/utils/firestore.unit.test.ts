import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { BeverageId } from '~/domain/beverage/types'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { userBeverageRecordRepository } = await import('~/utils/firestore')

const userId = 'user-1' as UserId
type Record = { userId: UserId; beverageId: BeverageId; note: string }
const repo = userBeverageRecordRepository<Record>('records')

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('userBeverageRecordRepository.findManyByBeverageIds', () => {
  const seed = () => {
    fake.seed('records', `${userId}_w1`, { userId, beverageId: 'w1', note: 'a' })
    fake.seed('records', `${userId}_w2`, { userId, beverageId: 'w2', note: 'b' })
    fake.seed('records', `${userId}_w3`, { userId, beverageId: 'w3', note: 'c' })
  }

  test('loads only the requested ids, one read each (no full scan)', async () => {
    seed()
    const before = fake.reads
    const result = await repo.findManyByBeverageIds(userId, ['w1', 'w3'] as BeverageId[])
    expect(result.map((r) => String(r.beverageId)).sort()).toEqual(['w1', 'w3'])
    expect(fake.reads - before).toBe(2)
  })

  test('returns [] with zero reads for an empty id list', async () => {
    seed()
    const before = fake.reads
    expect(await repo.findManyByBeverageIds(userId, [])).toEqual([])
    expect(fake.reads - before).toBe(0)
  })

  test('filters out ids that have no record', async () => {
    seed()
    const result = await repo.findManyByBeverageIds(userId, ['w1', 'missing'] as BeverageId[])
    expect(result.map((r) => String(r.beverageId))).toEqual(['w1'])
  })
})
