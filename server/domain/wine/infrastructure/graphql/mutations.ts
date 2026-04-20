import { GraphQLError } from 'graphql'
import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { WineCommand } from '../../command'
import { WineUseCase } from '../../use-case'
import { AddWineInput, UpdateWineInput } from './inputs'
import { WineType } from './types'

builder.mutationField('addWine', (t) =>
  t.field({
    type: WineType,
    description: 'Add a new wine to the catalog',
    args: { input: t.arg({ type: AddWineInput, required: true }) },
    resolve: (_root, { input }, { userId }) => {
      const { name, color, ...data } = stripNulls(input)
      return WineCommand.add(userId, name, color, data)
    },
  }),
)

builder.mutationField('updateWine', (t) =>
  t.field({
    type: WineType,
    description: 'Update an existing wine',
    args: {
      id: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: UpdateWineInput, required: true }),
    },
    resolve: async (_root, { id, input }, { userId }) => {
      const result = await WineCommand.update(userId, id, stripNulls(input))
      if (result === 'not-found')
        throw new GraphQLError('Wine not found', { extensions: { code: 'NOT_FOUND' } })
      return result
    },
  }),
)

builder.mutationField('deleteWine', (t) =>
  t.field({
    type: 'Boolean',
    description:
      'Delete a wine and all related data (cellar, tasting, gift, recommendation, journal)',
    args: { id: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { id }, { userId }) => {
      const result = await WineUseCase.removeCompletely(userId, id)
      if (result === 'not-found')
        throw new GraphQLError('Wine not found', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)
