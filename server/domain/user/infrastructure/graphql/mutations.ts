import { CellarCols, CellarRows } from '~/domain/cellar/primitives'
import { builder } from '~/domain/shared/graphql/builder'
import { badUserInput } from '~/domain/shared/graphql/errors'
import { UserQuery } from '~/domain/user/query'
import { UserUseCase } from '~/domain/user/use-case'
import { CompleteOnboardingInput } from './inputs'
import { MeType } from './types'

builder.mutationField('completeOnboarding', (t) =>
  t.field({
    type: MeType,
    description: 'Finish onboarding: save the user’s prénom and cellar dimensions',
    args: {
      input: t.arg({
        type: CompleteOnboardingInput,
        required: true,
        description: 'The prénom and cellar dimensions to persist',
      }),
    },
    resolve: async (_root, { input }, { userId }) => {
      // rows/cols travel as Int and are validated here (1..100); a bad value is a
      // BAD_USER_INPUT rather than a raw Zod error.
      const dimensions = parseDimensions(input.rows, input.cols)
      await UserUseCase.completeOnboarding(userId, {
        firstName: input.firstName,
        ...dimensions,
      })
      return UserQuery.me(userId)
    },
  }),
)

const parseDimensions = (rows: number, cols: number) => {
  try {
    return { rows: CellarRows(rows), cols: CellarCols(cols) }
  } catch {
    return badUserInput('rows and cols must be integers between 1 and 100')
  }
}
