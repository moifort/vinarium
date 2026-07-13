import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type { HouseholdId, HouseholdInvitation, HouseholdMember } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { HouseholdQuery } = await import('~/domain/household/query')

const user = (id: string) => id as UserId
const name = (value: string) => value as PersonName
const household = 'h1' as HouseholdId

const member = (id: string, role: 'owner' | 'member', joinedAt: string): HouseholdMember => ({
  userId: user(id),
  householdId: household,
  displayName: name(id),
  role,
  joinedAt: new Date(joinedAt),
})

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('HouseholdQuery.cellarScope', () => {
  test('a solo user is a scope of one, with no display names', async () => {
    const scope = await HouseholdQuery.cellarScope(user('solo'))
    expect(scope.memberIds).toEqual([user('solo')])
    expect(scope.displayNames.size).toBe(0)
  })

  test('a household resolves to every member id and display name', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-members', 'marie', member('marie', 'member', '2026-01-02'))

    const scope = await HouseholdQuery.cellarScope(user('owner'))

    expect(new Set(scope.memberIds)).toEqual(new Set([user('owner'), user('marie')]))
    expect(scope.displayNames.get(user('marie')) as string).toBe('marie')
  })

  test('resolves in two reads then serves from cache', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-members', 'marie', member('marie', 'member', '2026-01-02'))

    await HouseholdQuery.cellarScope(user('owner'))
    const afterFirst = fake.reads
    expect(afterFirst).toBe(2)

    await HouseholdQuery.cellarScope(user('owner'))
    expect(fake.reads).toBe(afterFirst)
  })
})

describe('HouseholdQuery.view', () => {
  test('returns not-in-household for a solo user', async () => {
    expect(await HouseholdQuery.view(user('solo'))).toBe('not-in-household')
  })

  test('lists members oldest-first and keeps only usable invitations', async () => {
    fake.seed('households', 'h1', {
      id: household,
      createdBy: user('owner'),
      createdAt: new Date(),
    })
    fake.seed('household-members', 'marie', member('marie', 'member', '2026-01-02'))
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    const open: HouseholdInvitation = {
      code: 'ABC234' as HouseholdInvitation['code'],
      householdId: household,
      createdBy: user('owner'),
      createdAt: new Date('2026-01-01'),
      expiresAt: new Date('2100-01-01'),
    }
    const used: HouseholdInvitation = {
      ...open,
      code: 'DEF567' as HouseholdInvitation['code'],
      usedBy: user('marie'),
    }
    fake.seed('household-invitations', 'ABC234', open)
    fake.seed('household-invitations', 'DEF567', used)

    const view = await HouseholdQuery.view(user('owner'))
    if (view === 'not-in-household') throw new Error('expected a household view')

    expect(view.members.map((m) => m.userId)).toEqual([user('owner'), user('marie')])
    expect(view.invitations.map((i) => i.code as string)).toEqual(['ABC234'])
  })
})
