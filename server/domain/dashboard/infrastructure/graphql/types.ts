import { JournalEventType } from '~/domain/journal/infrastructure/graphql/types'
import { builder } from '~/domain/shared/graphql/builder'
import { WineColorEnum } from '~/domain/wine/infrastructure/graphql/enums'
import type {
  DashboardView,
  FavoriteWine,
  LastBottle,
  ReadyToDrinkWine,
  ShortlistWine,
} from '../../types'

const FavoriteWineType = builder.objectRef<FavoriteWine>('FavoriteWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'WineId' }),
    name: t.expose('name', { type: 'WineName' }),
    color: t.expose('color', { type: WineColorEnum }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
    estimatedPrice: t.expose('estimatedPrice', { type: 'Eur', nullable: true }),
    tastingDate: t.expose('tastingDate', { type: 'DateTime', nullable: true }),
  }),
})

const ShortlistWineType = builder.objectRef<ShortlistWine>('ShortlistWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'WineId' }),
    name: t.expose('name', { type: 'WineName' }),
    color: t.expose('color', { type: WineColorEnum }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
    estimatedPrice: t.expose('estimatedPrice', { type: 'Eur', nullable: true }),
    tastingDate: t.expose('tastingDate', { type: 'DateTime', nullable: true }),
    rating: t.exposeFloat('rating', { nullable: true }),
  }),
})

const ReadyToDrinkWineType = builder.objectRef<ReadyToDrinkWine>('ReadyToDrinkWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'WineId' }),
    name: t.expose('name', { type: 'WineName' }),
    color: t.expose('color', { type: WineColorEnum }),
    position: t.exposeString('position'),
    urgent: t.exposeBoolean('urgent'),
    drinkUntil: t.expose('drinkUntil', { type: 'Year', nullable: true }),
  }),
})

const LastBottleWineType = builder.objectRef<LastBottle['wine']>('LastBottleWine').implement({
  fields: (t) => ({
    id: t.expose('id', { type: 'WineId' }),
    name: t.expose('name', { type: 'WineName' }),
    color: t.expose('color', { type: WineColorEnum }),
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
    shortlist: t.field({ type: [ShortlistWineType], resolve: (d) => d.shortlist }),
    lastBottle: t.field({ type: LastBottleType, nullable: true, resolve: (d) => d.lastBottle }),
    lastExit: t.field({ type: JournalEventType, nullable: true, resolve: (d) => d.lastExit }),
    history: t.field({ type: [JournalEventType], resolve: (d) => d.history }),
  }),
})
