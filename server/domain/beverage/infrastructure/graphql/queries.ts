import { builder } from '~/domain/shared/graphql/builder'
import { BeverageQuery } from '../../query'
import {
  BeverageListModeEnum,
  BeverageSortEnum,
  BeverageStatusFilterEnum,
  BeverageSubtypeEnum,
  BeverageTypeEnum,
  SortOrderEnum,
  WineColorEnum,
} from './enums'
import { BeveragesType, BeverageType } from './types'

builder.queryField('beverages', (t) =>
  t.field({
    type: BeveragesType,
    description: 'A page of the current user’s beverage list, filtered and sorted per view',
    args: {
      mode: t.arg({ type: BeverageListModeEnum, defaultValue: 'all' }),
      status: t.arg({ type: BeverageStatusFilterEnum, defaultValue: 'all' }),
      color: t.arg({ type: WineColorEnum }),
      beverageType: t.arg({ type: BeverageTypeEnum }),
      subtype: t.arg({ type: BeverageSubtypeEnum }),
      sort: t.arg({ type: BeverageSortEnum, defaultValue: 'updatedAt' }),
      order: t.arg({ type: SortOrderEnum, defaultValue: 'desc' }),
      limit: t.arg.int({ defaultValue: 40 }),
      after: t.arg({ type: 'BeverageId' }),
    },
    resolve: async (_root, args, { userId }) =>
      BeverageQuery.list(userId, {
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

builder.queryField('beverage', (t) =>
  t.field({
    type: BeverageType,
    nullable: true,
    description: 'Get a single beverage by ID',
    args: { id: t.arg({ type: 'BeverageId', required: true }) },
    resolve: async (_root, { id }, { userId }) => {
      const beverage = await BeverageQuery.byId(userId, id)
      return beverage === 'not-found' ? null : beverage
    },
  }),
)
