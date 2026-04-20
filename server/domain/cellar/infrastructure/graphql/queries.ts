import { builder } from '~/domain/shared/graphql/builder'
import { CellarQuery } from '../../query'
import { CellarBottleWithWineType, CellarPositionType } from './types'

builder.queryField('cellarBottles', (t) =>
  t.field({
    type: [CellarBottleWithWineType],
    description: 'All bottles currently in the cellar, with the joined wine',
    resolve: (_root, _args, { userId }) => CellarQuery.getAllBottles(userId),
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
