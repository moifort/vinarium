import { BeverageTypeEnum, WineColorEnum } from '~/domain/beverage/infrastructure/graphql/enums'
import { JournalEventType } from '~/domain/journal/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { DashboardView, FavoriteWine, LastBottle, ReadyToDrinkWine } from '../../types'

const FavoriteWineType = builder.objectRef<FavoriteWine>('FavoriteWine').implement({
  description:
    'A wine the user flagged as a favorite, summarized for the dashboard.\n\n' +
    'Carries the identity fields plus the latest tasting metadata (`tastingDate`, `rating`) ' +
    'so the home screen can surface the highest-rated bottles without a second query.',
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId', description: 'Identifier of the favorite beverage' }),
    name: t.expose('name', { type: 'BeverageName', description: 'Display name of the beverage' }),
    beverageType: t.expose('beverageType', {
      type: BeverageTypeEnum,
      description: 'Beverage family (wine, spirit, beer, ...)',
    }),
    color: t.expose('color', {
      type: WineColorEnum,
      nullable: true,
      description: 'Wine color (red, white, rose); null for non-wine beverages',
    }),
    vintage: t.expose('vintage', {
      type: 'Year',
      nullable: true,
      description: 'Vintage year; null when unknown or not applicable',
    }),
    estimatedPrice: t.expose('estimatedPrice', {
      type: 'Eur',
      nullable: true,
      description: 'Estimated unit value in euros; null when unpriced',
    }),
    tastingDate: t.expose('tastingDate', {
      type: 'DateTime',
      nullable: true,
      description: 'Date of the most recent tasting note; null when never tasted',
    }),
    rating: t.exposeFloat('rating', {
      nullable: true,
      description: 'Rating from the latest tasting note; null when never rated',
    }),
  }),
})

const ReadyToDrinkWineType = builder.objectRef<ReadyToDrinkWine>('ReadyToDrinkWine').implement({
  description:
    'A cellared bottle that has entered its drinking window, surfaced on the dashboard.\n\n' +
    'The `urgent` flag marks bottles at risk of being kept past their peak, and `drinkUntil` ' +
    'is the last recommended year to drink them. Includes the cellar `position` so the bottle ' +
    'can be located at a glance.',
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId', description: 'Identifier of the beverage' }),
    name: t.expose('name', { type: 'BeverageName', description: 'Display name of the beverage' }),
    beverageType: t.expose('beverageType', {
      type: BeverageTypeEnum,
      description: 'Beverage family (wine, spirit, beer, ...)',
    }),
    color: t.expose('color', {
      type: WineColorEnum,
      nullable: true,
      description: 'Wine color; null for non-wine beverages',
    }),
    position: t.exposeString('position', {
      description: 'Cellar grid slot where the bottle is stored',
    }),
    urgent: t.exposeBoolean('urgent', {
      description:
        'True when the bottle is near or past its drinking window and should be drunk soon',
    }),
    drinkUntil: t.expose('drinkUntil', {
      type: 'Year',
      nullable: true,
      description: 'Last recommended year to drink the bottle; null when unknown',
    }),
  }),
})

const LastBottleWineType = builder.objectRef<LastBottle['wine']>('LastBottleWine').implement({
  description:
    'Identity of the beverage referenced by `LastBottle`.\n\n' +
    'A trimmed projection carrying only the fields the dashboard needs to name and color the ' +
    'most recently placed bottle.',
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId', description: 'Identifier of the beverage' }),
    name: t.expose('name', { type: 'BeverageName', description: 'Display name of the beverage' }),
    beverageType: t.expose('beverageType', {
      type: BeverageTypeEnum,
      description: 'Beverage family (wine, spirit, beer, ...)',
    }),
    color: t.expose('color', {
      type: WineColorEnum,
      nullable: true,
      description: 'Wine color; null for non-wine beverages',
    }),
    vintage: t.expose('vintage', {
      type: 'Year',
      nullable: true,
      description: 'Vintage year; null when unknown or not applicable',
    }),
  }),
})

const LastBottleType = builder.objectRef<LastBottle>('LastBottle').implement({
  description:
    'The most recently placed bottle in the cellar.\n\n' +
    'Pairs the beverage identity with where and when it was stored, letting the dashboard echo ' +
    'the last add-to-cellar action.',
  fields: (t) => ({
    wine: t.field({
      type: LastBottleWineType,
      description: 'The beverage this bottle holds',
      resolve: (b) => b.wine,
    }),
    position: t.exposeString('position', {
      description: 'Cellar grid slot where the bottle was placed',
    }),
    date: t.expose('date', {
      type: 'DateTime',
      description: 'When the bottle was added to the cellar',
    }),
  }),
})

export const DashboardType = builder.objectRef<DashboardView>('Dashboard').implement({
  description:
    'Read-only home-screen summary of the current user cellar and activity.\n\n' +
    'Aggregates cellar counters, the estimated total value, drink-window alerts, favorites and ' +
    'recent journal activity into a single payload so the app home screen loads in one request. ' +
    'Every field is derived; nothing here is directly mutable.\n\n' +
    '```graphql\n' +
    'query {\n' +
    '  dashboard {\n' +
    '    bottleCount\n' +
    '    capacity\n' +
    '    totalValue\n' +
    '    readyToDrink { name urgent drinkUntil }\n' +
    '    favorites { name rating }\n' +
    '    lastBottle { wine { name } position date }\n' +
    '  }\n' +
    '}\n' +
    '```',
  fields: (t) => ({
    bottleCount: t.exposeInt('bottleCount', {
      description: 'Number of bottles currently stored in the cellar',
    }),
    capacity: t.exposeInt('capacity', {
      description: 'Total cellar capacity (number of grid spots)',
    }),
    totalValue: t.exposeFloat('totalValue', {
      description: 'Sum of the estimated values of all cellared bottles, in euros',
    }),
    readyToDrink: t.field({
      type: [ReadyToDrinkWineType],
      description: 'Cellared bottles that have entered their drinking window',
      resolve: (d) => d.readyToDrink,
    }),
    favorites: t.field({
      type: [FavoriteWineType],
      description: 'Wines the user flagged as favorites',
      resolve: (d) => d.favorites,
    }),
    lastBottle: t.field({
      type: LastBottleType,
      nullable: true,
      description: 'The most recently placed bottle; null when the cellar is empty',
      resolve: (d) => d.lastBottle,
    }),
    lastExit: t.field({
      type: JournalEventType,
      nullable: true,
      description:
        'The most recent journal event that removed a bottle from the cellar; null when none',
      resolve: (d) => d.lastExit,
    }),
    history: t.field({
      type: [JournalEventType],
      description: 'Recent journal events, most recent first',
      resolve: (d) => d.history,
    }),
  }),
})
