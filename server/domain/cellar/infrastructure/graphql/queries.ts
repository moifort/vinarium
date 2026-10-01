import { builder } from '~/domain/shared/graphql/builder'
import { notFound } from '~/domain/shared/graphql/errors'
import { pageLimit } from '~/utils/input'
import { CellarQuery } from '../../query'
import { CellarBottlesType, CellarInfoType, CellarPositionType, CellarType } from './types'

const cellarNotFound = () => notFound('Cellar not found')

builder.queryField('cellars', (t) =>
  t.field({
    type: [CellarType],
    description: "The household's cellars with their usage, the primary first",
    resolve: (_root, _args, { userId }) => CellarQuery.overview(userId),
  }),
)

builder.queryField('cellarInfo', (t) =>
  t.field({
    type: CellarInfoType,
    description: 'Grid dimensions and placement count of a cellar, the primary one by default',
    args: {
      cellarId: t.arg({ type: 'CellarId', description: 'Cellar to describe; primary if absent' }),
    },
    resolve: async (_root, { cellarId }, { userId }) => {
      const info = await CellarQuery.info(userId, cellarId ?? undefined)
      return info === 'not-found' ? cellarNotFound() : info
    },
  }),
)

builder.queryField('cellarBottles', (t) =>
  t.field({
    type: CellarBottlesType,
    description:
      'A page of the bottles standing in a cellar, the primary one by default, in grid order, ' +
      'with the joined wine',
    args: {
      cellarId: t.arg({ type: 'CellarId', description: 'Cellar to read; primary if absent' }),
      limit: t.arg.int({
        defaultValue: 15,
        description: 'Maximum bottles returned in the page, at most 1000',
      }),
      after: t.arg({
        type: 'BeverageId',
        description: "Cursor: return the page following this bottle's beverage id.",
      }),
    },
    resolve: async (_root, args, { userId }) => {
      const page = await CellarQuery.bottlesPage(userId, {
        // The full grid is read in one page to place or move a bottle.
        limit: pageLimit(args.limit, 15, 1000),
        after: args.after ?? undefined,
        cellarId: args.cellarId ?? undefined,
      })
      return page === 'not-found' ? cellarNotFound() : page
    },
  }),
)

builder.queryField('suggestCellarPosition', (t) =>
  t.field({
    type: CellarPositionType,
    nullable: true,
    description:
      'Suggest the next free position of a cellar, the primary one by default (null if full)',
    args: {
      cellarId: t.arg({ type: 'CellarId', description: 'Cellar to look in; primary if absent' }),
    },
    resolve: async (_root, { cellarId }, { userId }) => {
      const result = await CellarQuery.suggestPosition(userId, cellarId ?? undefined)
      if (result === 'not-found') return cellarNotFound()
      return result === 'cellar-full' ? null : result
    },
  }),
)
