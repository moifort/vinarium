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
    description:
      'A page of the viewer’s beverage list, filtered and sorted per view, plus any ' +
      'household member’s wine currently placed in the shared cellar',
    args: {
      mode: t.arg({
        type: BeverageListModeEnum,
        defaultValue: 'all',
        description: 'List preset: all beverages or the favorites shortlist',
      }),
      status: t.arg({
        type: BeverageStatusFilterEnum,
        defaultValue: 'all',
        description: 'Restrict to a cellar status (in-cellar, consumed, …)',
      }),
      color: t.arg({ type: WineColorEnum, description: 'Facet: keep only this wine color' }),
      beverageType: t.arg({
        type: BeverageTypeEnum,
        description: 'Facet: keep only this beverage type (wine, beer, …)',
      }),
      subtype: t.arg({ type: BeverageSubtypeEnum, description: 'Facet: keep only this subtype' }),
      sort: t.arg({
        type: BeverageSortEnum,
        defaultValue: 'updatedAt',
        description: 'Field the page is ordered by',
      }),
      order: t.arg({
        type: SortOrderEnum,
        defaultValue: 'desc',
        description: 'Sort direction',
      }),
      limit: t.arg.int({ defaultValue: 40, description: 'Maximum beverages returned in the page' }),
      after: t.arg({
        type: 'BeverageId',
        description: 'Cursor: return the page following this beverage id',
      }),
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
    description: 'Get a single beverage by ID — the viewer’s own or a household member’s',
    args: {
      id: t.arg({ type: 'BeverageId', required: true, description: 'Beverage to fetch' }),
    },
    resolve: async (_root, { id }, { userId }) => {
      const beverage = await BeverageQuery.byIdForViewer(userId, id)
      return beverage === 'not-found' ? null : beverage
    },
  }),
)
