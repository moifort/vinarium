import type { WriteBatch } from 'firebase-admin/firestore'
import type {
  Household,
  HouseholdId,
  HouseholdInvitation,
  HouseholdMember,
  InvitationCode,
} from '~/domain/household/types'
import type { UserId } from '~/domain/shared/types'
import { db } from '~/system/firebase'
import { evictFromRequestCache, memoizedPerRequest } from '~/system/request-cache'
import { genericDataConverter } from '~/utils/firestore'

const households = () =>
  db().collection('households').withConverter(genericDataConverter<Household>())
const members = () =>
  db().collection('household-members').withConverter(genericDataConverter<HouseholdMember>())
const invitations = () =>
  db()
    .collection('household-invitations')
    .withConverter(genericDataConverter<HouseholdInvitation>())

const memberCacheKey = (userId: UserId) => `household:member:${userId}`

// A user's membership — at most one, since the doc id IS the userId. Memoized:
// every shared-cellar read resolves its scope through this, so it must cost a
// single read per request.
export const findMembership = (userId: UserId): Promise<HouseholdMember | null> =>
  memoizedPerRequest(memberCacheKey(userId), async () => {
    const doc = await members().doc(userId).get()
    return doc.data() ?? null
  })

// Drop the memoized membership after a write that changes it, so a re-query later
// in the same request (e.g. joinHousehold returning the fresh household view) does
// not see the pre-write state — the read-then-write caveat in request-cache.ts.
export const evictMembershipCache = (userId: UserId): void =>
  evictFromRequestCache(memberCacheKey(userId))

export const findHousehold = async (id: HouseholdId): Promise<Household | null> => {
  const doc = await households().doc(id).get()
  return doc.data() ?? null
}

export const findMembers = async (householdId: HouseholdId): Promise<HouseholdMember[]> => {
  const snap = await members().where('householdId', '==', householdId).get()
  return snap.docs.map((doc) => doc.data())
}

export const findInvitation = async (code: InvitationCode): Promise<HouseholdInvitation | null> => {
  const doc = await invitations().doc(code).get()
  return doc.data() ?? null
}

// Every invitation of a household, whatever its status. Callers filter to usable
// codes themselves (the settings view) or need the full set (leave cleanup).
export const findInvitationsByHousehold = async (
  householdId: HouseholdId,
): Promise<HouseholdInvitation[]> => {
  const snap = await invitations().where('householdId', '==', householdId).get()
  return snap.docs.map((doc) => doc.data())
}

export const saveHousehold = async (
  household: Household,
  batch?: WriteBatch,
): Promise<Household> => {
  const ref = households().doc(household.id)
  if (batch) batch.set(ref, household)
  else await ref.set(household)
  return household
}

export const saveMember = async (
  member: HouseholdMember,
  batch?: WriteBatch,
): Promise<HouseholdMember> => {
  const ref = members().doc(member.userId)
  if (batch) batch.set(ref, member)
  else await ref.set(member)
  return member
}

export const saveInvitation = async (
  invitation: HouseholdInvitation,
  batch?: WriteBatch,
): Promise<HouseholdInvitation> => {
  const ref = invitations().doc(invitation.code)
  if (batch) batch.set(ref, invitation)
  else await ref.set(invitation)
  return invitation
}

export const removeMember = (userId: UserId, batch: WriteBatch): void => {
  batch.delete(members().doc(userId))
}

export const removeHousehold = (id: HouseholdId, batch: WriteBatch): void => {
  batch.delete(households().doc(id))
}

export const removeInvitation = (code: InvitationCode, batch: WriteBatch): void => {
  batch.delete(invitations().doc(code))
}
