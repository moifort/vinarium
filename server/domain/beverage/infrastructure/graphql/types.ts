import { builder } from '~/domain/shared/graphql/builder'
import type { Beverage, DrinkWindow, Place, Purchase, WineDetails } from '../../types'
import { BeverageSubtypeEnum, BeverageTypeEnum, WineColorEnum } from './enums'

const DrinkWindowType = builder.objectRef<DrinkWindow>('DrinkWindow').implement({
  description: 'The years a wine is at its best — either bound may stand alone',
  fields: (t) => ({
    from: t.expose('from', { type: 'Year', nullable: true }),
    until: t.expose('until', { type: 'Year', nullable: true }),
  }),
})

const PurchaseType = builder.objectRef<Purchase>('Purchase').implement({
  description: 'What the bottle cost and when it was acquired',
  fields: (t) => ({
    price: t.expose('price', { type: 'Eur', nullable: true }),
    date: t.expose('date', { type: 'DateTime', nullable: true }),
  }),
})

const PlaceType = builder.objectRef<Place>('Place').implement({
  description: 'Where the bottle was bought (coordinates and/or a place name)',
  fields: (t) => ({
    latitude: t.expose('latitude', { type: 'Latitude', nullable: true }),
    longitude: t.expose('longitude', { type: 'Longitude', nullable: true }),
    name: t.expose('name', { type: 'PlaceName', nullable: true }),
  }),
})

// The wine-only fields, exposed as one member of the BeverageDetails union.
const WineDetailsType = builder.objectRef<WineDetails>('WineDetails').implement({
  description: 'Fields specific to a wine (absent on every other beverage type)',
  fields: (t) => ({
    color: t.expose('color', { type: WineColorEnum, nullable: true }),
    vintage: t.expose('vintage', { type: 'Year', nullable: true }),
    appellation: t.expose('appellation', { type: 'Appellation', nullable: true }),
    classification: t.expose('classification', { type: 'Classification', nullable: true }),
    grapeVarieties: t.expose('grapeVarieties', { type: ['GrapeVariety'], nullable: true }),
    drinkWindow: t.field({
      type: DrinkWindowType,
      nullable: true,
      resolve: (w) => w.drinkWindow,
    }),
    servingTemperature: t.expose('servingTemperature', { type: 'Celsius', nullable: true }),
  }),
})

// The per-type details union. Only wine has a member for now; adding BeerDetails
// is a new member plus a branch in resolveType (keyed on the parent's type).
const BeverageDetailsUnion = builder.unionType('BeverageDetails', {
  description: 'Fields that exist only for a specific beverage type',
  types: [WineDetailsType],
  resolveType: () => 'WineDetails',
})

// The satellite fields (cellar, consumption, gift, recommendation, history) are
// grafted onto BeverageType by their own domains via builder.objectField and
// resolve through the per-request loaders — a Beverage stays a plain Beverage here.
export const BeverageType = builder.objectRef<Beverage>('Beverage').implement({
  description: 'A beverage in the user’s collection (wine, spirit, beer, sake ...)',
  fields: (t) => ({
    id: t.expose('id', { type: 'BeverageId' }),
    userId: t.expose('userId', { type: 'UserId' }),
    isMine: t.boolean({
      description: 'Whether this beverage belongs to the viewer (false for a housemate’s)',
      resolve: (beverage, _args, { userId }) => beverage.userId === userId,
    }),
    name: t.expose('name', { type: 'BeverageName' }),
    beverageType: t.expose('beverageType', { type: BeverageTypeEnum }),
    subtype: t.expose('subtype', { type: BeverageSubtypeEnum, nullable: true }),
    alcoholContent: t.expose('alcoholContent', { type: 'Percentage', nullable: true }),
    producer: t.expose('producer', { type: 'Producer', nullable: true }),
    region: t.expose('region', { type: 'Region', nullable: true }),
    country: t.expose('country', { type: 'Country', nullable: true }),
    purchase: t.field({ type: PurchaseType, nullable: true, resolve: (b) => b.purchase }),
    notes: t.expose('notes', { type: 'Notes', nullable: true }),
    place: t.field({ type: PlaceType, nullable: true, resolve: (b) => b.place }),
    details: t.field({
      type: BeverageDetailsUnion,
      nullable: true,
      description: 'Type-specific fields — non-null only for a wine',
      resolve: (b) => (b.beverageType === 'wine' ? b.wine : null),
    }),
    createdAt: t.expose('createdAt', { type: 'DateTime' }),
    updatedAt: t.expose('updatedAt', { type: 'DateTime' }),
  }),
})

// Paginated beverage list payload: the page of items plus the cursor-less
// pagination signals (façon pchook). `totalCount` is the page size when unknown.
export type BeveragesPage = { items: Beverage[]; hasMore: boolean; totalCount: number }

export const BeveragesType = builder.objectRef<BeveragesPage>('Beverages').implement({
  description: 'A page of the beverage list',
  fields: (t) => ({
    items: t.field({ type: [BeverageType], resolve: ({ items }) => items }),
    hasMore: t.exposeBoolean('hasMore', {
      description: 'Whether more beverages are available after this page',
    }),
    totalCount: t.exposeInt('totalCount', {
      description: 'Number of beverages in this page (full count is not computed)',
    }),
  }),
})
