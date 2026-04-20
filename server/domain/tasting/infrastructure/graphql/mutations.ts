import { make } from 'ts-brand'
import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { TastingCommand } from '../../command'
import type { Rating } from '../../types'
import { ShortlistInput } from './inputs'

const FAVORITE_RATING = make<Rating>()(5)

builder.mutationField('markFavorite', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Mark a wine as favorite (creates / overwrites a tasting note with rating 5)',
    args: { wineId: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { wineId }, { userId }) => {
      await TastingCommand.create({ userId, wineId, rating: FAVORITE_RATING })
      return true
    },
  }),
)

builder.mutationField('addToShortlist', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Add a wine to the shortlist with optional tasting details',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: ShortlistInput, required: true }),
    },
    resolve: async (_root, { wineId, input }, { userId }) => {
      await TastingCommand.create({
        userId,
        wineId,
        shortlist: true,
        ...stripNulls(input),
      })
      return true
    },
  }),
)
