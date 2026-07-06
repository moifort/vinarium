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
      beverageId: t.arg({ type: 'BeverageId', required: true }),
      row: t.arg.int({ required: true }),
      col: t.arg.int({ required: true }),
    },
    resolve: async (_root, { beverageId, row, col }, { userId }) =>
      bottleView(
        await CellarCommand.placeBeverage(userId, beverageId, CellarRow(row), CellarCol(col)),
      ),
  }),
)

builder.mutationField('moveBottle', (t) =>
  t.field({
    type: CellarBottleType,
    description: 'Move a bottle to a different position in the cellar',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true }),
      row: t.arg.int({ required: true }),
      col: t.arg.int({ required: true }),
    },
    resolve: async (_root, { beverageId, row, col }, { userId }) => {
      const result = await CellarCommand.moveBottle(
        userId,
        beverageId,
        CellarRow(row),
        CellarCol(col),
      )
      if (result === 'not-in-cellar')
        throw new GraphQLError('Beverage not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return bottleView(result)
    },
  }),
)

builder.mutationField('consumeBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar and record consumption (tasting note)',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true }),
      input: t.arg({ type: ConsumptionInput, required: true }),
    },
    resolve: async (_root, { beverageId, input }, { userId }) => {
      const result = await CellarUseCase.removeBottle(userId, beverageId, {
        type: 'tasting',
        ...stripNulls(input),
      })
      if (result === 'not-in-cellar')
        throw new GraphQLError('Beverage not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)

builder.mutationField('giftBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar and record it as a gift',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true }),
      input: t.arg({ type: GiftInput, required: true }),
    },
    resolve: async (_root, { beverageId, input }, { userId }) => {
      const { giftedDate, recipientName } = stripNulls(input)
      const result = await CellarUseCase.removeBottle(userId, beverageId, {
        type: 'gift',
        given: { date: giftedDate, ...(recipientName && { recipientName }) },
      })
      if (result === 'not-in-cellar')
        throw new GraphQLError('Beverage not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)

builder.mutationField('removeBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar without recording why',
    args: { beverageId: t.arg({ type: 'BeverageId', required: true }) },
    resolve: async (_root, { beverageId }, { userId }) => {
      const result = await CellarUseCase.removeBottle(userId, beverageId)
      if (result === 'not-in-cellar')
        throw new GraphQLError('Beverage not in cellar', { extensions: { code: 'NOT_FOUND' } })
      return true
    },
  }),
)
