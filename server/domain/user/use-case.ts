import { CellarCommand } from '~/domain/cellar/command'
import type { CellarCols, CellarRows } from '~/domain/cellar/types'
import type { PersonName, UserId } from '~/domain/shared/types'
import { UserCommand } from '~/domain/user/command'
import { atomically } from '~/utils/firestore'

export namespace UserUseCase {
  // Finish onboarding: persist the profile (firstName + timestamp) and the cellar
  // dimensions in one batch, so a partial failure never leaves the user "half
  // onboarded" — either both land or neither does.
  export const completeOnboarding = async (
    userId: UserId,
    input: { firstName: PersonName; rows: CellarRows; cols: CellarCols },
  ) =>
    atomically(async (batch) => {
      await CellarCommand.configureFor(userId, input.rows, input.cols, batch)
      return UserCommand.completeOnboarding(userId, input.firstName, batch)
    })
}
