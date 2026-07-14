import type { UserId } from '~/domain/shared/types'
import * as repository from '~/domain/user/infrastructure/repository'
import type { MeView } from '~/domain/user/types'

export namespace UserQuery {
  // The signed-in user's identity and onboarding state. Returns nulls when no
  // profile exists yet — the app routes to onboarding on a missing timestamp.
  export const me = async (userId: UserId): Promise<MeView> => {
    const profile = await repository.findProfile(userId)
    return {
      userId,
      firstName: profile?.firstName,
      onboardingCompletedAt: profile?.onboardingCompletedAt,
    }
  }
}
