import { match, P } from 'ts-pattern'
import { builder } from '~/domain/shared/graphql/builder'
import { domainError, notFound } from '~/domain/shared/graphql/errors'
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
      beverageId: t.arg({ type: 'BeverageId', required: true, description: 'Wine to place' }),
      row: t.arg.int({ required: true, description: 'Target grid row (0-based)' }),
      col: t.arg.int({ required: true, description: 'Target grid column (0-based)' }),
    },
    resolve: async (_root, { beverageId, row, col }, { userId }) => {
      const result = await CellarCommand.placeBeverage(
        userId,
        beverageId,
        CellarRow(row),
        CellarCol(col),
      )
      return match(result)
        .with('not-your-beverage', () => notFound('Beverage not found'))
        .with('position-occupied', () =>
          domainError('POSITION_OCCUPIED', 'Cellar position already occupied'),
        )
        .with(P.not(P.string), bottleView)
        .exhaustive()
    },
  }),
)

builder.mutationField('moveBottle', (t) =>
  t.field({
    type: CellarBottleType,
    description: 'Move a bottle to a different position in the cellar',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true, description: 'Bottle to move' }),
      row: t.arg.int({ required: true, description: 'Destination grid row (0-based)' }),
      col: t.arg.int({ required: true, description: 'Destination grid column (0-based)' }),
    },
    resolve: async (_root, { beverageId, row, col }, { userId }) => {
      const result = await CellarCommand.moveBottle(
        userId,
        beverageId,
        CellarRow(row),
        CellarCol(col),
      )
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with(P.not(P.string), bottleView)
        .exhaustive()
    },
  }),
)

builder.mutationField('consumeBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar and record consumption (tasting note)',
    args: {
      beverageId: t.arg({
        type: 'BeverageId',
        required: true,
        description: 'Bottle being consumed',
      }),
      input: t.arg({
        type: ConsumptionInput,
        required: true,
        description: 'Tasting note recorded on consumption',
      }),
    },
    resolve: async (_root, { beverageId, input }, { userId }) => {
      const result = await CellarUseCase.removeBottle(userId, beverageId, {
        type: 'tasting',
        ...stripNulls(input),
      })
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with(undefined, () => true)
        .exhaustive()
    },
  }),
)

builder.mutationField('giftBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar and record it as a gift',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true, description: 'Bottle given away' }),
      input: t.arg({
        type: GiftInput,
        required: true,
        description: 'Gift details (recipient, date)',
      }),
    },
    resolve: async (_root, { beverageId, input }, { userId }) => {
      const { giftedDate, recipientName } = stripNulls(input)
      const result = await CellarUseCase.removeBottle(userId, beverageId, {
        type: 'gift',
        given: { date: giftedDate, ...(recipientName && { recipientName }) },
      })
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with(undefined, () => true)
        .exhaustive()
    },
  }),
)

builder.mutationField('removeBottle', (t) =>
  t.field({
    type: 'Boolean',
    description: 'Remove a bottle from the cellar without recording why',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true, description: 'Bottle to remove' }),
    },
    resolve: async (_root, { beverageId }, { userId }) => {
      const result = await CellarUseCase.removeBottle(userId, beverageId)
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with(undefined, () => true)
        .exhaustive()
    },
  }),
)
