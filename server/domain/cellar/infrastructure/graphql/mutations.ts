import { GraphQLError } from 'graphql'
import { builder } from '~/domain/shared/graphql/builder'
import { stripNulls } from '~/utils/input'
import { CellarCommand } from '../../command'
import { CellarCol, CellarRow } from '../../primitives'
import { bottleView } from '../../query'
import { CellarUseCase } from '../../use-case'
import { ConsumptionInput, GiftInput } from './inputs'
import { CellarBottleType } from './types'

builder.mutationField('placeBottle', (t) =>
  t.field({
    type: CellarBottleType,
    description: 'Place a wine in the cellar grid',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      row: t.arg.int({ required: true }),
      col: t.arg.int({ required: true }),
    },
    resolve: async (_root, { wineId, row, col }, { userId }) =>
      bottleView(await CellarCommand.placeWine(userId, wineId, CellarRow(row), CellarCol(col))),
  }),
)

builder.mutationField('moveBottle', (t) =>
  t.field({
    type: CellarBottleType,
    description: 'Move a bottle to a different position in the cellar',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      row: t.arg.int({ required: true }),
      col: t.arg.int({ required: true }),
    },
    resolve: async (_root, { wineId, row, col }, { userId }) => {
      const result = await CellarCommand.moveBottle(userId, wineId, CellarRow(row), CellarCol(col))
      if (result === 'not-in-cellar')
        throw new GraphQLError('Wine not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return bottleView(result)
    },
  }),
)

builder.mutationField('consumeBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar and record consumption (tasting note)',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: ConsumptionInput, required: true }),
    },
    resolve: async (_root, { wineId, input }, { userId }) => {
      const result = await CellarUseCase.removeBottle(userId, wineId, {
        type: 'tasting',
        ...stripNulls(input),
      })
      if (result === 'not-in-cellar')
        throw new GraphQLError('Wine not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)

builder.mutationField('giftBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar and record it as a gift',
    args: {
      wineId: t.arg({ type: 'WineId', required: true }),
      input: t.arg({ type: GiftInput, required: true }),
    },
    resolve: async (_root, { wineId, input }, { userId }) => {
      const { giftedDate, recipientName } = stripNulls(input)
      const result = await CellarUseCase.removeBottle(userId, wineId, {
        type: 'gift',
        given: { date: giftedDate, ...(recipientName && { recipientName }) },
      })
      if (result === 'not-in-cellar')
        throw new GraphQLError('Wine not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)

builder.mutationField('removeBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar without recording why',
    args: { wineId: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { wineId }, { userId }) => {
      const result = await CellarUseCase.removeBottle(userId, wineId)
      if (result === 'not-in-cellar')
        throw new GraphQLError('Wine not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)
