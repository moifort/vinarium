import { invitationStatus } from '~/domain/household/business-rules'
import * as repository from '~/domain/household/infrastructure/repository'
import type { CellarScope, HouseholdView } from '~/domain/household/types'
import type { UserId } from '~/domain/shared/types'
import { memoizedPerRequest } from '~/system/request-cache'

export namespace HouseholdQuery {
  export const membershipOf = (userId: UserId) => repository.findMembership(userId)

  export const view = async (userId: UserId) => {
    const membership = await repository.findMembership(userId)
    if (!membership) return 'not-in-household' as const
    const [household, members, invitations] = await Promise.all([
      repository.findHousehold(membership.householdId),
      repository.findMembers(membership.householdId),
      repository.findInvitationsByHousehold(membership.householdId),
    ])
    if (!household) return 'not-in-household' as const
    const now = new Date()
    const view: HouseholdView = {
      ...household,
      members: [...members].sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime()),
      // Only the owner acts on invitations, but any member sees the open codes to
      // share; used/expired/revoked ones are dropped.
      invitations: invitations.filter(
        (invitation) => invitationStatus(invitation, now) === 'usable',
      ),
    }
    return view
  }

  // The shared-cellar scope: [userId] when solo, else every member's id and display
  // name. Memoized so the whole request pays at most two reads for the scope (the
  // membership doc and the members query), then nothing.
  export const cellarScope = (userId: UserId): Promise<CellarScope> =>
    memoizedPerRequest(`household:scope:${userId}`, async () => {
      const membership = await repository.findMembership(userId)
      if (!membership) return { memberIds: [userId], displayNames: new Map() }
      const members = await repository.findMembers(membership.householdId)
      if (members.length === 0) return { memberIds: [userId], displayNames: new Map() }
      return {
        memberIds: members.map((member) => member.userId),
        displayNames: new Map(members.map((member) => [member.userId, member.displayName])),
      }
    })
}
