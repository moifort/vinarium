import { builder } from '~/domain/shared/graphql/builder'
import { WineQuery } from '../../query'
import {
  BeverageSubtypeEnum,
  BeverageTypeEnum,
  SortOrderEnum,
  WineColorEnum,
  WineListModeEnum,
  WineSortEnum,
  WineStatusFilterEnum,
} from './enums'
import { WinesType, WineType } from './types'

builder.queryField('wines', (t) =>
  t.field({
    type: WinesType,
    description: 'A page of the current user’s wine list, filtered and sorted per view',
    args: {
      mode: t.arg({ type: WineListModeEnum, defaultValue: 'all' }),
      status: t.arg({ type: WineStatusFilterEnum, defaultValue: 'all' }),
      color: t.arg({ type: WineColorEnum }),
      beverageType: t.arg({ type: BeverageTypeEnum }),
      subtype: t.arg({ type: BeverageSubtypeEnum }),
      sort: t.arg({ type: WineSortEnum, defaultValue: 'updatedAt' }),
      order: t.arg({ type: SortOrderEnum, defaultValue: 'desc' }),
      limit: t.arg.int({ defaultValue: 40 }),
      after: t.arg({ type: 'WineId' }),
    },
    resolve: async (_root, args, { userId }) =>
      WineQuery.list(userId, {
        mode: args.mode ?? 'all',
        status: args.status ?? 'all',
        sort: args.sort ?? 'updatedAt',
        order: args.order ?? 'desc',
        limit: args.limit ?? 40,
        after: args.after ?? undefined,
        color: args.color ?? undefined,
        beverageType: args.beverageType ?? undefined,
        subtype: args.subtype ?? undefined,
      }),
  }),
)

builder.queryField('wine', (t) =>
  t.field({
    type: WineType,
    nullable: true,
    description: 'Get a single wine by ID',
    args: { id: t.arg({ type: 'WineId', required: true }) },
    resolve: async (_root, { id }, { userId }) => {
      const wine = await WineQuery.getById(userId, id)
      return wine === 'not-found' ? null : wine
    },
  }),
)
