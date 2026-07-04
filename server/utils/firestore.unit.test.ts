import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { UserId } from '~/domain/shared/types'
import type { WineId } from '~/domain/wine/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { userWineRecordRepository } = await import('~/utils/firestore')

const userId = 'user-1' as UserId
type Record = { userId: UserId; wineId: WineId; note: string }
const repo = userWineRecordRepository<Record>('records')

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('userWineRecordRepository.findManyByWineIds', () => {
  const seed = () => {
    fake.seed('records', `${userId}_w1`, { userId, wineId: 'w1', note: 'a' })
    fake.seed('records', `${userId}_w2`, { userId, wineId: 'w2', note: 'b' })
    fake.seed('records', `${userId}_w3`, { userId, wineId: 'w3', note: 'c' })
  }

  test('loads only the requested ids, one read each (no full scan)', async () => {
    seed()
    const before = fake.reads
    const result = await repo.findManyByWineIds(userId, ['w1', 'w3'] as WineId[])
    expect(result.map((r) => String(r.wineId)).sort()).toEqual(['w1', 'w3'])
    expect(fake.reads - before).toBe(2)
  })

  test('returns [] with zero reads for an empty id list', async () => {
    seed()
    const before = fake.reads
    expect(await repo.findManyByWineIds(userId, [])).toEqual([])
    expect(fake.reads - before).toBe(0)
  })

  test('filters out ids that have no record', async () => {
    seed()
    const result = await repo.findManyByWineIds(userId, ['w1', 'missing'] as WineId[])
    expect(result.map((r) => String(r.wineId))).toEqual(['w1'])
  })
})
