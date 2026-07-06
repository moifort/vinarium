import { BeverageTypeEnum, WineColorEnum } from '~/domain/beverage/infrastructure/graphql/enums'
import { JournalEventType } from '~/domain/journal/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import type { DashboardView, FavoriteWine, LastBottle, ReadyToDrinkWine } from '../../types'

const FavoriteWineType = builder.objectRef<FavoriteWine>('FavoriteWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId' }),
    name: t.expose('name', { type: 'BeverageName' }),
    beverageType: t.expose('beverageType', { type: BeverageTypeEnum }),
    color: t.expose('color', { type: WineColorEnum, nullable: true }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
    estimatedPrice: t.expose('estimatedPrice', { type: 'Eur', nullable: true }),
    tastingDate: t.expose('tastingDate', { type: 'DateTime', nullable: true }),
    rating: t.exposeFloat('rating', { nullable: true }),
  }),
})

const ReadyToDrinkWineType = builder.objectRef<ReadyToDrinkWine>('ReadyToDrinkWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId' }),
    name: t.expose('name', { type: 'BeverageName' }),
    beverageType: t.expose('beverageType', { type: BeverageTypeEnum }),
    color: t.expose('color', { type: WineColorEnum, nullable: true }),
    position: t.exposeString('position'),
    urgent: t.exposeBoolean('urgent'),
    drinkUntil: t.expose('drinkUntil', { type: 'Year', nullable: true }),
  }),
})

const LastBottleWineType = builder.objectRef<LastBottle['wine']>('LastBottleWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId' }),
    name: t.expose('name', { type: 'BeverageName' }),
    beverageType: t.expose('beverageType', { type: BeverageTypeEnum }),
    color: t.expose('color', { type: WineColorEnum, nullable: true }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
  }),
})

const LastBottleType = builder.objectRef<LastBottle>('LastBottle').implement({
  fields: (t) => ({
    wine: t.field({ type: LastBottleWineType, resolve: (b) => b.wine }),
    position: t.exposeString('position'),
    date: t.expose('date', { type: 'DateTime' }),
  }),
})

export const DashboardType = builder.objectRef<DashboardView>('Dashboard').implement({
  description: 'Aggregated dashboard view for the current user',
  fields: (t) => ({
    bottleCount: t.exposeInt('bottleCount'),
    totalValue: t.exposeFloat('totalValue'),
    readyToDrink: t.field({ type: [ReadyToDrinkWineType], resolve: (d) => d.readyToDrink }),
    favorites: t.field({ type: [FavoriteWineType], resolve: (d) => d.favorites }),
    lastBottle: t.field({ type: LastBottleType, nullable: true, resolve: (d) => d.lastBottle }),
    lastExit: t.field({ type: JournalEventType, nullable: true, resolve: (d) => d.lastExit }),
    history: t.field({ type: [JournalEventType], resolve: (d) => d.history }),
  }),
})
