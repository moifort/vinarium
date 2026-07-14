import type { WriteBatch } from 'firebase-admin/firestore'
import type { PersonName, UserId } from '~/domain/shared/types'
import * as repository from '~/domain/user/infrastructure/repository'

export namespace UserCommand {
  // Persist the profile that marks onboarding done. The cellar dimensions are
  // written separately by UserUseCase.completeOnboarding, in the same batch.
  export const completeOnboarding = (userId: UserId, firstName: PersonName, batch?: WriteBatch) =>
    repository.saveProfile({ userId, firstName, onboardingCompletedAt: new Date() }, batch)
}
