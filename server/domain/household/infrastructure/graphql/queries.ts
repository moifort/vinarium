import { builder } from '~/domain/shared/graphql/builder'
import { HouseholdQuery } from '../../query'
import { HouseholdType } from './types'

builder.queryField('myHousehold', (t) =>
  t.field({
    type: HouseholdType,
    nullable: true,
    description:
      "The signed-in user's household with its members and open invitation codes.\n\n" +
      'Null when the user belongs to no household, in which case they act as a solo cellar of one.',
    resolve: async (_root, _args, { userId }) => {
      const result = await HouseholdQuery.view(userId)
      return result === 'not-in-household' ? null : result
    },
  }),
)
