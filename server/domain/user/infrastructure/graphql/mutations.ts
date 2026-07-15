import { CellarCols, CellarRows, CellarZones } from '~/domain/cellar/primitives'
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
      // rows/cols/zones travel as Int and are validated here; a bad value is a
      // BAD_USER_INPUT rather than a raw Zod error.
      const dimensions = parseDimensions(input.rows, input.cols, input.zones)
      await UserUseCase.completeOnboarding(userId, {
        firstName: input.firstName,
        ...dimensions,
      })
      return UserQuery.me(userId)
    },
  }),
)

const parseDimensions = (rows: number, cols: number, zones: number) => {
  try {
    return { rows: CellarRows(rows), cols: CellarCols(cols), zones: CellarZones(zones) }
  } catch {
    return badUserInput('rows/cols must be 1..100 and zones 1..3')
  }
}
