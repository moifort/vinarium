import type { WriteBatch } from 'firebase-admin/firestore'
import type { UserId } from '~/domain/shared/types'
import type { UserProfile } from '~/domain/user/types'
import { db } from '~/system/firebase'
import { memoizedPerRequest } from '~/system/request-cache'
import { genericDataConverter } from '~/utils/firestore'

const profiles = () =>
  db().collection('user-profiles').withConverter(genericDataConverter<UserProfile>())

// A user's profile — at most one, since the doc id IS the userId. Memoized: the
// auth gate reads it on every launch, so it must cost a single read per request.
export const findProfile = (userId: UserId): Promise<UserProfile | null> =>
  memoizedPerRequest(`user:profile:${userId}`, async () => {
    const doc = await profiles().doc(userId).get()
    return doc.data() ?? null
  })

export const saveProfile = async (
  profile: UserProfile,
  batch?: WriteBatch,
): Promise<UserProfile> => {
  const ref = profiles().doc(profile.userId)
  if (batch) batch.set(ref, profile)
  else await ref.set(profile)
  return profile
}
