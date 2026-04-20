import { builder } from '~/domain/shared/graphql/builder'
import { WineQuery } from '../../query'
import { WineType } from './types'

builder.queryField('wines', (t) =>
  t.field({
    type: [WineType],
    description: 'List all wines belonging to the current user',
    resolve: (_root, _args, { userId }) => WineQuery.findAll(userId),
  }),
)

builder.queryField('wine', (t) =>
  t.field({
    type: WineType,
    nullable: true,
    description: 'Get a single wine by ID',
    args: { id: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { id }, { userId }) => {
      const wine = await WineQuery.getById(userId, id)
      return wine === 'not-found' ? null : wine
    },
  }),
)
