import type { Brand } from 'ts-brand'
import type { PersonName, UserId } from '~/domain/shared/types'

export type HouseholdId = Brand<string, 'HouseholdId'>
export type InvitationCode = Brand<string, 'InvitationCode'>
export type HouseholdRole = 'owner' | 'member'

export type Household = {
  id: HouseholdId
  createdBy: UserId
  createdAt: Date
}

export type HouseholdMember = {
  userId: UserId
  householdId: HouseholdId
  displayName: PersonName
  role: HouseholdRole
  joinedAt: Date
}

export type HouseholdInvitation = {
  code: InvitationCode
  householdId: HouseholdId
  createdBy: UserId
  createdAt: Date
  expiresAt: Date
  usedBy?: UserId
  usedAt?: Date
  revokedAt?: Date
}

// The set of members whose bottles share one physical cellar, plus their display
// names — resolved once per request and consumed by every shared-cellar read.
// A solo user (no household) is a scope of one: [userId] with an empty name map.
export type CellarScope = {
  memberIds: UserId[]
  displayNames: Map<UserId, PersonName>
}

// A household projected with its members and, for the owner, the invitation codes
// still open — the shape the settings screen renders.
export type HouseholdView = Household & {
  members: HouseholdMember[]
  invitations: HouseholdInvitation[]
}
