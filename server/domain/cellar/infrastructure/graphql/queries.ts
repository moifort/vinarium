import { builder } from '~/domain/shared/graphql/builder'
import { CellarQuery } from '../../query'
import { CellarBottlesType, CellarInfoType, CellarPositionType } from './types'

builder.queryField('cellarInfo', (t) =>
  t.field({
    type: CellarInfoType,
    description: 'Cellar grid dimensions and current placement count',
    resolve: (_root, _args, { userId }) => CellarQuery.info(userId),
  }),
)

builder.queryField('cellarBottles', (t) =>
  t.field({
    type: CellarBottlesType,
    description: 'A page of bottles currently in the cellar, in grid order, with the joined wine',
    args: {
      limit: t.arg.int({ defaultValue: 15 }),
      after: t.arg({ type: 'BeverageId' }),
    },
    resolve: (_root, args, { userId }) =>
      CellarQuery.bottlesPage(userId, {
        limit: args.limit ?? 15,
        after: args.after ?? undefined,
      }),
  }),
)

builder.queryField('suggestCellarPosition', (t) =>
  t.field({
    type: CellarPositionType,
    nullable: true,
    description: 'Suggest the next free cellar position (null if cellar is full)',
    resolve: async (_root, _args, { userId }) => {
      const result = await CellarQuery.suggestPosition(userId)
      return result === 'cellar-full' ? null : result
    },
  }),
)
