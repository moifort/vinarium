import { match, P } from 'ts-pattern'
import { SearchIndexUseCase } from '~/domain/search/use-case'
import { builder } from '~/domain/shared/graphql/builder'
import { badUserInput, domainError, notFound } from '~/domain/shared/graphql/errors'
import { stripNulls } from '~/utils/input'
import { CellarCommand } from '../../command'
import { CellarCol, CellarCols, CellarRow, CellarRows, CellarZones } from '../../primitives'
import { bottleView, CellarQuery } from '../../query'
import type { CellarId } from '../../types'
import { CellarUseCase } from '../../use-case'
import { ConsumptionInput, GiftInput } from './inputs'
import { CellarBottleType, CellarType, ReconfigureCellarResultUnion } from './types'

// Validate the grid dimensions at the resolver boundary; a Zod failure becomes a
// user-input error rather than a 500. rows/cols are 1..100, zones 1..3.
const parseDimensions = (rows: number, cols: number, zones: number) => {
  try {
    return { rows: CellarRows(rows), cols: CellarCols(cols), zones: CellarZones(zones) }
  } catch {
    return badUserInput('rows/cols must be 1..100 and zones 1..3')
  }
}

const cellarNotFound = () => notFound('Cellar not found')

// A cellar as `cellars` lists it, once a mutation has changed it.
const listed = async (userId: Parameters<typeof CellarQuery.overview>[0], id: CellarId) => {
  const cellar = (await CellarQuery.overview(userId)).find((c) => c.id === id)
  return cellar ?? cellarNotFound()
}

builder.mutationField('placeBottle', (t) =>
  t.field({
    type: CellarBottleType,
    description: 'Place a wine in the cellar grid',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true, description: 'Wine to place' }),
      row: t.arg.int({ required: true, description: 'Target grid row (0-based)' }),
      col: t.arg.int({ required: true, description: 'Target grid column (0-based)' }),
      cellarId: t.arg({ type: 'CellarId', description: 'Target cellar; primary if absent' }),
    },
    resolve: async (_root, { beverageId, row, col, cellarId }, { userId }) => {
      const result = await CellarCommand.placeBeverage(
        userId,
        beverageId,
        CellarRow(row),
        CellarCol(col),
        cellarId ?? undefined,
      )
      if (typeof result !== 'string') await SearchIndexUseCase.refresh(userId, beverageId)
      return match(result)
        .with('not-your-beverage', () => notFound('Beverage not found'))
        .with('position-occupied', () =>
          domainError('POSITION_OCCUPIED', 'Cellar position already occupied'),
        )
        .with('out-of-grid', () => badUserInput('Cellar position outside the grid'))
        .with('cellar-not-found', cellarNotFound)
        .with(P.not(P.string), bottleView)
        .exhaustive()
    },
  }),
)

builder.mutationField('moveBottle', (t) =>
  t.field({
    type: CellarBottleType,
    description:
      'Move a bottle to another position, in its cellar or in another one. A bottle already ' +
      'standing there swaps places with it',
    args: {
      beverageId: t.arg({ type: 'BeverageId', required: true, description: 'Bottle to move' }),
      row: t.arg.int({ required: true, description: 'Destination grid row (0-based)' }),
      col: t.arg.int({ required: true, description: 'Destination grid column (0-based)' }),
      cellarId: t.arg({
        type: 'CellarId',
        description: "Destination cellar; the bottle's own if absent",
      }),
    },
    resolve: async (_root, { beverageId, row, col, cellarId }, { userId }) => {
      const result = await CellarCommand.moveBottle(
        userId,
        beverageId,
        CellarRow(row),
        CellarCol(col),
        cellarId ?? undefined,
      )
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with('out-of-grid', () => badUserInput('Cellar position outside the grid'))
        .with('cellar-not-found', cellarNotFound)
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
      if (result !== 'not-in-cellar') await SearchIndexUseCase.refresh(userId, beverageId)
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
      if (result !== 'not-in-cellar') await SearchIndexUseCase.refresh(userId, beverageId)
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with(undefined, () => true)
        .exhaustive()
    },
  }),
)

builder.mutationField('reconfigureCellar', (t) =>
  t.field({
    type: ReconfigureCellarResultUnion,
    description:
      'Resize or retune a cellar grid, the primary one by default (settings). Refuses to strand ' +
      'placed bottles',
    args: {
      rows: t.arg.int({ required: true, description: 'Number of rows, labelled A.. (1..100)' }),
      cols: t.arg.int({ required: true, description: 'Number of slots per row (1..100)' }),
      zones: t.arg.int({ required: true, description: 'Number of temperature zones (1..3)' }),
      cellarId: t.arg({ type: 'CellarId', description: 'Cellar to resize; primary if absent' }),
    },
    resolve: async (_root, args, { userId }) => {
      const { rows, cols, zones } = parseDimensions(args.rows, args.cols, args.zones)
      const cellarId = args.cellarId ?? undefined
      const result = await CellarCommand.reconfigure(userId, rows, cols, zones, cellarId)
      if (result === 'not-found') return cellarNotFound()
      if ('outOfBounds' in result) return result
      const info = await CellarQuery.info(userId, cellarId)
      return info === 'not-found' ? cellarNotFound() : info
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
      if (result !== 'not-in-cellar') await SearchIndexUseCase.refresh(userId, beverageId)
      return match(result)
        .with('not-in-cellar', () => notFound('Beverage not in cellar'))
        .with(undefined, () => true)
        .exhaustive()
    },
  }),
)

builder.mutationField('createCellar', (t) =>
  t.field({
    type: CellarType,
    description:
      'Add a cellar to the household (Premium).\n\n' +
      'Fails with PREMIUM_REQUIRED on the free plan, and with TOO_MANY_CELLARS past ten ' +
      'cellars. A cellar created while subscribed stays usable once Premium ends.',
    args: {
      name: t.arg({ type: 'CellarName', required: true, description: 'Name of the cellar' }),
      rows: t.arg.int({ required: true, description: 'Number of rows, labelled A.. (1..100)' }),
      cols: t.arg.int({ required: true, description: 'Number of slots per row (1..100)' }),
      zones: t.arg.int({
        defaultValue: 1,
        description: 'Number of temperature zones (1..3)',
      }),
    },
    resolve: async (_root, args, { userId }) => {
      const size = parseDimensions(args.rows, args.cols, args.zones ?? 1)
      const result = await CellarUseCase.createCellar(userId, args.name, size)
      return match(result)
        .with('premium-required', () =>
          domainError('PREMIUM_REQUIRED', 'Several cellars need Premium'),
        )
        .with('too-many-cellars', () =>
          domainError('TOO_MANY_CELLARS', 'A household holds at most ten cellars'),
        )
        .with(P.string, (id) => listed(userId, id))
        .exhaustive()
    },
  }),
)

builder.mutationField('renameCellar', (t) =>
  t.field({
    type: CellarType,
    description: 'Name a cellar of the household, the primary one included',
    args: {
      id: t.arg({ type: 'CellarId', required: true, description: 'Cellar to name' }),
      name: t.arg({ type: 'CellarName', required: true, description: 'New name' }),
    },
    resolve: async (_root, { id, name }, { userId }) => {
      const result = await CellarCommand.rename(userId, id, name)
      return result === 'not-found' ? cellarNotFound() : listed(userId, result)
    },
  }),
)

builder.mutationField('deleteCellar', (t) =>
  t.field({
    type: 'Boolean',
    description:
      'Delete an empty cellar, and return true.\n\n' +
      'Fails with CELLAR_NOT_EMPTY while a bottle stands in it, and with PRIMARY_CELLAR for the ' +
      'primary cellar, which cannot be deleted.',
    args: { id: t.arg({ type: 'CellarId', required: true, description: 'Cellar to delete' }) },
    resolve: async (_root, { id }, { userId }) =>
      match(await CellarCommand.remove(userId, id))
        .with('not-found', cellarNotFound)
        .with('primary-cellar', () =>
          domainError('PRIMARY_CELLAR', 'The primary cellar cannot be deleted'),
        )
        .with({ notEmpty: P.number }, () =>
          domainError('CELLAR_NOT_EMPTY', 'Take the bottles out of the cellar first'),
        )
        .with(undefined, () => true)
        .exhaustive(),
  }),
)
