import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { RecommendationCommand } from '../../command'
import { RecommendationInput } from './inputs'

builder.mutationField('addRecommendation', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Record a recommendation for a wine',
    args: {
      beverageId: t.arg({
        type: 'BeverageId',
        required: true,
        description: 'Wine being recommended',
      }),
      input: t.arg({
        type: RecommendationInput,
        required: true,
        description: 'Recommendation fields',
      }),
    },
    resolve: async (_root, { beverageId, input }, { userId }) => {
      await RecommendationCommand.create({ userId, beverageId, ...stripNulls(input) })
      return true
    },
  }),
)
