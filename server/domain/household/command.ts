import {
  invitationExpiry,
  invitationStatus,
  newInvitationCode,
  nextOwner,
} from '~/domain/household/business-rules'
import * as repository from '~/domain/household/infrastructure/repository'
import { randomHouseholdId } from '~/domain/household/primitives'
import type { HouseholdId, HouseholdInvitation, InvitationCode } from '~/domain/household/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { atomically } from '~/utils/firestore'

// A crypto-backed index in [0, max): an invitation code is a bearer credential
// granting access to a shared cellar, so its randomness must not be predictable
// (Math.random is not a CSPRNG). Rejection sampling keeps it unbiased for any max.
const cryptoRandomIndex = (max: number) => {
  const ceiling = Math.floor(0x100000000 / max) * max
  const buffer = new Uint32Array(1)
  let value: number
  do {
    crypto.getRandomValues(buffer)
    value = buffer[0]
  } while (value >= ceiling)
  return value % max
}

export namespace HouseholdCommand {
  // Generate an invitation code. The first invite a solo user creates also brings
  // the household into being, with the caller as its owner — done in one batch so a
  // household never exists without its owner.
  export const createInvitation = async (userId: UserId, displayName: PersonName) => {
    const now = new Date()
    const code = newInvitationCode(cryptoRandomIndex)
    const expiresAt = invitationExpiry(now)
    const membership = await repository.findMembership(userId)

    return atomically(async (batch) => {
      let householdId: HouseholdId
      if (membership) {
        householdId = membership.householdId
      } else {
        householdId = randomHouseholdId()
        await repository.saveHousehold(
          { id: householdId, createdBy: userId, createdAt: now },
          batch,
        )
        await repository.saveMember(
          { userId, householdId, displayName, role: 'owner', joinedAt: now },
          batch,
        )
      }
      const invitation: HouseholdInvitation = {
        code,
        householdId,
        createdBy: userId,
        createdAt: now,
        expiresAt,
      }
      await repository.saveInvitation(invitation, batch)
      return { outcome: 'created' as const, code, expiresAt }
    })
  }

  export const joinByCode = async (
    userId: UserId,
    code: InvitationCode,
    displayName: PersonName,
  ) => {
    const now = new Date()
    const [invitation, membership] = await Promise.all([
      repository.findInvitation(code),
      repository.findMembership(userId),
    ])
    if (membership) return 'already-in-household' as const
    if (!invitation) return 'invalid-code' as const
    const status = invitationStatus(invitation, now)
    if (status === 'expired') return 'expired' as const
    if (status === 'used') return 'already-used' as const
    if (status === 'revoked') return 'revoked' as const

    const result = await atomically(async (batch) => {
      await repository.saveMember(
        {
          userId,
          householdId: invitation.householdId,
          displayName,
          role: 'member',
          joinedAt: now,
        },
        batch,
      )
      await repository.saveInvitation({ ...invitation, usedBy: userId, usedAt: now }, batch)
      return { outcome: 'joined' as const, householdId: invitation.householdId }
    })
    // The membership was memoized as absent before the write above; drop it so the
    // resolver's follow-up household view sees the caller as a member.
    repository.evictMembershipCache(userId)
    return result
  }

  // Leave the household. When the owner leaves, ownership passes to the
  // earliest-joined remaining member; when the last member leaves, the household
  // and its open invitations are deleted.
  export const leave = async (userId: UserId) => {
    const membership = await repository.findMembership(userId)
    if (!membership) return 'not-in-household' as const
    const members = await repository.findMembers(membership.householdId)
    const remaining = members.filter((member) => member.userId !== userId)
    const openInvitations =
      remaining.length === 0
        ? await repository.findInvitationsByHousehold(membership.householdId)
        : []

    return atomically(async (batch) => {
      repository.removeMember(userId, batch)
      if (remaining.length === 0) {
        repository.removeHousehold(membership.householdId, batch)
        for (const invitation of openInvitations)
          repository.removeInvitation(invitation.code, batch)
      } else if (membership.role === 'owner') {
        const heir = nextOwner(remaining)
        if (heir) await repository.saveMember({ ...heir, role: 'owner' }, batch)
      }
      return { outcome: 'left' as const }
    })
  }

  export const removeMember = async (actorId: UserId, memberId: UserId) => {
    if (actorId === memberId) return 'cannot-remove-self' as const
    const [actor, target] = await Promise.all([
      repository.findMembership(actorId),
      repository.findMembership(memberId),
    ])
    if (!actor) return 'not-in-household' as const
    if (actor.role !== 'owner') return 'not-owner' as const
    if (!target || target.householdId !== actor.householdId) return 'not-a-member' as const

    return atomically(async (batch) => {
      repository.removeMember(memberId, batch)
      return { outcome: 'removed' as const }
    })
  }

  export const revokeInvitation = async (actorId: UserId, code: InvitationCode) => {
    const [actor, invitation] = await Promise.all([
      repository.findMembership(actorId),
      repository.findInvitation(code),
    ])
    if (!invitation) return 'invalid-code' as const
    if (!actor || actor.householdId !== invitation.householdId) return 'not-in-household' as const
    if (!invitation.usedBy && !invitation.revokedAt)
      await repository.saveInvitation({ ...invitation, revokedAt: new Date() })
    return { outcome: 'revoked' as const }
  }
}
