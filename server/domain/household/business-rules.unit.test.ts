import { describe, expect, test } from 'bun:test'
import {
  INVITATION_TTL_DAYS,
  invitationExpiry,
  invitationStatus,
  newInvitationCode,
  nextOwner,
} from '~/domain/household/business-rules'
import type { HouseholdId, HouseholdInvitation, HouseholdMember } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'

const household = 'h1' as HouseholdId
const user = (id: string) => id as UserId

const invitation = (overrides: Partial<HouseholdInvitation> = {}): HouseholdInvitation => ({
  code: 'ABC234' as HouseholdInvitation['code'],
  householdId: household,
  createdBy: user('owner'),
  createdAt: new Date('2026-01-01'),
  expiresAt: new Date('2026-01-08'),
  ...overrides,
})

const member = (id: string, joinedAt: string): HouseholdMember => ({
  userId: user(id),
  householdId: household,
  displayName: id as PersonName,
  role: 'member',
  joinedAt: new Date(joinedAt),
})

describe('newInvitationCode', () => {
  test('draws six characters from the unambiguous alphabet', () => {
    const code = newInvitationCode(() => 0)
    expect(code as string).toBe('AAAAAA')
  })
  test('uses the injected index for each position', () => {
    let call = 0
    const code = newInvitationCode(() => call++)
    expect(code as string).toBe('ABCDEF')
  })
})

describe('invitationExpiry', () => {
  test('is seven days after now', () => {
    const now = new Date('2026-01-01T00:00:00Z')
    const expiry = invitationExpiry(now)
    const days = (expiry.getTime() - now.getTime()) / (24 * 60 * 60 * 1000)
    expect(days).toBe(INVITATION_TTL_DAYS)
  })
})

describe('invitationStatus', () => {
  const now = new Date('2026-01-05')
  test('usable when fresh', () => expect(invitationStatus(invitation(), now)).toBe('usable'))
  test('revoked takes precedence', () =>
    expect(invitationStatus(invitation({ revokedAt: new Date('2026-01-03') }), now)).toBe(
      'revoked',
    ))
  test('used when consumed', () =>
    expect(invitationStatus(invitation({ usedBy: user('x') }), now)).toBe('used'))
  test('expired when past its expiry', () =>
    expect(invitationStatus(invitation({ expiresAt: new Date('2026-01-04') }), now)).toBe(
      'expired',
    ))
})

describe('nextOwner', () => {
  test('undefined when no members remain', () => expect(nextOwner([])).toBeUndefined())
  test('picks the earliest-joined member', () => {
    const heir = nextOwner([
      member('c', '2026-01-03'),
      member('a', '2026-01-01'),
      member('b', '2026-01-02'),
    ])
    expect(heir?.userId).toBe(user('a'))
  })
})
