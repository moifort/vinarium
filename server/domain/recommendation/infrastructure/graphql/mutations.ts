import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { RecommendationCommand } from '../../command'
import { RecommendationInput } from './inputs'

builder.mutationField('addRecommendation', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Record a recommendation for a wine',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: RecommendationInput, required: true }),
    },
    resolve: async (_root, { wineId, input }, { userId }) => {
      await RecommendationCommand.create({ userId, wineId, ...stripNulls(input) })
      return true
    },
  }),
)
