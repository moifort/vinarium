import { beforeEach, describe, expect, mock, test } from 'bun:test'
import type {
  HouseholdId,
  HouseholdInvitation,
  HouseholdMember,
  InvitationCode,
} from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { fakeDb, resetFakeFirestore } from '~/test/fake-firestore'

mock.module('~/system/firebase', () => ({ db: fakeDb }))

const { HouseholdCommand } = await import('~/domain/household/command')
const { HouseholdQuery } = await import('~/domain/household/query')

const user = (id: string) => id as UserId
const name = (value: string) => value as PersonName
const code = (value: string) => value as InvitationCode
const household = 'h1' as HouseholdId

const member = (
  id: string,
  role: 'owner' | 'member',
  joinedAt: string,
  householdId: HouseholdId = household,
): HouseholdMember => ({
  userId: user(id),
  householdId,
  displayName: name(id),
  role,
  joinedAt: new Date(joinedAt),
})

const invitation = (overrides: Partial<HouseholdInvitation> = {}): HouseholdInvitation => ({
  code: code('ABC234'),
  householdId: household,
  createdBy: user('owner'),
  createdAt: new Date('2026-01-01'),
  expiresAt: new Date('2100-01-01'),
  ...overrides,
})

let fake = resetFakeFirestore()

beforeEach(() => {
  fake = resetFakeFirestore()
})

describe('HouseholdCommand.createInvitation', () => {
  test('a solo user gets a household, an owner membership and an invitation in one batch', async () => {
    const result = await HouseholdCommand.createInvitation(user('owner'), name('Thibaut'))

    expect(result.outcome).toBe('created')
    expect(result.code as string).toMatch(/^[A-HJ-NP-Z2-9]{6}$/)
    expect(fake.batches).toHaveLength(1)
    expect(fake.batches[0].commits).toBe(1)
    expect(fake.batches[0].ops).toHaveLength(3)
    expect(fake.directWrites).toEqual([])

    const owner = fake.snapshot('household-members').get('owner')
    expect(owner).toMatchObject({ userId: 'owner', role: 'owner', displayName: 'Thibaut' })
    expect(fake.snapshot('households').size).toBe(1)
    expect(fake.snapshot('household-invitations').get(result.code)).toMatchObject({
      createdBy: 'owner',
    })
  })

  test('an existing member only writes the invitation', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))

    const result = await HouseholdCommand.createInvitation(user('owner'), name('Thibaut'))

    expect(fake.batches[0].ops).toHaveLength(1)
    expect(fake.snapshot('households').size).toBe(0)
    expect(fake.snapshot('household-invitations').get(result.code)).toMatchObject({
      householdId: 'h1',
    })
  })
})

describe('HouseholdCommand.joinByCode', () => {
  test('joins the household and consumes the code in one batch', async () => {
    fake.seed('household-invitations', 'ABC234', invitation())

    const result = await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))

    expect(result).toMatchObject({ outcome: 'joined', householdId: 'h1' })
    expect(fake.batches[0].ops).toHaveLength(2)
    expect(fake.snapshot('household-members').get('marie')).toMatchObject({
      role: 'member',
      displayName: 'Marie',
      householdId: 'h1',
    })
    expect(fake.snapshot('household-invitations').get('ABC234')).toMatchObject({ usedBy: 'marie' })
  })

  test('rejects an unknown code', async () => {
    expect(await HouseholdCommand.joinByCode(user('marie'), code('ZZZ999'), name('Marie'))).toBe(
      'invalid-code',
    )
    expect(fake.batches).toHaveLength(0)
  })

  test('rejects an expired code', async () => {
    fake.seed('household-invitations', 'ABC234', invitation({ expiresAt: new Date('2020-01-01') }))
    expect(await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))).toBe(
      'expired',
    )
  })

  test('rejects an already-used code', async () => {
    fake.seed('household-invitations', 'ABC234', invitation({ usedBy: user('bob') }))
    expect(await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))).toBe(
      'already-used',
    )
  })

  test('rejects a revoked code', async () => {
    fake.seed('household-invitations', 'ABC234', invitation({ revokedAt: new Date('2026-01-02') }))
    expect(await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))).toBe(
      'revoked',
    )
  })

  test('rejects a user already in a household', async () => {
    fake.seed('household-invitations', 'ABC234', invitation())
    fake.seed(
      'household-members',
      'marie',
      member('marie', 'owner', '2026-01-01', 'h2' as HouseholdId),
    )
    expect(await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))).toBe(
      'already-in-household',
    )
  })

  test('a code is single-use across two joiners', async () => {
    fake.seed('household-invitations', 'ABC234', invitation())
    await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))
    expect(await HouseholdCommand.joinByCode(user('paul'), code('ABC234'), name('Paul'))).toBe(
      'already-used',
    )
  })

  // Guards the request-cache read-then-write hazard: joining memoizes the caller
  // as absent, so the follow-up household view must not read that stale value.
  test('a fresh join is immediately visible to a re-query in the same request', async () => {
    fake.seed('households', 'h1', {
      id: household,
      createdBy: user('owner'),
      createdAt: new Date(),
    })
    fake.seed('household-invitations', 'ABC234', invitation())

    await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))
    const view = await HouseholdQuery.view(user('marie'))

    expect(view).not.toBe('not-in-household')
    if (view === 'not-in-household') throw new Error('expected a household view')
    expect(view.members.map((member) => member.userId)).toContain(user('marie'))
  })
})

describe('HouseholdCommand.leave', () => {
  test('transfers ownership to the earliest-joined member when the owner leaves', async () => {
    fake.seed('households', 'h1', {
      id: household,
      createdBy: user('owner'),
      createdAt: new Date(),
    })
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-members', 'marie', member('marie', 'member', '2026-01-02'))
    fake.seed('household-members', 'paul', member('paul', 'member', '2026-01-03'))

    const result = await HouseholdCommand.leave(user('owner'))

    expect(result).toMatchObject({ outcome: 'left' })
    expect(fake.snapshot('household-members').get('owner')).toBeUndefined()
    expect(fake.snapshot('household-members').get('marie')).toMatchObject({ role: 'owner' })
    expect(fake.snapshot('households').get('h1')).toBeDefined()
  })

  test('the last member out deletes the household and its open invitations', async () => {
    fake.seed('households', 'h1', {
      id: household,
      createdBy: user('owner'),
      createdAt: new Date(),
    })
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-invitations', 'ABC234', invitation())

    await HouseholdCommand.leave(user('owner'))

    expect(fake.snapshot('household-members').size).toBe(0)
    expect(fake.snapshot('households').get('h1')).toBeUndefined()
    expect(fake.snapshot('household-invitations').size).toBe(0)
  })

  test('rejects a user in no household', async () => {
    expect(await HouseholdCommand.leave(user('nobody'))).toBe('not-in-household')
  })
})

describe('HouseholdCommand.removeMember', () => {
  test('the owner removes a member', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-members', 'marie', member('marie', 'member', '2026-01-02'))

    const result = await HouseholdCommand.removeMember(user('owner'), user('marie'))

    expect(result).toMatchObject({ outcome: 'removed' })
    expect(fake.snapshot('household-members').get('marie')).toBeUndefined()
  })

  test('a non-owner cannot remove', async () => {
    fake.seed('household-members', 'marie', member('marie', 'member', '2026-01-02'))
    fake.seed('household-members', 'paul', member('paul', 'member', '2026-01-03'))
    expect(await HouseholdCommand.removeMember(user('marie'), user('paul'))).toBe('not-owner')
  })

  test('cannot remove yourself', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    expect(await HouseholdCommand.removeMember(user('owner'), user('owner'))).toBe(
      'cannot-remove-self',
    )
  })

  test('rejects a target in another household', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed(
      'household-members',
      'paul',
      member('paul', 'member', '2026-01-03', 'h2' as HouseholdId),
    )
    expect(await HouseholdCommand.removeMember(user('owner'), user('paul'))).toBe('not-a-member')
  })

  test('rejects an actor in no household', async () => {
    fake.seed('household-members', 'paul', member('paul', 'member', '2026-01-03'))
    expect(await HouseholdCommand.removeMember(user('nobody'), user('paul'))).toBe(
      'not-in-household',
    )
  })
})

describe('HouseholdCommand.revokeInvitation', () => {
  test('the owner revokes an open code, blocking a later join', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-invitations', 'ABC234', invitation())

    const result = await HouseholdCommand.revokeInvitation(user('owner'), code('ABC234'))

    expect(result).toMatchObject({ outcome: 'revoked' })
    expect(fake.snapshot('household-invitations').get('ABC234')?.revokedAt).toBeDefined()
    expect(await HouseholdCommand.joinByCode(user('marie'), code('ABC234'), name('Marie'))).toBe(
      'revoked',
    )
  })

  test('rejects a revoker outside the household', async () => {
    fake.seed('household-invitations', 'ABC234', invitation())
    expect(await HouseholdCommand.revokeInvitation(user('stranger'), code('ABC234'))).toBe(
      'not-in-household',
    )
  })

  test('is a no-op on an already-used code, without a second write', async () => {
    fake.seed('household-members', 'owner', member('owner', 'owner', '2026-01-01'))
    fake.seed('household-invitations', 'ABC234', invitation({ usedBy: user('marie') }))

    const result = await HouseholdCommand.revokeInvitation(user('owner'), code('ABC234'))

    expect(result).toMatchObject({ outcome: 'revoked' })
    expect(fake.snapshot('household-invitations').get('ABC234')?.revokedAt).toBeUndefined()
    expect(fake.directWrites).toEqual([])
  })
})
