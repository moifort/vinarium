import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { TastingCommand } from '../../command'
import { TastingInput } from './inputs'

builder.mutationField('markFavorite', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Toggle the favorite (heart) flag on a wine, preserving any existing tasting note',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      favorite: t.arg.boolean({ defaultValue: true }),
    },
    resolve: async (_root, { wineId, favorite }, { userId }) => {
      await TastingCommand.setFavorite(userId, wineId, favorite ?? true)
      return true
    },
  }),
)

builder.mutationField('recordTasting', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Record a tasting note (rating, notes, favorite flag) for a wine',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: TastingInput, required: true }),
    },
    resolve: async (_root, { wineId, input }, { userId }) => {
      await TastingCommand.create({ userId, wineId, ...stripNulls(input) })
      return true
    },
  }),
)
