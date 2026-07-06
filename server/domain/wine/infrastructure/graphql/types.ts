import { builder } from '~/domain/shared/graphql/builder'
import type { Wine } from '../../types'
import { BeverageSubtypeEnum, BeverageTypeEnum, WineColorEnum } from './enums'

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
    purchasePrice: t.expose('purchasePrice', { type: 'Eur', nullable: true }),
    purchaseDate: t.exposeString('purchaseDate', { nullable: true }),
    drinkFrom: t.expose('drinkFrom', { type: 'Year', nullable: true }),
    drinkUntil: t.expose('drinkUntil', { type: 'Year', nullable: true }),
    notes: t.exposeString('notes', { nullable: true }),
    giftedBy: t.expose('giftedBy', { type: 'PersonName', nullable: true }),
    servingTemperature: t.exposeFloat('servingTemperature', { nullable: true }),
    latitude: t.expose('latitude', { type: 'Latitude', nullable: true }),
    longitude: t.expose('longitude', { type: 'Longitude', nullable: true }),
    placeName: t.expose('placeName', { type: 'PlaceName', nullable: true }),
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
