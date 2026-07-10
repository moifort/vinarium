import {
  INVITATION_CODE_ALPHABET,
  INVITATION_CODE_LENGTH,
  InvitationCode,
} from '~/domain/household/primitives'
import type { HouseholdInvitation, HouseholdMember } from '~/domain/household/types'

export const INVITATION_TTL_DAYS = 7

// Build a fresh invitation code by drawing characters from the unambiguous
// alphabet. Randomness is injected so the rule stays pure and testable.
export const newInvitationCode = (randomIndex: (max: number) => number) => {
  const chars = Array.from(
    { length: INVITATION_CODE_LENGTH },
    () => INVITATION_CODE_ALPHABET[randomIndex(INVITATION_CODE_ALPHABET.length)],
  )
  return InvitationCode(chars.join(''))
}

export const invitationExpiry = (now: Date) =>
  new Date(now.getTime() + INVITATION_TTL_DAYS * 24 * 60 * 60 * 1000)

// A code is usable until it is revoked, consumed, or past its expiry — checked in
// that order so a revoked-then-expired code still reads as revoked.
export const invitationStatus = (invitation: HouseholdInvitation, now: Date) => {
  if (invitation.revokedAt) return 'revoked' as const
  if (invitation.usedBy) return 'used' as const
  if (invitation.expiresAt.getTime() <= now.getTime()) return 'expired' as const
  return 'usable' as const
}

// The member who inherits ownership when the owner leaves: the earliest to have
// joined. Undefined when no members remain (the household is then deleted).
export const nextOwner = (members: HouseholdMember[]): HouseholdMember | undefined =>
  members.length === 0
    ? undefined
    : [...members].sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime())[0]
