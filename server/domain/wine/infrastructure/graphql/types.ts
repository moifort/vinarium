import { builder } from '~/domain/shared/graphql/builder'
import type { DrinkWindow, Wine, WinePlace, WinePurchase } from '../../types'
import { BeverageSubtypeEnum, BeverageTypeEnum, WineColorEnum } from './enums'

const DrinkWindowType = builder.objectRef<DrinkWindow>('DrinkWindow').implement({
  description: 'The years a wine is at its best — either bound may stand alone',
  fields: (t) => ({
    from: t.expose('from', { type: 'Year', nullable: true }),
    until: t.expose('until', { type: 'Year', nullable: true }),
  }),
})

const WinePurchaseType = builder.objectRef<WinePurchase>('WinePurchase').implement({
  description: 'What the bottle cost and when it was acquired',
  fields: (t) => ({
    price: t.expose('price', { type: 'Eur', nullable: true }),
    date: t.exposeString('date', { nullable: true, description: 'ISO date string' }),
  }),
})

const WinePlaceType = builder.objectRef<WinePlace>('WinePlace').implement({
  description: 'Where the bottle was bought (coordinates and/or a place name)',
  fields: (t) => ({
    latitude: t.expose('latitude', { type: 'Latitude', nullable: true }),
    longitude: t.expose('longitude', { type: 'Longitude', nullable: true }),
    name: t.expose('name', { type: 'PlaceName', nullable: true }),
  }),
})

// The satellite fields (cellar, consumption, gift, recommendation, history) are
// grafted onto WineType by their own domains via builder.objectField and resolve
// through the per-request loaders — a Wine stays a plain Wine here.
export const WineType = builder.objectRef<Wine>('Wine').implement({
  description: 'A beverage in the user’s collection (wine, spirit, beer, sake ...)',
  fields: (t) => ({
    id: t.expose('id', { type: 'WineId' }),
    userId: t.expose('userId', { type: 'UserId' }),
    name: t.expose('name', { type: 'WineName' }),
    beverageType: t.expose('beverageType', { type: BeverageTypeEnum }),
    color: t.expose('color', { type: WineColorEnum, nullable: true }),
    subtype: t.expose('subtype', { type: BeverageSubtypeEnum, nullable: true }),
    alcoholContent: t.exposeFloat('alcoholContent', { nullable: true }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
    domain: t.expose('domain', { type: 'WineDomain', nullable: true }),
    appellation: t.expose('appellation', { type: 'Appellation', nullable: true }),
    region: t.expose('region', { type: 'Region', nullable: true }),
    country: t.expose('country', { type: 'Country', nullable: true }),
    grapeVarieties: t.exposeStringList('grapeVarieties', { nullable: true }),
    classification: t.expose('classification', { type: 'Classification', nullable: true }),
    purchase: t.field({ type: WinePurchaseType, nullable: true, resolve: (w) => w.purchase }),
    drinkWindow: t.field({ type: DrinkWindowType, nullable: true, resolve: (w) => w.drinkWindow }),
    notes: t.exposeString('notes', { nullable: true }),
    giftedBy: t.expose('giftedBy', { type: 'PersonName', nullable: true }),
    servingTemperature: t.exposeFloat('servingTemperature', { nullable: true }),
    place: t.field({ type: WinePlaceType, nullable: true, resolve: (w) => w.place }),
    createdAt: t.expose('createdAt', { type: 'DateTime' }),
    updatedAt: t.expose('updatedAt', { type: 'DateTime' }),
  }),
})

// Paginated wine list payload: the page of items plus the cursor-less pagination
// signals (façon pchook). `totalCount` is present when known, else the page size.
export type WinesPage = { items: Wine[]; hasMore: boolean; totalCount: number }

export const WinesType = builder.objectRef<WinesPage>('Wines').implement({
  description: 'A page of the wine list',
  fields: (t) => ({
    items: t.field({ type: [WineType], resolve: ({ items }) => items }),
    hasMore: t.exposeBoolean('hasMore', {
      description: 'Whether more wines are available after this page',
    }),
    totalCount: t.exposeInt('totalCount', {
      description: 'Number of wines in this page (full count is not computed)',
    }),
  }),
})
