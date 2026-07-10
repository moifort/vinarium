import { builder } from '~/domain/shared/graphql/builder'
import { HouseholdQuery } from '../../query'
import { HouseholdType } from './types'

builder.queryField('myHousehold', (t) =>
  t.field({
    type: HouseholdType,
    nullable: true,
    description: 'The current user’s household, or null if they belong to none',
    resolve: async (_root, _args, { userId }) => {
      const result = await HouseholdQuery.view(userId)
      return result === 'not-in-household' ? null : result
    },
  }),
)
