import { beforeEach, describe, expect, mock, test } from 'bun:test'
import { graphql } from 'graphql'
import type { UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { schema } = await import('~/domain/shared/graphql/schema')
const { beverageSatelliteLoaders } = await import('~/domain/shared/graphql/loaders')

// The viewer is the invited member: they own nothing, the cellar is the owner's.
const guest = 'guest' as UserId

let fake = resetFakeFirestore()
beforeEach(() => {
  fake = resetFakeFirestore()
})

const execute = (source: string, userId: UserId = guest) =>
  graphql({
    schema,
    source,
    contextValue: { userId, event: undefined as never, loaders: beverageSatelliteLoaders(userId) },
  })

const member = (id: string, role: 'owner' | 'member') => ({
  userId: id,
  householdId: 'h1',
  displayName: `${id} name`,
  role,
  joinedAt: new Date('2026-01-01'),
})

const seedSharedCellar = () => {
  fake.seed('household-members', 'owner', member('owner', 'owner'))
  fake.seed('household-members', 'guest', member('guest', 'member'))
  fake.seed('beverages', 'o1', {
    id: 'o1',
    userId: 'owner',
    name: 'Château Partagé',
    beverageType: 'wine',
    wine: { color: 'red' },
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
  })
  fake.seed('cellar', 'owner_o1', {
    userId: 'owner',
    beverageId: 'o1',
    row: 0,
    col: 0,
    createdAt: new Date('2026-01-10'),
    updatedAt: new Date('2026-01-10'),
  })
  fake.seed('journal', 'j-owner', {
    userId: 'owner',
    beverageId: 'o1',
    type: 'in',
    row: 0,
    col: 0,
    date: new Date('2026-01-10'),
  })
}

describe('journalEvents query', () => {
  test('an invited member reads the shared cellar’s movements, named by their author', async () => {
    seedSharedCellar()

    const result = await execute(`
      query {
        journalEvents(limit: 15, offset: 0) {
          items { type beverageName position actor { displayName isMine } }
          hasMore
        }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(result.data?.journalEvents).toMatchObject({
      items: [
        {
          type: 'IN',
          beverageName: 'Château Partagé',
          position: 'A1',
          actor: { displayName: 'owner name', isMine: false },
        },
      ],
      hasMore: false,
    })
  })

  test('the owner’s own movements carry no name to badge', async () => {
    seedSharedCellar()

    const result = await execute(
      `query { journalEvents { items { actor { displayName isMine } } } }`,
      'owner' as UserId,
    )

    expect(result.errors).toBeUndefined()
    expect(result.data?.journalEvents).toMatchObject({
      items: [{ actor: { displayName: null, isMine: true } }],
    })
  })
})

describe('the per-wine history field', () => {
  test('a shared bottle carries the movements of whoever placed it', async () => {
    seedSharedCellar()

    const result = await execute(`
      query {
        beverages(limit: 10) {
          items { id history { type position actor { displayName isMine } } }
        }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(result.data?.beverages).toMatchObject({
      items: [
        {
          id: 'o1',
          history: [
            { type: 'IN', position: 'A1', actor: { displayName: 'owner name', isMine: false } },
          ],
        },
      ],
    })
  })
})

describe('dashboard query', () => {
  test('an invited member sees the shared cellar, its history named by author', async () => {
    seedSharedCellar()

    const result = await execute(`
      query {
        dashboard {
          bottleCount
          history { beverageName actor { displayName isMine } }
        }
      }
    `)

    expect(result.errors).toBeUndefined()
    expect(result.data?.dashboard).toMatchObject({
      bottleCount: 1,
      history: [
        { beverageName: 'Château Partagé', actor: { displayName: 'owner name', isMine: false } },
      ],
    })
  })
})
