import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

const userId = 'user-1' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const execute = (source: string) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const reconfigure = (rows: number, cols: number, zones = 2) => `
  mutation {
    reconfigureCellar(rows: ${rows}, cols: ${cols}, zones: ${zones}) {
      __typename
      ... on CellarInfo { rows cols zones capacity placedCount }
      ... on CellarReconfigureBlocked { outOfBoundsCount }
    }
  }
`

const bottle = (beverageId: string, row: number, col: number) => ({
  userId,
  beverageId,
  row,
  col,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
})

describe('reconfigureCellar mutation', () => {
  test('resizes the grid and returns the updated CellarInfo', async () => {
    fake.seed('cellar-configs', 'usr_user-1', { rows: 6, cols: 8, zones: 1 })

    const result = await execute(reconfigure(10, 5, 3))

    expect(result.errors).toBeUndefined()
    expect(result.data?.reconfigureCellar).toMatchObject({
      __typename: 'CellarInfo',
      rows: 10,
      cols: 5,
      zones: 3,
      capacity: 50,
      placedCount: 0,
    })
    expect(fake.snapshot('cellar-configs').get('usr_user-1')).toMatchObject({ rows: 10, cols: 5 })
  })

  test('returns CellarReconfigureBlocked and leaves the config untouched when a bottle would be stranded', async () => {
    fake.seed('cellar-configs', 'usr_user-1', { rows: 10, cols: 10, zones: 1 })
    fake.seed('cellar', 'user-1_w1', bottle('w1', 8, 2))

    const result = await execute(reconfigure(4, 5, 1))

    expect(result.errors).toBeUndefined()
    expect(result.data?.reconfigureCellar).toMatchObject({
      __typename: 'CellarReconfigureBlocked',
      outOfBoundsCount: 1,
    })
    expect(fake.snapshot('cellar-configs').get('usr_user-1')).toMatchObject({ rows: 10, cols: 10 })
  })

  test('rejects out-of-range dimensions with BAD_USER_INPUT', async () => {
    const result = await execute(reconfigure(0, 8, 1))
    expect(result.errors?.[0]?.extensions?.code).toBe('BAD_USER_INPUT')
  })
})
