import { builder } from '~/domain/shared/graphql/builder'
import { UserQuery } from '~/domain/user/query'
import { MeType } from './types'

builder.queryField('me', (t) =>
  t.field({
    type: MeType,
    description: 'The signed-in user’s profile and onboarding state',
    resolve: (_root, _args, { userId }) => UserQuery.me(userId),
  }),
)
